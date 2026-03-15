#!/usr/bin/env bash
# Exports a built image to tar, then writes checksums and a release manifest for transfer.
set -euo pipefail

RELEASE_TAG="${RELEASE_TAG:-dev}"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}"
TOOLCHAIN_IMAGE_NAME="${TOOLCHAIN_IMAGE_NAME:-kulnor/fair-data-machine}"
OUT_DIR="${OUT_DIR:-release/${RELEASE_TAG}}"

qualify() {
  local image_name="$1"
  if [[ -n "$REGISTRY_PREFIX" ]]; then
    echo "${REGISTRY_PREFIX%/}/${image_name}:${RELEASE_TAG}"
  else
    echo "${image_name}:${RELEASE_TAG}"
  fi
}

TOOLCHAIN_IMAGE="$(qualify "$TOOLCHAIN_IMAGE_NAME")"

mkdir -p "$OUT_DIR"

echo "[export] Exporting $TOOLCHAIN_IMAGE"
docker save -o "$OUT_DIR/toolchain_${RELEASE_TAG}.tar" "$TOOLCHAIN_IMAGE"

echo "[export] Writing checksums"
(
  cd "$OUT_DIR"
  shasum -a 256 ./*.tar > SHA256SUMS.txt
)

echo "[export] Writing release manifest"
{
  echo "release_tag=$RELEASE_TAG"
  echo "created_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "toolchain_image=$TOOLCHAIN_IMAGE"
  echo "git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
} > "$OUT_DIR/release-manifest.txt"

echo "[export] Done: $OUT_DIR"