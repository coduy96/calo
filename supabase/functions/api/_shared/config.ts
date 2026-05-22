import { createClient } from "jsr:@supabase/supabase-js@2";

// In-memory 60s TTL cache so we don't hit the DB on every request. Edge
// Functions reuse a warm V8 isolate across requests, so this works.
let cache: { values: Record<string, unknown>; expiresAt: number } | null = null;

export async function getConfig(): Promise<Record<string, unknown>> {
  if (cache && cache.expiresAt > Date.now()) return cache.values;
  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await supa.from("app_config").select("key,value");
  if (error || !data) throw new Error("Config fetch failed: " + (error?.message ?? "no data"));
  const values: Record<string, unknown> = {};
  for (const row of data) values[row.key] = row.value;
  cache = { values, expiresAt: Date.now() + 60_000 };
  return values;
}

export function getString(cfg: Record<string, unknown>, key: string, fallback: string): string {
  const v = cfg[key];
  return typeof v === "string" ? v : fallback;
}

export function getNumber(cfg: Record<string, unknown>, key: string, fallback: number): number {
  const v = cfg[key];
  return typeof v === "number" ? v : fallback;
}
