#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

IMAGE_NAME="${RELEASE_IMAGE:-trip-planner-release-builder}"
SHA="$(git rev-parse --short HEAD)"
OUTPUT_DIR="${RELEASE_OUTPUT_DIR:-$ROOT/tmp/release}"
TARBALL="${RELEASE_TARBALL:-$ROOT/tmp/trip_planner_ia-${SHA}.tar.gz}"

log() {
  printf '→ %s\n' "$*" >&2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

main() {
  require_command docker
  require_command git

  mkdir -p "$(dirname "$OUTPUT_DIR")" "$(dirname "$TARBALL")"
  rm -rf "$OUTPUT_DIR"

  log "Building linux/amd64 release with Docker (target=builder)"
  docker build \
    --platform linux/amd64 \
    --target builder \
    --build-arg MIX_ENV=prod \
    -t "$IMAGE_NAME" \
    -f Dockerfile \
    .

  container_id="$(docker create "$IMAGE_NAME")"
  trap 'docker rm -f "$container_id" >/dev/null 2>&1 || true' EXIT

  log "Extracting release from container"
  docker cp "$container_id:/app/_build/prod/rel/trip_planner_ia" "$OUTPUT_DIR"

  log "Creating tarball $TARBALL"
  tar -czf "$TARBALL" -C "$OUTPUT_DIR" .

  log "Release ready: $TARBALL"
  printf '%s\n' "$TARBALL"
}

main "$@"