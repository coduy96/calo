import { createClient } from "jsr:@supabase/supabase-js@2";
import type { TokenUsage } from "./llm.ts";

// Best-effort token accounting. Mirrors enforceQuota's upsert pattern, but sums
// token counts into token_usage_daily instead of bumping a request counter.
//
// This NEVER throws: a logging failure must not affect the user's response, and
// it's only ever called after the upstream LLM call has already succeeded. Uses
// the same UTC day bucket as the quota counter so the two tables join cleanly.
export async function recordTokenUsage(
  installID: string,
  feature: string,
  usage: TokenUsage,
): Promise<void> {
  try {
    const supa = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const today = new Date().toISOString().slice(0, 10);
    const { error } = await supa.rpc("record_token_usage", {
      p_install_id: installID,
      p_day: today,
      p_feature: feature,
      p_model: usage.model,
      p_prompt: usage.promptTokens,
      p_output: usage.outputTokens,
      p_total: usage.totalTokens,
    });
    if (error) console.error("record_token_usage rpc failed:", error);
  } catch (e) {
    console.error("recordTokenUsage threw:", e);
  }
}
