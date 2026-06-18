#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$HOME/Desktop/Projetos/ai-trip-planner/.env}"
DST="${2:-$ROOT/.env}"
NETLIFY_SCRIPT="$ROOT/scripts/copy_env_from_netlify.sh"

log() {
  printf '→ %s\n' "$*" >&2
}

copy_from_local() {
  if [[ ! -f "$SRC" ]]; then
    echo "Source .env not found: $SRC" >&2
    return 1
  fi

  cp "$SRC" "$DST"

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

  log "Copied env from $SRC to $DST"
}

copy_from_netlify() {
  if [[ ! -x "$NETLIFY_SCRIPT" ]]; then
    echo "Netlify copy script not found: $NETLIFY_SCRIPT" >&2
    return 1
  fi

  "$NETLIFY_SCRIPT" "$DST"
}

main() {
  if command -v netlify >/dev/null 2>&1; then
    if copy_from_netlify; then
      return 0
    fi

    log "Netlify fetch failed — falling back to local .env"
  else
    log "netlify CLI not installed — using local .env"
  fi

  copy_from_local
}

main "$@"

echo "Keys in $DST:" >&2
awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/ {
  val=$2; gsub(/^[ \t]+|[ \t]+$/, "", val); gsub(/^"|"$/, "", val);
  if (length(val) > 0) print "  " $1 "=set"; else print "  " $1 "=empty"
}' "$DST" | sort >&2