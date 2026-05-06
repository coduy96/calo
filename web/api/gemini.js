const DEFAULT_LIMIT = 80;
const FALLBACK_MODELS = {
  food: [
    "gemini-3.1-flash-lite-preview",
    "gemini-3-flash-preview",
    "gemini-2.5-flash-lite",
    "gemini-2.5-flash",
  ],
  coach: ["gemini-2.5-flash-lite", "gemini-2.5-flash"],
  speech: ["gemini-2.5-flash-lite", "gemini-2.5-flash"],
};

const memoryUsage = globalThis.__fudAIUsage ?? new Map();
globalThis.__fudAIUsage = memoryUsage;

export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    return response.status(405).json({ error: "Method not allowed." });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return response.status(500).json({ error: "Server is missing GEMINI_API_KEY." });
  }

  const installID = String(request.headers["x-fudai-install-id"] || "").trim();
  if (!installID) {
    return response.status(400).json({ error: "Missing install ID." });
  }

  const task = normalizeTask(request.body?.task);
  const geminiBody = request.body?.body;
  if (!task || !geminiBody || typeof geminiBody !== "object") {
    return response.status(400).json({ error: "Invalid request body." });
  }

  const quota = await consumeQuota(installID);
  if (!quota.allowed) {
    return response.status(429).json({
      error: `Daily Fud AI Plus limit reached. Try again tomorrow, or switch to BYOK for unlimited usage.`,
    });
  }

  const models = configuredModels(task);
  let lastError = null;

  for (const model of models) {
    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": apiKey,
        },
        body: JSON.stringify(geminiBody),
      }
    );

    const text = await upstream.text();
    if (upstream.ok) {
      response.setHeader("X-FudAI-Model", model);
      return response.status(200).send(text);
    }

    lastError = parseUpstreamError(text) || `Gemini ${model} failed with HTTP ${upstream.status}.`;
    if (![429, 500, 503, 529].includes(upstream.status)) {
      break;
    }
  }

  return response.status(502).json({ error: lastError || "Gemini request failed." });
}

function normalizeTask(task) {
  if (task === "food" || task === "coach" || task === "speech") {
    return task;
  }
  return null;
}

function configuredModels(task) {
  const envKey = {
    food: "GEMINI_FOOD_MODELS",
    coach: "GEMINI_COACH_MODELS",
    speech: "GEMINI_SPEECH_MODELS",
  }[task];

  const configured = process.env[envKey]
    ?.split(",")
    .map((model) => model.trim())
    .filter(Boolean);

  return configured?.length ? configured : FALLBACK_MODELS[task];
}

async function consumeQuota(installID) {
  const limit = Number(process.env.FUD_AI_PLUS_DAILY_LIMIT || DEFAULT_LIMIT);
  const key = `fudai:plus:${todayKey()}:${installID}`;

  if (process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN) {
    const count = await kvCommand(["INCR", key]);
    if (count === 1) {
      await kvCommand(["EXPIRE", key, secondsUntilTomorrow() + 3600]);
    }
    return { allowed: count <= limit, count, limit };
  }

  const current = memoryUsage.get(key) || 0;
  const next = current + 1;
  memoryUsage.set(key, next);
  return { allowed: next <= limit, count: next, limit };
}

async function kvCommand(command) {
  const result = await fetch(process.env.KV_REST_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.KV_REST_API_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(command),
  });
  const json = await result.json();
  if (!result.ok) {
    throw new Error(json?.error || "KV command failed.");
  }
  return Number(json.result);
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function secondsUntilTomorrow() {
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setUTCHours(24, 0, 0, 0);
  return Math.max(3600, Math.ceil((tomorrow.getTime() - now.getTime()) / 1000));
}

function parseUpstreamError(text) {
  try {
    const json = JSON.parse(text);
    return json?.error?.message || json?.error || null;
  } catch {
    return text || null;
  }
}
