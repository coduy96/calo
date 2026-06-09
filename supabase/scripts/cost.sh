#!/usr/bin/env bash
# Voidpen LLM cost report — daily + total spend, computed from token_usage_daily
# against the app_config 'model_prices' rates. Thinking-token aware.
#
# Requires: psql (PostgreSQL client).
#
# Setup (once): copy the DB connection string from the Supabase dashboard →
#   Project Settings → Database → Connection string → "Session pooler" (URI).
# The URI already includes the password. Then export it:
#
#   export VOIDPEN_DB_URL='postgresql://postgres.ckllhxtjxevmnusdocbn:<PASSWORD>@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres'
#
# Usage:
#   ./supabase/scripts/cost.sh
set -euo pipefail

DB_URL="${VOIDPEN_DB_URL:-${DATABASE_URL:-}}"
if [[ -z "$DB_URL" ]]; then
  echo "Error: set VOIDPEN_DB_URL (or DATABASE_URL) to the Supabase Postgres connection string." >&2
  echo "  Supabase dashboard → Project Settings → Database → Connection string (Session pooler URI)." >&2
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "Error: psql not found. Install the PostgreSQL client (e.g. 'brew install libpq')." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/cost_report.sql"
