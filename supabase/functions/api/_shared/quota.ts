import { createClient } from "jsr:@supabase/supabase-js@2";
import { getConfig, getNumber } from "./config.ts";
import { json } from "./cors.ts";

const FEATURE_TO_CONFIG_KEY: Record<string, string> = {
  food: "quota_food_per_day",
  label: "quota_label_per_day",
  chat: "quota_chat_per_day",
  transcribe: "quota_transcribe_per_day",
  weight: "quota_weight_per_day",
  goals: "quota_goals_per_day",
};

const FALLBACK_LIMITS: Record<string, number> = {
  food: 200,
  label: 200,
  chat: 100,
  transcribe: 60,
  weight: 20,
  goals: 10,
};

export async function enforceQuota(installID: string, feature: string): Promise<Response | null> {
  const cfg = await getConfig();
  const limit = getNumber(cfg, FEATURE_TO_CONFIG_KEY[feature] ?? "", FALLBACK_LIMITS[feature] ?? 100);

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Use UTC date so "day" is consistent globally. Users in different timezones
  // will see the rollover at midnight UTC — fine for a soft cap.
  const today = new Date().toISOString().slice(0, 10);
  const { data, error } = await supa.rpc("increment_usage", {
    p_install_id: installID,
    p_day: today,
    p_feature: feature,
  });
  if (error) {
    // Fail-open on DB error — paying users shouldn't be blocked by our infra
    // hiccups. The cap is a soft anti-abuse measure, not a paywall.
    console.error("quota rpc failed:", error);
    return null;
  }
  const count = typeof data === "number" ? data : 0;
  if (count > limit) {
    return json({ error: "rate_limit_exceeded", feature }, 429);
  }
  return null;
}
