-- Voidpen LLM cost report.
-- Run via scripts/cost.sh (psql), or paste a single section into the Supabase
-- SQL editor (Studio ignores the \echo lines / temp view — see the standalone
-- query at the bottom for a Studio-friendly one-shot).
--
-- COST MODEL: Gemini bills input on prompt tokens and output on EVERYTHING the
-- model emits — visible output PLUS hidden "thinking" tokens. token_usage_daily
-- stores output_tokens = visible only, so the billed output is
-- (total_tokens - prompt_tokens). Per-model USD rates per 1,000,000 tokens live
-- in the app_config 'model_prices' jsonb. Models missing there cost $0 (and are
-- flagged in the last section) — add them to model_prices.

-- One shared cost definition for every section below.
create temp view _cost as
with prices as (select value as m from app_config where key = 'model_prices')
select
  t.day,
  t.feature,
  t.model,
  t.request_count,
  t.prompt_tokens,
  t.output_tokens,
  t.total_tokens,
  (p.m ? t.model) as has_rate,
  t.prompt_tokens / 1e6 * coalesce((p.m -> t.model ->> 'input_per_million')::numeric, 0)
    + (t.total_tokens - t.prompt_tokens) / 1e6 * coalesce((p.m -> t.model ->> 'output_per_million')::numeric, 0)
    as cost_usd
from token_usage_daily t
cross join prices p;

\echo
\echo ===== Daily cost, last 30 days (UTC days) =====
select day,
       sum(request_count)      as reqs,
       round(sum(cost_usd), 4) as cost_usd
from _cost
where day >= current_date - interval '30 days'
group by day
order by day desc;

\echo
\echo ===== Daily cost by model, last 14 days =====
select day, model,
       sum(request_count)      as reqs,
       round(sum(cost_usd), 4) as cost_usd
from _cost
where day >= current_date - interval '14 days'
group by day, model
order by day desc, cost_usd desc;

\echo
\echo ===== Total cost by model (all time) =====
select model,
       sum(request_count)                as reqs,
       sum(prompt_tokens)                as prompt_tokens,
       sum(total_tokens - prompt_tokens) as billed_output_tokens,
       round(sum(cost_usd), 4)           as cost_usd
from _cost
group by model
order by cost_usd desc;

\echo
\echo ===== Totals (all time / this month / today) =====
select round(sum(cost_usd), 4)                                                                  as total_usd,
       round(sum(cost_usd) filter (where day >= date_trunc('month', current_date)::date), 4)    as this_month_usd,
       round(sum(cost_usd) filter (where day = current_date), 4)                                as today_usd,
       sum(request_count)                                                                       as total_reqs
from _cost;

\echo
\echo ===== WARNING: models used but missing a rate in model_prices (counted as 0) =====
select distinct model from _cost where not has_rate;

-- ─────────────────────────────────────────────────────────────────────────────
-- Studio one-shot (paste this single statement into the Supabase SQL editor):
--
-- with prices as (select value as m from app_config where key='model_prices'),
-- c as (
--   select t.day, t.request_count,
--     t.prompt_tokens/1e6 * coalesce((p.m->t.model->>'input_per_million')::numeric,0)
--     + (t.total_tokens - t.prompt_tokens)/1e6 * coalesce((p.m->t.model->>'output_per_million')::numeric,0) as cost_usd
--   from token_usage_daily t cross join prices p
-- )
-- select coalesce(to_char(day,'YYYY-MM-DD'),'ALL-TIME TOTAL') as day,
--        sum(request_count) as reqs, round(sum(cost_usd),4) as cost_usd
-- from c group by rollup(day) order by day nulls last;
