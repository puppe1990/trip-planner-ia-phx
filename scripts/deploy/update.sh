#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Defaults — override with env vars or scripts/deploy/deploy.local.env
DEPLOY_IP="${DEPLOY_IP:-100.59.80.29}"
DEPLOY_HOST="${DEPLOY_HOST:-trip.gestaobem.com}"
DEPLOY_SSH_KEY="${DEPLOY_SSH_KEY:-$HOME/.ssh/lightsail-default-key-us-east-1.pem}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
LIGHTSAIL_STATIC_IP="${LIGHTSAIL_STATIC_IP:-trip-planner-ip}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -f "$ROOT/scripts/deploy/deploy.local.env" ]]; then
  # shellcheck source=/dev/null
  source "$ROOT/scripts/deploy/deploy.local.env"
fi

log() {
  printf '→ %s\n' "$*" >&2
}

die() {
  echo "Error: $*" >&2
  exit 1
}

resolve_deploy_ip() {
  if [[ -n "$DEPLOY_IP" ]]; then
    printf '%s' "$DEPLOY_IP"
    return 0
  fi

  if command -v aws >/dev/null 2>&1; then
    aws lightsail get-static-ip \
      --static-ip-name "$LIGHTSAIL_STATIC_IP" \
      --region "$AWS_REGION" \
      --query 'staticIp.ipAddress' \
      --output text 2>/dev/null || true
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

main() {
  require_command ssh
  require_command scp
  require_command tar

  DEPLOY_IP="$(resolve_deploy_ip)"

  if [[ -z "$DEPLOY_IP" || "$DEPLOY_IP" == "None" ]]; then
    die "Could not resolve DEPLOY_IP. Set DEPLOY_IP or configure AWS CLI."
  fi

  [[ -f "$DEPLOY_SSH_KEY" ]] || die "SSH key not found: $DEPLOY_SSH_KEY"
  chmod 600 "$DEPLOY_SSH_KEY"

  log "Updating Trip Planner IA on $DEPLOY_USER@$DEPLOY_IP"

  DEPLOY_IP="$DEPLOY_IP" DEPLOY_SSH_KEY="$DEPLOY_SSH_KEY" DEPLOY_USER="$DEPLOY_USER" \
    "$ROOT/scripts/deploy/build-on-server.sh"

  log "Running migrations and restarting app"
  ssh -i "$DEPLOY_SSH_KEY" -o StrictHostKeyChecking=accept-new \
    "${DEPLOY_USER}@${DEPLOY_IP}" 'bash -s' <<'REMOTE'
set -euo pipefail

log() { printf '→ %s\n' "$*" >&2; }

if [[ -f /etc/trip_planner_ia/env ]]; then
  log "Running migrations"
  sudo bash -c 'set -a; source /etc/trip_planner_ia/env; set +a; /opt/trip_planner_ia/current/bin/migrate'
else
  log "No /etc/trip_planner_ia/env — skipping migrations"
fi

log "Restarting trip_planner_ia"
sudo systemctl restart trip_planner_ia
sleep 2

if sudo systemctl is-active --quiet trip_planner_ia; then
  log "Service is active"
else
  sudo journalctl -u trip_planner_ia -n 30 --no-pager
  exit 1
fi
REMOTE

  local url="https://${DEPLOY_HOST}"
  log "Deploy finished"
  log "App: $url"

  if command -v curl >/dev/null 2>&1; then
    local code
    code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "$url" || echo "000")"
    log "Health check: HTTP $code"
  fi
}

main "$@"