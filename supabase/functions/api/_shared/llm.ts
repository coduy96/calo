// Normalized LLM client. iOS sends provider-agnostic requests; this module
// translates them into whatever provider is configured in app_config and
// translates the response back. Adding a provider = adding one adapter case.

import { getConfig, getString, getNumber } from "./config.ts";

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta";

export interface NormalizedMessage {
  role: "user" | "assistant" | "tool";
  content?: string;
  image_base64?: string;
  // For tool messages — the matching tool_call id.
  tool_call_id?: string;
  // For tool messages — the tool's return value as a JSON string.
  tool_result?: string;
}

export interface NormalizedToolDef {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
}

export interface NormalizedRequest {
  task: "food" | "label" | "chat" | "weight" | "goals";
  system?: string;
  messages: NormalizedMessage[];
  tools?: NormalizedToolDef[];
}

export interface NormalizedToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
}

export interface NormalizedResponse {
  text: string | null;
  tool_calls: NormalizedToolCall[] | null;
}

export async function generate(req: NormalizedRequest): Promise<NormalizedResponse> {
  const cfg = await getConfig();
  const provider = getString(cfg, "llm_provider", "gemini");
  const model = pickModel(cfg, req.task);
  const maxTokens = getNumber(
    cfg,
    req.task === "chat" ? "chat_max_output_tokens" : "max_output_tokens",
    1024,
  );

  switch (provider) {
    case "gemini":
      return await geminiGenerate(model, req, maxTokens);
    default:
      // Other providers can be added by writing an adapter here. The DB lets
      // you flip the config, but the code needs to know how to translate.
      throw new Error(`Provider not implemented: ${provider}`);
  }
}

function pickModel(cfg: Record<string, unknown>, task: NormalizedRequest["task"]): string {
  const defaultModel = getString(cfg, "llm_model_default", "gemini-2.5-flash-lite");
  if (task === "chat") return getString(cfg, "llm_model_chat", defaultModel);
  return defaultModel;
}

// ─── Gemini adapter ─────────────────────────────────────────────────────────

interface GeminiPart {
  text?: string;
  inlineData?: { mimeType: string; data: string };
  functionCall?: { name: string; args: Record<string, unknown> };
  functionResponse?: { name: string; response: { content: unknown } };
}
interface GeminiContent {
  role: "user" | "model";
  parts: GeminiPart[];
}

async function geminiGenerate(
  model: string,
  req: NormalizedRequest,
  maxTokens: number,
): Promise<NormalizedResponse> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY not set");

  const contents: GeminiContent[] = [];
  for (const msg of req.messages) {
    if (msg.role === "tool") {
      // Tool result — Gemini expects a user-role content with a
      // functionResponse part. The matching functionCall is in a prior
      // model-role content (provided by the caller in messages history).
      contents.push({
        role: "user",
        parts: [
          {
            functionResponse: {
              name: msg.tool_call_id ?? "tool",
              response: {
                content: msg.tool_result
                  ? safeParseJSON(msg.tool_result)
                  : {},
              },
            },
          },
        ],
      });
      continue;
    }
    const role = msg.role === "assistant" ? "model" : "user";
    const parts: GeminiPart[] = [];
    if (msg.image_base64) {
      parts.push({
        inlineData: { mimeType: "image/jpeg", data: msg.image_base64 },
      });
    }
    if (msg.content !== undefined && msg.content !== "") {
      parts.push({ text: msg.content });
    }
    if (parts.length === 0) continue;
    contents.push({ role, parts });
  }

  const body: Record<string, unknown> = {
    contents,
    generationConfig: { maxOutputTokens: maxTokens },
  };
  if (req.system) {
    body.systemInstruction = { parts: [{ text: req.system }] };
  }
  if (req.tools && req.tools.length > 0) {
    body.tools = [
      {
        functionDeclarations: req.tools.map((t) => ({
          name: t.name,
          description: t.description,
          parameters: t.parameters,
        })),
      },
    ];
  }

  const resp = await fetchWithRetry(
    `${GEMINI_BASE}/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": apiKey,
      },
      body: JSON.stringify(body),
    },
  );
  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Gemini ${resp.status}: ${errText.slice(0, 500)}`);
  }
  const data = await resp.json();
  return parseGeminiResponse(data);
}

function parseGeminiResponse(data: unknown): NormalizedResponse {
  // Defensive parsing — bad Gemini responses (safety filters, empty
  // candidates) should produce an empty result, not a 500.
  const json = data as Record<string, unknown>;
  const candidates = json.candidates as Array<Record<string, unknown>> | undefined;
  const content = candidates?.[0]?.content as { parts?: GeminiPart[] } | undefined;
  const parts = content?.parts ?? [];

  const toolCalls: NormalizedToolCall[] = [];
  let text = "";
  for (const part of parts) {
    if (part.functionCall) {
      toolCalls.push({
        id: part.functionCall.name,
        name: part.functionCall.name,
        arguments: part.functionCall.args ?? {},
      });
    } else if (part.text) {
      text += part.text;
    }
  }
  return {
    text: text.length > 0 ? text : null,
    tool_calls: toolCalls.length > 0 ? toolCalls : null,
  };
}

function safeParseJSON(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return { text: s };
  }
}

// Transient overload retry — Gemini occasionally returns 503/429 under global
// load. Three retries with exponential backoff is enough to ride past the
// minute-scale throttles we've seen in production.
async function fetchWithRetry(url: string, init: RequestInit): Promise<Response> {
  const delaysMs = [1000, 2000, 4000];
  let lastResp: Response | null = null;
  for (let attempt = 0; attempt <= delaysMs.length; attempt++) {
    const resp = await fetch(url, init);
    if (resp.ok) return resp;
    if (resp.status !== 429 && resp.status !== 503 && resp.status !== 529) {
      return resp;
    }
    lastResp = resp;
    if (attempt < delaysMs.length) {
      await new Promise((r) => setTimeout(r, delaysMs[attempt]));
    }
  }
  return lastResp!;
}

// ─── Transcribe ─────────────────────────────────────────────────────────────

export interface TranscribeRequest {
  audio_base64: string;
  mime_type: string;
  language?: string | null;
}

export async function transcribe(req: TranscribeRequest): Promise<{ text: string }> {
  const cfg = await getConfig();
  const provider = getString(cfg, "llm_provider", "gemini");
  const model = getString(cfg, "llm_model_transcribe", getString(cfg, "llm_model_default", "gemini-2.5-flash-lite"));

  if (provider !== "gemini") {
    throw new Error(`Transcribe provider not implemented: ${provider}`);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY not set");

  const langHint = req.language
    ? ` Prefer language code ${req.language} when interpreting speech, but preserve the spoken language if clearly different.`
    : "";
  const prompt = `Transcribe this audio to text for a food logging app.${langHint} Return only the transcript text. Do not add summaries, labels, markdown, timestamps, or quotes.`;

  const body = {
    contents: [
      {
        parts: [
          {
            inlineData: { mimeType: req.mime_type || "audio/m4a", data: req.audio_base64 },
          },
          { text: prompt },
        ],
      },
    ],
  };

  const resp = await fetchWithRetry(
    `${GEMINI_BASE}/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": apiKey,
      },
      body: JSON.stringify(body),
    },
  );
  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Gemini ${resp.status}: ${errText.slice(0, 500)}`);
  }
  const data = await resp.json();
  const parsed = parseGeminiResponse(data);
  const text = (parsed.text ?? "").trim();
  if (!text) throw new Error("empty_transcript");
  return { text };
}
