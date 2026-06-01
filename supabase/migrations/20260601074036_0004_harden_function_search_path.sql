-- Pin search_path to '' on both usage-accounting functions and fully-qualify
-- table references, closing the function_search_path_mutable advisor WARN.
create or replace function public.increment_usage(
  p_install_id text,
  p_day        date,
  p_feature    text
) returns integer
language plpgsql
set search_path = ''
as $$
declare
  new_count int;
begin
  insert into public.usage_daily (install_id, day, feature, count)
  values (p_install_id, p_day, p_feature, 1)
  on conflict (install_id, day, feature)
  do update set count = public.usage_daily.count + 1
  returning count into new_count;
  return new_count;
end;
$$;

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
set search_path = ''
as $$
begin
  insert into public.token_usage_daily (
    install_id, day, feature, model,
    prompt_tokens, output_tokens, total_tokens, request_count, updated_at
  )
  values (
    p_install_id, p_day, p_feature, p_model,
    p_prompt, p_output, p_total, 1, now()
  )
  on conflict (install_id, day, feature, model)
  do update set
    prompt_tokens = public.token_usage_daily.prompt_tokens + excluded.prompt_tokens,
    output_tokens = public.token_usage_daily.output_tokens + excluded.output_tokens,
    total_tokens  = public.token_usage_daily.total_tokens  + excluded.total_tokens,
    request_count = public.token_usage_daily.request_count + 1,
    updated_at    = now();
end;
$$;
