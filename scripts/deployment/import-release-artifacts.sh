#!/usr/bin/env bash
# Imports exported image artifacts, verifies checksums, and can retag/push to an internal registry.
set -euo pipefail

ARTIFACT_DIR="${1:-}"
if [[ -z "$ARTIFACT_DIR" ]]; then
  echo "Usage: $0 <artifact_dir>"
  exit 1
fi

PUSH_TO_REGISTRY="${PUSH_TO_REGISTRY:-false}"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}"

if [[ ! -d "$ARTIFACT_DIR" ]]; then
  echo "[import] Artifact directory not found: $ARTIFACT_DIR"
  exit 1
fi

if [[ -f "$ARTIFACT_DIR/SHA256SUMS.txt" ]]; then
  echo "[import] Verifying checksums"
  (
    cd "$ARTIFACT_DIR"
    shasum -a 256 -c SHA256SUMS.txt
  )
else
  echo "[import] WARNING: SHA256SUMS.txt not found, skipping checksum verification"
fi

shopt -s nullglob
archives=("$ARTIFACT_DIR"/*.tar)

if (( ${#archives[@]} == 0 )); then
  echo "[import] No tar archives found in $ARTIFACT_DIR"
  exit 1
fi

for archive in "${archives[@]}"; do
  echo "[import] Loading $archive"
  docker load -i "$archive"
done

if [[ "$PUSH_TO_REGISTRY" == "true" ]]; then
  if [[ -z "$REGISTRY_PREFIX" ]]; then
    echo "[import] REGISTRY_PREFIX is required when PUSH_TO_REGISTRY=true"
    exit 1
  fi

  echo "[import] Retag/push enabled for registry: $REGISTRY_PREFIX"
  while IFS='=' read -r key value; do
    case "$key" in
      toolchain_image|model_image)
        source_image="$value"
        target_image="${REGISTRY_PREFIX%/}/${source_image#*/}"
        echo "[import] Tagging $source_image -> $target_image"
        docker tag "$source_image" "$target_image"
        echo "[import] Pushing $target_image"
        docker push "$target_image"
        ;;
    esac
  done < "$ARTIFACT_DIR/release-manifest.txt"
fi

echo "[import] Done"