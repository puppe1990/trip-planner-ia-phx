#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

log() {
  printf '→ %s\n' "$*" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

env_key_set() {
  local key="$1"
  [[ -f .env ]] && grep -q "^${key}=." .env
}

sync_env_from_original() {
  if [[ ! -x scripts/copy_env.sh ]]; then
    return 1
  fi

  scripts/copy_env.sh
}

load_env() {
  local original="$HOME/Desktop/Projetos/ai-trip-planner/.env"

  if [[ ! -f .env ]]; then
    log "No .env found — copying from ai-trip-planner"
    sync_env_from_original || log "Could not copy .env — continuing with defaults"
  elif [[ -f "$original" ]] && ! env_key_set "GEMINI_API_KEY" && ! env_key_set "NVIDIA_API_KEY"; then
    log ".env sem API keys — re-sincronizando do ai-trip-planner"
    sync_env_from_original || true
  fi

  if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
}

ensure_elixir_deps() {
  if [[ ! -d deps ]] || [[ ! -d _build/dev ]]; then
    log "Installing Elixir dependencies"
    mix deps.get
    mix compile
    return
  fi

  log "Elixir dependencies OK"
}

ensure_node_deps() {
  if [[ ! -f package.json ]]; then
    return
  fi

  if [[ ! -d node_modules ]] || [[ package-lock.json -nt node_modules/.package-lock.json ]]; then
    log "Installing Node dependencies"
    if [[ -f package-lock.json ]]; then
      npm ci
    else
      npm install
    fi
    return
  fi

  log "Node dependencies OK"
}

ensure_assets() {
  log "Ensuring asset tooling"
  mix assets.setup

  if [[ ! -f priv/static/assets/css/app.css ]] || [[ ! -f priv/static/assets/js/app.js ]]; then
    log "Building frontend assets"
    mix assets.build
  else
    log "Frontend assets OK"
  fi
}

ensure_database() {
  mkdir -p priv/data
  log "Running database migrations"
  mix ecto.migrate
}

is_port_in_use() {
  local port=$1

  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return
  fi

  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$port" >/dev/null 2>&1
    return
  fi

  echo "Cannot check port availability (need lsof or nc)" >&2
  exit 1
}

find_free_port() {
  local port=$1
  local max_port=$((port + 100))

  while is_port_in_use "$port"; do
    log "Port $port is in use, trying $((port + 1))"
    port=$((port + 1))

    if [[ $port -gt $max_port ]]; then
      echo "No free port found between $1 and $max_port" >&2
      exit 1
    fi
  done

  echo "$port"
}

stop_existing_dev_servers() {
  local pid cmd

  for pid in $(pgrep -x beam.smp 2>/dev/null || true); do
    cmd=$(ps -p "$pid" -o args= 2>/dev/null || true)

    if [[ "$cmd" == *"trip_planner_ia"* ]] || [[ "$cmd" == *"trip-planner-ia-phx"* ]]; then
      log "Stopping existing dev server (pid $pid)"
      kill "$pid" 2>/dev/null || true
    fi
  done

  sleep 1
}

main() {
  require_command mix
  require_command elixir

  load_env

  local base_port="${PORT:-4000}"
  local port

  ensure_elixir_deps
  ensure_node_deps
  ensure_assets
  ensure_database
  stop_existing_dev_servers

  port="$(find_free_port "$base_port")"
  export PORT="$port"

  if [[ "$port" != "$base_port" ]]; then
    log "Using port $port (default $base_port was busy)"
  else
    log "Using port $port"
  fi

  log "Starting server at http://localhost:$port"
  exec mix phx.server
}

main "$@"