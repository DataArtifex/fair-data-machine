#!/usr/bin/env bash
# Runner to execute smoke tests against a built image
set -euo pipefail

IMAGE="${1:-}"
if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[test] Running smoke tests for: $IMAGE"
docker run --rm \
  -v "$SCRIPT_DIR/smoke-test.sh":/tmp/smoke-test.sh:ro \
  "$IMAGE" \
  bash /tmp/smoke-test.sh
