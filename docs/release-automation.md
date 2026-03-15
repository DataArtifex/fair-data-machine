# Release Automation (Toolchain Image)

This guide explains how to build and package all required images from this scaffold.

## What gets built

- **Toolchain base image** assembled from component Dockerfiles in `scripts/build/components/` (with QLever enabled by default).

Model files are handled outside the image and mounted at runtime to `/var/lib/ollama/models`.

## Scripts

- `scripts/deployment/build-release-images.sh`
- `scripts/deployment/export-release-artifacts.sh`
- `scripts/deployment/import-release-artifacts.sh`
- `scripts/test/smoke-test-image.sh`
- `scripts/test/smoke-test-inner.sh`
- `scripts/test/smoke-test-addons.sh`

## Smoke test structure

Smoke tests are organized as one all-in-one suite with optional add-on checks:

- `smoke-test-inner.sh`: base checks that should pass for every image.
- `smoke-test-addons.sh`: optional component checks (R, QLever, Oxygraph, Ollama).
- `smoke-test-image.sh`: runner that mounts the test directory into the container and executes the main suite.

Behavior:
- Base checks always run.
- Add-on checks run when an add-on is discovered in the image.
- Add-ons not present are reported as skipped.
- If an add-on is expected by include flags but missing, tests fail.

## 1) Build release image

```bash
RELEASE_TAG=2026.03.13 \
REGISTRY_PREFIX= \
./scripts/deployment/build-release-images.sh
```

Useful options:
- `REGISTRY_PREFIX=registry.local` to tag images for internal registry naming.
- `TOOLCHAIN_IMAGE_NAME` to customize repository name.

Composition examples:

```bash
# Base only
RELEASE_TAG=2026.03.13 ./scripts/deployment/build-release-images.sh

# Base + R (user-invoked preset script)
RELEASE_TAG=2026.03.13 ./scripts/build/r.sh

# Base + Ollama (+ optional R)
RELEASE_TAG=2026.03.13 ./scripts/build/ollama-r.sh
```

## 2) Export release artifacts (no-registry path or transfer bundle)

```bash
RELEASE_TAG=2026.03.13 \
OUT_DIR=release/2026.03.13 \
./scripts/deployment/export-release-artifacts.sh
```

Output:
- `toolchain_<tag>.tar`
- `SHA256SUMS.txt`
- `release-manifest.txt`

## 3) Push directly to registry (connected environment)

Login:

```bash
docker login
```

Build with registry-prefixed tags:

```bash
RELEASE_TAG=2026.03.13 \
REGISTRY_PREFIX=docker.io \
./scripts/deployment/build-release-images.sh
```

Push:

```bash
docker push docker.io/kulnor/fair-data-machine:2026.03.13
```

For private registries:

```bash
docker login registry.local
RELEASE_TAG=2026.03.13 REGISTRY_PREFIX=registry.local ./scripts/deployment/build-release-images.sh
docker push registry.local/kulnor/fair-data-machine:2026.03.13
```

## 4) Import artifacts in secure environment

```bash
./scripts/deployment/import-release-artifacts.sh release/2026.03.13
```

This loads all tar archives and verifies checksums when `SHA256SUMS.txt` is present.

## 5) Optional: push imported images to local registry

```bash
PUSH_TO_REGISTRY=true \
REGISTRY_PREFIX=registry.local \
./scripts/deployment/import-release-artifacts.sh release/2026.03.13
```

## Naming convention recommendation

- Toolchain: `kulnor/fair-data-machine:<release-tag>`

Use immutable tags for approved releases.

## Smoke checks after import

```bash
docker images | grep -E "kulnor/fair-data-machine"
docker run --rm kulnor/fair-data-machine:2026.03.13 duckdb --version
```

For model files, verify volume-backed model store on a runtime host:

```bash
docker run --rm -v ollama_models:/var/lib/ollama/models alpine ls -la /var/lib/ollama/models
```
