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

echo "Copied env to $DST"