#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-$HOME/Desktop/Projetos/ai-trip-planner/.env}"
DST="${2:-$HOME/Desktop/Projetos/trip-planner-ia-phx/.env}"

if [[ ! -f "$SRC" ]]; then
  echo "Source .env not found: $SRC" >&2
  exit 1
fi

cp "$SRC" "$DST"

# Map better-auth vars to Phoenix equivalents
if grep -q '^BETTER_AUTH_SECRET=' "$DST" && ! grep -q '^SECRET_KEY_BASE=' "$DST"; then
  secret=$(grep '^BETTER_AUTH_SECRET=' "$DST" | cut -d= -f2-)
  echo "SECRET_KEY_BASE=$secret" >> "$DST"
fi

grep -q '^PHX_HOST=' "$DST" || echo "PHX_HOST=localhost" >> "$DST"
grep -q '^PORT=' "$DST" || echo "PORT=4000" >> "$DST"
grep -q '^PHX_SERVER=' "$DST" || echo "PHX_SERVER=true" >> "$DST"
grep -q '^TRIP_PLANNER_MULTI_STEP=' "$DST" || echo "TRIP_PLANNER_MULTI_STEP=true" >> "$DST"

if ! grep -q '^SECRET_KEY_BASE=.' "$DST"; then
  if command -v mix >/dev/null 2>&1; then
    secret="$(mix phx.gen.secret)"
    echo "SECRET_KEY_BASE=$secret" >> "$DST"
  fi
fi

echo "Copied env to $DST"
echo "Keys from $SRC:" >&2
awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/ {
  val=$2; gsub(/^[ \t]+|[ \t]+$/, "", val);
  if (length(val) > 0) print "  " $1 "=set"; else print "  " $1 "=empty"
}' "$DST" | sort >&2