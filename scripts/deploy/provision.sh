#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REGION="${AWS_REGION:-us-east-1}"
AZ="${AWS_AVAILABILITY_ZONE:-us-east-1a}"
INSTANCE_NAME="${LIGHTSAIL_INSTANCE:-trip-planner-ia}"
STATIC_IP_NAME="${LIGHTSAIL_STATIC_IP:-trip-planner-ip}"
KEY_PAIR_NAME="${LIGHTSAIL_KEY_PAIR:-trip-planner-key}"
BLUEPRINT_ID="${LIGHTSAIL_BLUEPRINT:-ubuntu_22_04}"
BUNDLE_ID="${LIGHTSAIL_BUNDLE:-nano_3_0}"

log() {
  printf '→ %s\n' "$*" >&2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

aws_lightsail() {
  aws lightsail "$@" --region "$REGION"
}

instance_exists() {
  aws_lightsail get-instance --instance-name "$INSTANCE_NAME" >/dev/null 2>&1
}

create_key_pair() {
  if aws_lightsail get-key-pair --key-pair-name "$KEY_PAIR_NAME" >/dev/null 2>&1; then
    log "Key pair $KEY_PAIR_NAME already exists"
    return 0
  fi

  log "Creating key pair $KEY_PAIR_NAME"
  if ! aws_lightsail create-key-pair --key-pair-name "$KEY_PAIR_NAME" >/dev/null 2>&1; then
    log "Could not create key pair — using Lightsail default SSH key"
    KEY_PAIR_NAME=""
  fi
}

create_instance() {
  if instance_exists; then
    log "Instance $INSTANCE_NAME already exists"
    return 0
  fi

  log "Creating Lightsail instance $INSTANCE_NAME ($BUNDLE_ID, dualstack)"
  if [[ -n "$KEY_PAIR_NAME" ]]; then
    aws_lightsail create-instances \
      --instance-names "$INSTANCE_NAME" \
      --availability-zone "$AZ" \
      --blueprint-id "$BLUEPRINT_ID" \
      --bundle-id "$BUNDLE_ID" \
      --key-pair-name "$KEY_PAIR_NAME" \
      --ip-address-type dualstack >/dev/null
  else
    aws_lightsail create-instances \
      --instance-names "$INSTANCE_NAME" \
      --availability-zone "$AZ" \
      --blueprint-id "$BLUEPRINT_ID" \
      --bundle-id "$BUNDLE_ID" \
      --ip-address-type dualstack >/dev/null
  fi

  log "Waiting for instance to become running..."
  for _ in $(seq 1 60); do
    state="$(aws_lightsail get-instance --instance-name "$INSTANCE_NAME" --query 'instance.state.name' --output text)"
    if [[ "$state" == "running" ]]; then
      break
    fi
    sleep 5
  done
}

ensure_static_ip() {
  if ! aws_lightsail get-static-ip --static-ip-name "$STATIC_IP_NAME" >/dev/null 2>&1; then
    log "Allocating static IP $STATIC_IP_NAME"
    aws_lightsail allocate-static-ip --static-ip-name "$STATIC_IP_NAME" >/dev/null
  fi

  attached="$(aws_lightsail get-static-ip --static-ip-name "$STATIC_IP_NAME" --query 'staticIp.attachedTo' --output text)"
  if [[ "$attached" == "None" || -z "$attached" ]]; then
    log "Attaching static IP to $INSTANCE_NAME"
    aws_lightsail attach-static-ip \
      --static-ip-name "$STATIC_IP_NAME" \
      --instance-name "$INSTANCE_NAME" >/dev/null
  fi
}

open_port() {
  local port="$1"
  local protocol="${2:-TCP}"

  aws_lightsail open-instance-public-ports \
    --instance-name "$INSTANCE_NAME" \
    --port-info "fromPort=${port},toPort=${port},protocol=${protocol}" >/dev/null 2>&1 || true
}

download_ssh_key() {
  local key_path="$HOME/.ssh/lightsail-${KEY_PAIR_NAME}-${REGION}.pem"

  if [[ -f "$key_path" ]]; then
    log "SSH key already present at $key_path"
    printf '%s' "$key_path"
    return 0
  fi

  log "Downloading default Lightsail SSH key"
  aws_lightsail download-default-key-pair --output text >/dev/null
  key_path="$HOME/.ssh/lightsail-default-key-${REGION}.pem"
  chmod 600 "$key_path" 2>/dev/null || true
  printf '%s' "$key_path"
}

print_summary() {
  local ipv4 ipv6 ssh_key

  ipv4="$(aws_lightsail get-static-ip --static-ip-name "$STATIC_IP_NAME" --query 'staticIp.ipAddress' --output text)"
  ipv6="$(aws_lightsail get-instance --instance-name "$INSTANCE_NAME" --query 'instance.ipv6Addresses[0]' --output text)"
  ssh_key="$(download_ssh_key)"

  cat >&2 <<EOF

Lightsail provisioned in ${REGION}

  Instance:  ${INSTANCE_NAME}
  Bundle:    ${BUNDLE_ID}
  IPv4:      ${ipv4}
  IPv6:      ${ipv6}
  SSH key:   ${ssh_key}

DNS (before HTTPS):
  A     @ -> ${ipv4}
  AAAA  @ -> ${ipv6}

Next steps:
  export DEPLOY_HOST=your-domain.com
  export DEPLOY_IP=${ipv4}
  export DEPLOY_SSH_KEY=${ssh_key}
  ./scripts/deploy/bootstrap-server.sh
  ./scripts/deploy/build-release.sh
  ./scripts/deploy/deploy.sh
EOF
}

main() {
  require_command aws

  log "Validating bundle ${BUNDLE_ID}"
  aws_lightsail get-bundles --query "bundles[?bundleId=='${BUNDLE_ID}'].[name,price,ramSizeInGb,cpuCount]" --output table

  create_key_pair
  create_instance
  ensure_static_ip
  open_port 80
  open_port 443
  print_summary
}

main "$@"