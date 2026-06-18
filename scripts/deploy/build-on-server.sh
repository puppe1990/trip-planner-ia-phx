#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DEPLOY_IP="${DEPLOY_IP:-}"
DEPLOY_SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/lightsail-default-key-us-east-1.pem}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"

log() {
  printf '→ %s\n' "$*" >&2
}

resolve_deploy_ip() {
  if [[ -n "$DEPLOY_IP" ]]; then
    printf '%s' "$DEPLOY_IP"
    return 0
  fi

  aws lightsail get-static-ip \
    --static-ip-name "${LIGHTSAIL_STATIC_IP:-trip-planner-ip}" \
    --region "${AWS_REGION:-us-east-1}" \
    --query 'staticIp.ipAddress' \
    --output text
}

main() {
  DEPLOY_IP="$(resolve_deploy_ip)"
  chmod 600 "$DEPLOY_SSH_KEY"

  log "Packaging source for server build"
  tar -czf /tmp/trip_planner_ia-src.tar.gz \
    --exclude _build \
    --exclude deps \
    --exclude node_modules \
    --exclude .git \
    --exclude tmp \
    --exclude priv/static/assets \
    -C "$ROOT" .

  scp -i "$DEPLOY_SSH_KEY" -o StrictHostKeyChecking=accept-new \
    /tmp/trip_planner_ia-src.tar.gz "${DEPLOY_USER}@${DEPLOY_IP}:/tmp/"

  log "Building release on server (native linux/amd64)"
  ssh -i "$DEPLOY_SSH_KEY" -o StrictHostKeyChecking=accept-new \
    "${DEPLOY_USER}@${DEPLOY_IP}" 'bash -s' <<'REMOTE'
set -euo pipefail

log() { printf '→ %s\n' "$*" >&2; }

if ! swapon --show | grep -q /swapfile; then
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
fi

if ! command -v mise >/dev/null 2>&1; then
  log "Installing mise + Erlang/Elixir"
  sudo apt-get update
  sudo apt-get install -y curl build-essential git ca-certificates
  curl https://mise.run | sh
  echo 'eval "$(/home/ubuntu/.local/bin/mise activate bash)"' >> ~/.bashrc
fi

export PATH="/home/ubuntu/.local/bin:$PATH"
eval "$(/home/ubuntu/.local/bin/mise activate bash)"
mise install erlang@28.4.1 elixir@1.19.5-otp-28
mise use -g erlang@28.4.1 elixir@1.19.5-otp-28

log "Elixir $(elixir --version | head -1)"

rm -rf ~/trip_planner_ia_build
mkdir -p ~/trip_planner_ia_build
tar -xzf /tmp/trip_planner_ia-src.tar.gz -C ~/trip_planner_ia_build
cd ~/trip_planner_ia_build

export MIX_ENV=prod
export SECRET_KEY_BASE=buildtime_secret_key_base_32chars_min
export TURSO_DATABASE_URL=libsql://build.turso.io

mix local.hex --force
mix local.rebar --force
mix deps.get --only prod
mix compile
mix assets.setup
mix assets.deploy
mix release

RELEASE_DIR="/opt/trip_planner_ia/releases/build"
sudo mkdir -p "$RELEASE_DIR"
sudo rm -rf "${RELEASE_DIR:?}"/*
sudo cp -a _build/prod/rel/trip_planner_ia/. "$RELEASE_DIR/"
sudo ln -sfn "$RELEASE_DIR" /opt/trip_planner_ia/current
log "Server build complete"
REMOTE

  log "Build on server finished"
}

main "$@"