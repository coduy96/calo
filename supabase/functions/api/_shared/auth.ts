import { createClient } from "jsr:@supabase/supabase-js@2";
import { json } from "./cors.ts";

const RC_API = "https://api.revenuecat.com/v1";

// 5-minute fail-open allowlist keyed by install_id: if RC REST API is
// unreachable AND we previously confirmed the user is entitled, let them
// through so an RC outage doesn't lock out paying subscribers.
const failOpenCache = new Map<string, number>();
const FAIL_OPEN_TTL_MS = 5 * 60 * 1000;

export interface AuthOK {
  ok: true;
  installID: string;
}
export interface AuthFail {
  ok: false;
  response: Response;
}

/// Resolve the install_id from headers, then verify it has an active
/// entitlement. Strategy:
///   1) Check `entitlements` table for a still-valid row.
///   2) On miss or expired, query RevenueCat REST API once. Upsert the row so
///      subsequent calls hit the fast path.
///   3) On RC API error: fail-open if we've seen this install authenticated
///      within the last 5 minutes; otherwise 402.
export async function requireEntitlement(req: Request): Promise<AuthOK | AuthFail> {
  // Accept either header name — old app builds may send the legacy
  // X-Voidpen-Install-ID; new builds send X-Install-ID.
  const installID =
    req.headers.get("x-install-id") ?? req.headers.get("x-voidpen-install-id");
  if (!installID || installID.length < 8) {
    return { ok: false, response: json({ error: "missing_install_id" }, 400) };
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: row } = await supa
    .from("entitlements")
    .select("install_id, is_active, expires_at")
    .eq("install_id", installID)
    .maybeSingle();

  const now = new Date();
  if (
    row?.is_active &&
    (!row.expires_at || new Date(row.expires_at) > now)
  ) {
    failOpenCache.set(installID, Date.now() + FAIL_OPEN_TTL_MS);
    return { ok: true, installID };
  }

  // Cache miss / expired / not active — ask RevenueCat directly.
  const rcKey = Deno.env.get("REVENUECAT_API_KEY");
  if (!rcKey) {
    // No way to verify. Treat as no entitlement.
    return { ok: false, response: json({ error: "subscription_required" }, 402) };
  }

  try {
    const resp = await fetch(
      `${RC_API}/subscribers/${encodeURIComponent(installID)}`,
      { headers: { Authorization: `Bearer ${rcKey}` } },
    );
    if (resp.ok) {
      const body = await resp.json();
      const entitlement = body?.subscriber?.entitlements?.plus;
      const expiresStr = entitlement?.expires_date ?? null;
      const expiresDate = expiresStr ? new Date(expiresStr) : null;
      const active = !!entitlement && (!expiresDate || expiresDate > now);
      const productID = entitlement?.product_identifier ?? null;

      await supa.from("entitlements").upsert({
        install_id: installID,
        rc_app_user_id: installID,
        is_active: active,
        product_id: productID,
        expires_at: expiresStr,
        updated_at: now.toISOString(),
      });

      if (active) {
        failOpenCache.set(installID, Date.now() + FAIL_OPEN_TTL_MS);
        return { ok: true, installID };
      }
    }
  } catch (e) {
    console.error("RC API unreachable:", e);
    // Fall through to fail-open check.
  }

  // Fail-open path: if we recently confirmed this install was entitled, let
  // them keep working through a transient RC outage. New installs that have
  // never been verified just get 402.
  const expiry = failOpenCache.get(installID);
  if (expiry && expiry > Date.now()) {
    return { ok: true, installID };
  }

  return { ok: false, response: json({ error: "subscription_required" }, 402) };
}
