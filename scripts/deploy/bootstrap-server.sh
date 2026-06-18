#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DEPLOY_IP="${DEPLOY_IP:-}"
DEPLOY_HOST="${DEPLOY_HOST:-}"
DEPLOY_SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/lightsail-default-key-us-east-1.pem}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
CADDY_EMAIL="${CADDY_EMAIL:-}"

log() {
  printf '→ %s\n' "$*" >&2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
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

ssh_cmd() {
  ssh -i "$DEPLOY_SSH_KEY" \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=15 \
    "${DEPLOY_USER}@${DEPLOY_IP}" "$@"
}

scp_to_server() {
  scp -i "$DEPLOY_SSH_KEY" \
    -o StrictHostKeyChecking=accept-new \
    "$1" "${DEPLOY_USER}@${DEPLOY_IP}:$2"
}

main() {
  require_command ssh
  require_command scp

  DEPLOY_IP="$(resolve_deploy_ip)"

  if [[ -z "$DEPLOY_IP" || "$DEPLOY_IP" == "None" ]]; then
    echo "Could not resolve DEPLOY_IP" >&2
    exit 1
  fi

  if [[ ! -f "$DEPLOY_SSH_KEY" ]]; then
    echo "SSH key not found: $DEPLOY_SSH_KEY" >&2
    exit 1
  fi

  chmod 600 "$DEPLOY_SSH_KEY"

  log "Bootstrapping $DEPLOY_USER@$DEPLOY_IP"

  scp_to_server "$ROOT/deploy/trip_planner_ia.service" "/tmp/trip_planner_ia.service"
  if [[ -n "$DEPLOY_HOST" ]]; then
    ./scripts/deploy/sync-production-env.sh "$ROOT/tmp/production.env"
    scp_to_server "$ROOT/tmp/production.env" "/tmp/trip_planner_ia.env"

    cat >"$ROOT/tmp/Caddyfile" <<EOF
{
	email ${CADDY_EMAIL:-admin@${DEPLOY_HOST}}
}

${DEPLOY_HOST} {
	encode gzip
	reverse_proxy 127.0.0.1:4000
}
EOF
    scp_to_server "$ROOT/tmp/Caddyfile" "/tmp/Caddyfile"
  fi

  ssh_cmd "DEPLOY_HOST='${DEPLOY_HOST}' bash -s" <<'REMOTE'
set -euo pipefail

log() { printf '→ %s\n' "$*" >&2; }

if ! swapon --show | grep -q /swapfile; then
  log "Creating 2GB swap"
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

if ! command -v caddy >/dev/null 2>&1; then
  log "Installing Caddy"
  sudo apt-get update
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y caddy
fi

sudo mkdir -p /opt/trip_planner_ia/releases /etc/trip_planner_ia

if [[ -f /tmp/trip_planner_ia.env ]]; then
  log "Installing production env"
  sudo mv /tmp/trip_planner_ia.env /etc/trip_planner_ia/env
  sudo chmod 600 /etc/trip_planner_ia/env
fi

sudo mv /tmp/trip_planner_ia.service /etc/systemd/system/trip_planner_ia.service
sudo systemctl daemon-reload
sudo systemctl enable trip_planner_ia

if [[ -n "${DEPLOY_HOST:-}" ]]; then
  log "Configuring Caddy for ${DEPLOY_HOST}"
  sudo mkdir -p /etc/caddy
  sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile
  sudo systemctl enable caddy
  sudo systemctl restart caddy
else
  log "DEPLOY_HOST not set — skipping Caddy HTTPS (configure later)"
fi

log "Bootstrap complete"
REMOTE

  log "Bootstrap finished for $DEPLOY_IP"
}

main "$@"