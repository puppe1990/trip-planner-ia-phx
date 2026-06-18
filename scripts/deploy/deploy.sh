#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DEPLOY_IP="${DEPLOY_IP:-}"
DEPLOY_SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/lightsail-default-key-us-east-1.pem}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
TARBALL="${RELEASE_TARBALL:-}"
SHA="$(git rev-parse --short HEAD)"

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

resolve_tarball() {
  if [[ -n "$TARBALL" && -f "$TARBALL" ]]; then
    printf '%s' "$TARBALL"
    return 0
  fi

  local candidate="$ROOT/tmp/trip_planner_ia-${SHA}.tar.gz"
  if [[ -f "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  echo "Release tarball not found. Run ./scripts/deploy/build-release.sh first." >&2
  exit 1
}

main() {
  require_command ssh
  require_command scp

  DEPLOY_IP="$(resolve_deploy_ip)"
  TARBALL="$(resolve_tarball)"

  if [[ -z "$DEPLOY_IP" || "$DEPLOY_IP" == "None" ]]; then
    echo "Could not resolve DEPLOY_IP" >&2
    exit 1
  fi

  chmod 600 "$DEPLOY_SSH_KEY"

  log "Deploying $TARBALL to $DEPLOY_USER@$DEPLOY_IP"

  scp -i "$DEPLOY_SSH_KEY" -o StrictHostKeyChecking=accept-new \
    "$TARBALL" "${DEPLOY_USER}@${DEPLOY_IP}:/tmp/trip_planner_ia-${SHA}.tar.gz"

  ssh -i "$DEPLOY_SSH_KEY" -o StrictHostKeyChecking=accept-new \
    "${DEPLOY_USER}@${DEPLOY_IP}" "bash -s" "$SHA" <<'REMOTE'
set -euo pipefail
SHA="$1"

log() { printf '→ %s\n' "$*" >&2; }

RELEASE_DIR="/opt/trip_planner_ia/releases/${SHA}"

sudo mkdir -p "$RELEASE_DIR"
sudo tar -xzf "/tmp/trip_planner_ia-${SHA}.tar.gz" -C "$RELEASE_DIR"
sudo ln -sfn "$RELEASE_DIR" /opt/trip_planner_ia/current

if [[ -f /etc/trip_planner_ia/env ]]; then
  log "Running migrations"
  sudo bash -c 'set -a; source /etc/trip_planner_ia/env; set +a; /opt/trip_planner_ia/current/bin/migrate'
fi

log "Restarting trip_planner_ia"
sudo systemctl restart trip_planner_ia
sudo systemctl --no-pager --full status trip_planner_ia | head -20
REMOTE

  log "Deploy complete"
  log "Check: curl -I http://${DEPLOY_IP}:4000 (or https://${DEPLOY_HOST:-your-domain})"
}

main "$@"