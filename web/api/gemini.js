const DEFAULT_TASK_LIMITS = {
  food: 30,
  speech: 60,
  coach: 100,
};
const DEFAULT_GLOBAL_LIMIT = 200;
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

  const quota = await checkQuota(installID, task);
  if (!quota.allowed) {
    return response.status(429).json({
      error: quota.message,
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
      await recordSuccessfulUsage(installID, task);
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

async function checkQuota(installID, task) {
  const usage = await readUsage(installID, task);
  if (usage.taskCount >= usage.taskLimit) {
    return {
      allowed: false,
      ...usage,
      message: `${taskLabel(task)} daily limit reached (${usage.taskLimit}/day). Try again tomorrow, or switch to BYOK for unlimited usage.`,
    };
  }
  if (usage.globalCount >= usage.globalLimit) {
    return {
      allowed: false,
      ...usage,
      message: `Daily Fud AI Plus safety limit reached (${usage.globalLimit}/day). Try again tomorrow, or switch to BYOK for unlimited usage.`,
    };
  }
  return { allowed: true, ...usage };
}

async function readUsage(installID, task) {
  const globalKey = quotaKey(installID);
  const taskKey = quotaKey(installID, task);
  const taskLimit = taskDailyLimit(task);
  const globalLimit = globalDailyLimit();

  if (process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN) {
    const [taskCount, globalCount] = await Promise.all([
      kvCommand(["GET", taskKey]),
      kvCommand(["GET", globalKey]),
    ]);
    return { taskCount, globalCount, taskLimit, globalLimit };
  }

  return {
    taskCount: memoryUsage.get(taskKey) || 0,
    globalCount: memoryUsage.get(globalKey) || 0,
    taskLimit,
    globalLimit,
  };
}

async function recordSuccessfulUsage(installID, task) {
  const globalKey = quotaKey(installID);
  const taskKey = quotaKey(installID, task);

  if (process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN) {
    const [taskCount, globalCount] = await Promise.all([
      kvCommand(["INCR", taskKey]),
      kvCommand(["INCR", globalKey]),
    ]);
    const ttl = secondsUntilTomorrow() + 3600;
    await Promise.all([
      taskCount === 1 ? kvCommand(["EXPIRE", taskKey, ttl]) : Promise.resolve(),
      globalCount === 1 ? kvCommand(["EXPIRE", globalKey, ttl]) : Promise.resolve(),
    ]);
    return;
  }

  memoryUsage.set(taskKey, (memoryUsage.get(taskKey) || 0) + 1);
  memoryUsage.set(globalKey, (memoryUsage.get(globalKey) || 0) + 1);
}

function quotaKey(installID, task) {
  const base = `fudai:plus:${todayKey()}:${installID}`;
  return task ? `${base}:${task}` : base;
}

function taskDailyLimit(task) {
  const envKey = {
    food: "FUD_AI_PLUS_FOOD_DAILY_LIMIT",
    speech: "FUD_AI_PLUS_SPEECH_DAILY_LIMIT",
    coach: "FUD_AI_PLUS_COACH_DAILY_LIMIT",
  }[task];
  return positiveInteger(process.env[envKey], DEFAULT_TASK_LIMITS[task]);
}

function globalDailyLimit() {
  return positiveInteger(
    process.env.FUD_AI_PLUS_GLOBAL_DAILY_LIMIT ?? process.env.FUD_AI_PLUS_DAILY_LIMIT,
    DEFAULT_GLOBAL_LIMIT
  );
}

function positiveInteger(raw, fallback) {
  const parsed = Number(raw);
  return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : fallback;
}

function taskLabel(task) {
  switch (task) {
    case "food":
      return "Food analysis";
    case "speech":
      return "Speech-to-text";
    case "coach":
      return "Coach";
    default:
      return "Fud AI Plus";
  }
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
  return Number(json.result || 0);
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
