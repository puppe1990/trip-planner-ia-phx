#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DEPLOY_HOST="${DEPLOY_HOST:-}"
OUTPUT="${1:-$ROOT/tmp/production.env}"

if [[ -z "$DEPLOY_HOST" ]]; then
  echo "DEPLOY_HOST is required (your production domain)" >&2
  exit 1
fi

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env — run ./scripts/copy_env_from_netlify.sh first" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

python3 - <<'PY' "$ROOT/.env" "$OUTPUT" "$DEPLOY_HOST"
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
deploy_host = sys.argv[3]

values = {}
for line in src.read_text(encoding="utf-8").splitlines():
    if not line or line.lstrip().startswith("#") or "=" not in line:
        continue
    key, value = line.split("=", 1)
    value = value.strip().strip('"').strip("'")
    values[key] = value

wanted = [
    "AI_PROVIDER",
    "AI_MODEL",
    "GEMINI_API_KEY",
    "NVIDIA_API_KEY",
    "TURSO_DATABASE_URL",
    "TURSO_AUTH_TOKEN",
    "SECRET_KEY_BASE",
    "TRIP_PLANNER_MULTI_STEP",
]

lines = [
    "PHX_SERVER=true",
    "PORT=4000",
    f"PHX_HOST={deploy_host}",
    "POOL_SIZE=3",
]

for key in wanted:
    if key in values and values[key]:
        val = values[key]
        if any(ch in val for ch in ' #"\''):
            val = '"' + val.replace('"', '\\"') + '"'
        lines.append(f"{key}={val}")

out.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

printf '→ Wrote production env to %s\n' "$OUTPUT" >&2