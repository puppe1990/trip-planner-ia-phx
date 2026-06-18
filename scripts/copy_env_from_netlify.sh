#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NETLIFY_SITE="${NETLIFY_SITE:-ai-trip-planner-mnpuppe}"
NETLIFY_SITE_ID="${NETLIFY_SITE_ID:-752bff89-1f49-4739-9c55-db4329a220c3}"
NETLIFY_CONTEXT="${NETLIFY_CONTEXT:-production}"
LOCAL_FALLBACK="${LOCAL_FALLBACK:-$HOME/Desktop/Projetos/ai-trip-planner/.env}"
DST="${1:-$ROOT/.env}"

log() {
  printf '→ %s\n' "$*" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

ensure_netlify_link() {
  if [[ -f .netlify/state.json ]]; then
    return 0
  fi

  log "Linking project to Netlify site $NETLIFY_SITE"
  netlify link --id "$NETLIFY_SITE_ID"
}

write_env_file() {
  LOCAL_FALLBACK="$LOCAL_FALLBACK" \
  NETLIFY_CONTEXT="$NETLIFY_CONTEXT" \
  DST="$DST" \
  ROOT="$ROOT" \
  python3 - <<'PY'
import os
import re
import shutil
import subprocess
from pathlib import Path

context = os.environ["NETLIFY_CONTEXT"]
dst = Path(os.environ["DST"])
root = Path(os.environ["ROOT"])
local_fallback = Path(os.environ["LOCAL_FALLBACK"])
existing_dst = dst.read_text(encoding="utf-8") if dst.exists() else ""

KEYS = [
    "AI_PROVIDER",
    "AI_MODEL",
    "GEMINI_API_KEY",
    "NVIDIA_API_KEY",
    "TURSO_DATABASE_URL",
    "TURSO_AUTH_TOKEN",
    "BETTER_AUTH_SECRET",
    "BETTER_AUTH_URL",
    "TRIP_PLANNER_MULTI_STEP",
]


def log(msg: str) -> None:
    print(f"→ {msg}", file=os.sys.stderr)


def is_masked(value: str) -> bool:
    return "*" in value or value.startswith("No value set in the")


def parse_env_file(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}

    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip().strip('"').strip("'")
        if value:
            values[key] = value
    return values


def netlify_get(key: str) -> str | None:
    try:
        result = subprocess.run(
            ["netlify", "env:get", key, "--context", context],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None

    value = (result.stdout or "").strip()
    if not value or is_masked(value):
        return None
    return value


def turso_db_name_for(url: str) -> str | None:
    turso_bin = shutil.which("turso")
    if not turso_bin:
        return None

    try:
        result = subprocess.run(
            [turso_bin, "db", "list"],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None

    if result.returncode != 0:
        return None

    for line in (result.stdout or "").splitlines():
        if url in line:
            return line.split()[0]

    return None


def turso_token_for(url: str) -> str | None:
    db_name = turso_db_name_for(url)
    if not db_name:
        return None

    turso_bin = shutil.which("turso")
    if not turso_bin:
        return None

    try:
        result = subprocess.run(
            [turso_bin, "db", "tokens", "create", db_name],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None

    if result.returncode != 0:
        log(f"turso db tokens create failed: {(result.stderr or result.stdout).strip()}")
        return None

    lines = [line.strip() for line in (result.stdout or "").splitlines() if line.strip()]
    if not lines:
        return None

    token = lines[-1]
    return token if token and not is_masked(token) else None


def mix_secret() -> str | None:
    try:
        result = subprocess.run(
            ["mix", "phx.gen.secret"],
            check=False,
            capture_output=True,
            text=True,
            cwd=root,
        )
    except FileNotFoundError:
        return None

    value = (result.stdout or "").strip()
    return value or None


def quote(value: str) -> str:
    if re.search(r'[\s#"\'\']', value):
        return '"' + value.replace('"', '\\"') + '"'
    return value


local_values = parse_env_file(local_fallback)
existing_values = parse_env_file(dst)
resolved: dict[str, str] = {}

for key in KEYS:
    value = netlify_get(key)
    if value:
        resolved[key] = value
    elif key in local_values:
        log(f"Using local fallback for {key}")
        resolved[key] = local_values[key]

if not resolved.get("TURSO_AUTH_TOKEN") and resolved.get("TURSO_DATABASE_URL", "").startswith("libsql://"):
    token = turso_token_for(resolved["TURSO_DATABASE_URL"])
    if token:
        log("Created Turso auth token from turso CLI")
        resolved["TURSO_AUTH_TOKEN"] = token
    else:
        log("Could not create Turso auth token — set TURSO_AUTH_TOKEN manually")

secret_key_base = resolved.get("BETTER_AUTH_SECRET") or existing_values.get("SECRET_KEY_BASE")
if not secret_key_base:
    secret_key_base = mix_secret()
    if secret_key_base:
        log("Generated SECRET_KEY_BASE")

lines = []
if resolved.get("AI_PROVIDER"):
    lines.append(f"AI_PROVIDER={quote(resolved['AI_PROVIDER'])}")
if resolved.get("AI_MODEL"):
    lines.append(f"AI_MODEL={quote(resolved['AI_MODEL'])}")
else:
    lines.append("AI_MODEL=")
if resolved.get("GEMINI_API_KEY"):
    lines.append(f"GEMINI_API_KEY={quote(resolved['GEMINI_API_KEY'])}")
if resolved.get("NVIDIA_API_KEY"):
    lines.append(f"NVIDIA_API_KEY={quote(resolved['NVIDIA_API_KEY'])}")
if resolved.get("TURSO_DATABASE_URL"):
    lines.append(f"TURSO_DATABASE_URL={quote(resolved['TURSO_DATABASE_URL'])}")
if resolved.get("TURSO_AUTH_TOKEN"):
    lines.append(f"TURSO_AUTH_TOKEN={quote(resolved['TURSO_AUTH_TOKEN'])}")
if secret_key_base:
    lines.append(f"SECRET_KEY_BASE={quote(secret_key_base)}")
lines.extend(
    [
        "PHX_HOST=localhost",
        "PORT=4000",
        "PHX_SERVER=true",
        f"TRIP_PLANNER_MULTI_STEP={quote(resolved.get('TRIP_PLANNER_MULTI_STEP', 'true'))}",
    ]
)

dst.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

print_summary() {
  awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/ {
    val=$2
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    gsub(/^"|"$/, "", val)
    if (length(val) > 0) print "  " $1 "=set"
    else print "  " $1 "=empty"
  }' "$DST" | sort >&2
}

main() {
  require_command netlify
  require_command python3

  ensure_netlify_link
  log "Fetching env from Netlify site=$NETLIFY_SITE context=$NETLIFY_CONTEXT"
  write_env_file
  log "Wrote $DST"
  log "Variables:"
  print_summary
}

main "$@"