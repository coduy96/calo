// Single Edge Function fronting all paid-feature LLM traffic. Routes by
// sub-path. Every route is gated by an active RevenueCat entitlement and a
// per-install daily soft cap pulled from app_config.
//
//   POST /api/generate    { task, system?, messages, tools? } -> { text, tool_calls }
//   POST /api/transcribe  { audio_base64, mime_type, language? } -> { text }
//
// Tasks: food | label | chat | weight | goals. Each maps to its own quota
// bucket in usage_daily and (potentially) its own model in app_config.

import { corsHeaders, json, preflight } from "./_shared/cors.ts";
import { requireEntitlement } from "./_shared/auth.ts";
import { enforceQuota } from "./_shared/quota.ts";
import { recordTokenUsage } from "./_shared/usage.ts";
import {
  generate,
  transcribe,
  type NormalizedRequest,
  type TranscribeRequest,
} from "./_shared/llm.ts";

Deno.serve(async (req: Request) => {
  const pre = preflight(req);
  if (pre) return pre;

  const url = new URL(req.url);
  // Edge Functions are mounted at /functions/v1/<function-name>/, so inside
  // the handler the path is /<function-name>/<sub-path>. We strip the
  // function name to get the sub-path.
  const path = url.pathname.replace(/^\/api\/?/, "").replace(/^\/?/, "");

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  switch (path) {
    case "generate":
      return await handleGenerate(req);
    case "transcribe":
      return await handleTranscribe(req);
    default:
      return json({ error: "not_found", path }, 404);
  }
});

async function handleGenerate(req: Request): Promise<Response> {
  const auth = await requireEntitlement(req);
  if (!auth.ok) return auth.response;

  let body: NormalizedRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  if (!body || typeof body !== "object" || !body.task || !Array.isArray(body.messages)) {
    return json({ error: "invalid_request" }, 400);
  }
  if (!["food", "label", "chat", "weight", "goals"].includes(body.task)) {
    return json({ error: "invalid_task", task: body.task }, 400);
  }

  const quota = await enforceQuota(auth.installID, body.task);
  if (quota) return withCors(quota);

  try {
    const result = await generate(body);
    // Record token usage best-effort; recordTokenUsage never throws, so this
    // can't turn a successful generation into an error response.
    await recordTokenUsage(auth.installID, body.task, result.usage);
    return json(result.response);
  } catch (e) {
    console.error("generate failed:", e);
    return json({ error: "upstream_error", message: String(e) }, 502);
  }
}

async function handleTranscribe(req: Request): Promise<Response> {
  const auth = await requireEntitlement(req);
  if (!auth.ok) return auth.response;

  let body: TranscribeRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  if (!body || typeof body !== "object" || !body.audio_base64) {
    return json({ error: "invalid_request" }, 400);
  }

  const quota = await enforceQuota(auth.installID, "transcribe");
  if (quota) return withCors(quota);

  try {
    const result = await transcribe(body);
    await recordTokenUsage(auth.installID, "transcribe", result.usage);
    return json({ text: result.text });
  } catch (e) {
    console.error("transcribe failed:", e);
    return json({ error: "upstream_error", message: String(e) }, 502);
  }
}

function withCors(resp: Response): Response {
  const headers = new Headers(resp.headers);
  for (const [k, v] of Object.entries(corsHeaders)) headers.set(k, v);
  return new Response(resp.body, { status: resp.status, headers });
}
