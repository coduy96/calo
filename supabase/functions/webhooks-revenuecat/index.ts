// RevenueCat webhook receiver. Receives subscription lifecycle events and
// keeps the `entitlements` table in sync. Idempotent via rc_events.event_id.
//
// Configure in RevenueCat dashboard:
//   URL: https://<project-ref>.supabase.co/functions/v1/webhooks-revenuecat
//   Authorization header: Bearer <REVENUECAT_WEBHOOK_SECRET>
//
// Events handled (others are stored for audit but don't mutate entitlements):
//   INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE, TRIAL_STARTED, TRIAL_CONVERTED
//     -> upsert entitlement as active with expires_at
//   CANCELLATION (auto-renewal off; access continues until expires_at)
//     -> store but keep is_active until EXPIRATION
//   EXPIRATION, SUBSCRIPTION_PAUSED, BILLING_ISSUE
//     -> mark is_active=false
//   TRANSFER (subscription moved to a different app_user_id, e.g. restore on
//     a new install)
//     -> delete the old install row and upsert the new one

import { createClient } from "jsr:@supabase/supabase-js@2";

const ACTIVATING_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "TRIAL_STARTED",
  "TRIAL_CONVERTED",
  "UNCANCELLATION",
]);

const DEACTIVATING_EVENTS = new Set([
  "EXPIRATION",
  "SUBSCRIPTION_PAUSED",
]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), { status: 405 });
  }

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (secret) {
    const got = req.headers.get("authorization") ?? "";
    const expected = `Bearer ${secret}`;
    if (got !== expected) {
      return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
    }
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid_json" }), { status: 400 });
  }

  const event = (body.event ?? {}) as Record<string, unknown>;
  const eventID = (event.id as string) ?? crypto.randomUUID();
  const eventType = (event.type as string) ?? "UNKNOWN";

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Idempotency: insert into rc_events first. If event_id already exists,
  // the unique-violation tells us this is a replay and we can short-circuit.
  const { error: insertErr } = await supa
    .from("rc_events")
    .insert({ event_id: eventID, event_type: eventType, payload: body });
  if (insertErr) {
    // Most likely a unique-violation replay. RC retries on non-2xx.
    if (insertErr.code === "23505") {
      return new Response(JSON.stringify({ ok: true, dedup: true }), { status: 200 });
    }
    console.error("rc_events insert failed:", insertErr);
    return new Response(JSON.stringify({ error: "db_error" }), { status: 500 });
  }

  try {
    await applyEvent(supa, eventType, event);
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    console.error("apply event failed:", e);
    return new Response(JSON.stringify({ error: "apply_failed", message: String(e) }), {
      status: 500,
    });
  }
});

// deno-lint-ignore no-explicit-any
async function applyEvent(supa: any, eventType: string, event: Record<string, unknown>) {
  const appUserID = (event.app_user_id as string) ?? null;
  const productID = (event.product_id as string) ?? null;
  const expirationAtMs = event.expiration_at_ms as number | undefined;
  const expiresAt = expirationAtMs ? new Date(expirationAtMs).toISOString() : null;
  const periodType = (event.period_type as string) ?? null;
  const isTrial = periodType === "TRIAL";

  // TRANSFER moves an entitlement from one app_user_id to another (typically
  // when a user restores on a fresh install: a new install_id has the same
  // App Store purchase). Apply to the destination, clear the source.
  if (eventType === "TRANSFER") {
    const transferredFrom = (event.transferred_from as string[]) ?? [];
    const transferredTo = (event.transferred_to as string[]) ?? [];
    const newID = transferredTo[0] ?? appUserID;
    if (newID) {
      await supa.from("entitlements").upsert({
        install_id: newID,
        rc_app_user_id: newID,
        is_active: true,
        product_id: productID,
        is_trial: isTrial,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      });
    }
    if (transferredFrom.length > 0) {
      await supa
        .from("entitlements")
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .in("install_id", transferredFrom);
    }
    return;
  }

  if (!appUserID) return; // nothing to apply

  if (ACTIVATING_EVENTS.has(eventType)) {
    await supa.from("entitlements").upsert({
      install_id: appUserID,
      rc_app_user_id: appUserID,
      is_active: true,
      product_id: productID,
      is_trial: isTrial,
      expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    });
    return;
  }

  if (DEACTIVATING_EVENTS.has(eventType)) {
    await supa.from("entitlements").upsert({
      install_id: appUserID,
      rc_app_user_id: appUserID,
      is_active: false,
      product_id: productID,
      expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    });
    return;
  }

  // CANCELLATION = user disabled auto-renew but still has access until
  // expires_at. Keep them active; the eventual EXPIRATION event flips it off.
  // BILLING_ISSUE = same — RC keeps grace-period flag, we trust expires_at.
  if (eventType === "CANCELLATION" || eventType === "BILLING_ISSUE") {
    await supa
      .from("entitlements")
      .update({
        product_id: productID,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq("install_id", appUserID);
    return;
  }

  // TEST and any unknown event types: stored in rc_events but no state change.
}
