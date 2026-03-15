#!/usr/bin/env bash
# Runs container smoke tests for a target image by executing the in-container test suite.
set -euo pipefail

IMAGE="${1:-}"

if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 <image-ref>"
  echo "Example: $0 kulnor/fair-data-machine:dev"
  exit 1
fi

echo "[test] Running smoke tests for image: $IMAGE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker run --rm \
  -v "$SCRIPT_DIR":/opt/dartfx/smoke-tests:ro \
  "$IMAGE" \
  bash /opt/dartfx/smoke-tests/smoke-test-inner.sh

echo "[test] All smoke tests passed for: $IMAGE"