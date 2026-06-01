-- Per-install/day/feature/model token accounting. Append-only aggregate that
-- mirrors usage_daily (same install_id/day/feature keys) but adds the model
-- dimension and sums token counts instead of a request counter.
create table if not exists public.token_usage_daily (
  install_id    text    not null,
  day           date    not null,
  feature       text    not null,
  model         text    not null,
  prompt_tokens bigint  not null default 0,
  output_tokens bigint  not null default 0,
  total_tokens  bigint  not null default 0,
  request_count integer not null default 0,
  updated_at    timestamptz not null default now(),
  primary key (install_id, day, feature, model)
);

-- Service-role only, consistent with the other tables: RLS on, no public
-- policies (the edge function uses the service-role key, which bypasses RLS).
alter table public.token_usage_daily enable row level security;

-- Upsert that accumulates tokens and bumps request_count, mirroring
-- increment_usage. Called best-effort from the edge function after a
-- successful LLM call.
create or replace function public.record_token_usage(
  p_install_id text,
  p_day        date,
  p_feature    text,
  p_model      text,
  p_prompt     int,
  p_output     int,
  p_total      int
) returns void
language plpgsql
as $$
begin
  insert into token_usage_daily (
    install_id, day, feature, model,
    prompt_tokens, output_tokens, total_tokens, request_count, updated_at
  )
  values (
    p_install_id, p_day, p_feature, p_model,
    p_prompt, p_output, p_total, 1, now()
  )
  on conflict (install_id, day, feature, model)
  do update set
    prompt_tokens = token_usage_daily.prompt_tokens + excluded.prompt_tokens,
    output_tokens = token_usage_daily.output_tokens + excluded.output_tokens,
    total_tokens  = token_usage_daily.total_tokens  + excluded.total_tokens,
    request_count = token_usage_daily.request_count + 1,
    updated_at    = now();
end;
$$;

-- Per-model USD rates per 1,000,000 tokens. Cost is computed on read by joining
-- token_usage_daily against this map. NOTE: these are placeholder rates for
-- gemini-2.5-flash-lite — verify against current Google pricing and adjust.
insert into public.app_config (key, value)
values (
  'model_prices',
  '{"gemini-2.5-flash-lite": {"input_per_million": 0.10, "output_per_million": 0.40}}'::jsonb
)
on conflict (key) do nothing;
