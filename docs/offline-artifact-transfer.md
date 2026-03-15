# Artifact Transfer Workflow (No Local Registry)

This workflow is for secure environments with no internet and no internal registry.

## Overview

You build and validate images in a connected environment, export them as archives, transfer them into the secure environment, then load and run locally.

## 1) Build in connected environment

Choose the exact image composition before build (base only, or base + selected add-ons).

Preferred path:

```bash
RELEASE_TAG=2026.03.13 \
./scripts/deployment/build-release-images.sh
```

Composed examples:

```bash
# Base + R (QLever is in base by default)
RELEASE_TAG=2026.03.13 ./scripts/build/r.sh

# Base + Ollama + R
RELEASE_TAG=2026.03.13 ./scripts/build/ollama-r.sh
```

If Ollama is included, prepare a separate model data archive from a staging host after pulling required models.

## 2) Generate release manifest and checksums

Create an inventory file with:
- image names and tags
- digests
- build date
- source commit SHA

Generate checksums for exported archives:

```bash
shasum -a 256 fair-data-machine_dev.tar > SHA256SUMS.txt
```

Include model-data archive checksums when used.

## 3) Export artifacts

Preferred path:

```bash
RELEASE_TAG=2026.03.13 \
OUT_DIR=release/2026.03.13 \
./scripts/deployment/export-release-artifacts.sh
```

Manual equivalent:

Export toolchain image:

```bash
docker save -o fair-data-machine_dev.tar kulnor/fair-data-machine:dev
```

Export model files archive when Ollama is included (example):

```bash
tar -czf ollama-models_gpt-oss-20b.tar.gz -C /var/lib/ollama models
```

Bundle files for transfer:
- image tar files
- checksums
- release manifest
- deployment notes

## 4) Transfer into secure environment

Use your approved transfer mechanism (for example controlled removable media or internal transfer gateway).

Verify checksums before import:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

## 5) Import and run in secure environment

Preferred import:

```bash
./scripts/deployment/import-release-artifacts.sh release/2026.03.13
```

Manual equivalent:

Load images:

```bash
docker load -i fair-data-machine_dev.tar
```

Run base or composed container (example):

```bash
docker run --rm -it \
  -p 5432:5432 \
  -v "$PWD":/workspace \
  kulnor/fair-data-machine:dev
```

If the image includes Ollama, also expose port 11434 and mount model storage:

```bash
docker run --rm -it \
  -p 5432:5432 \
  -p 11434:11434 \
  -v "$PWD":/workspace \
  -v ollama_models:/var/lib/ollama/models \
  kulnor/fair-data-machine:dev
```

## 6) Offline model store (Ollama images only)

Model transfer in closed environments:

1. Prepare an Ollama model store archive from a staging machine.
2. Transfer archive into secure environment.
3. Mount/extract to a persistent volume used by Ollama.

Keep model artifact versioning separate from image versioning.

## 7) Post-deploy smoke tests

Inside secure environment:

```bash
docker images | grep dartfx
docker run --rm kulnor/fair-data-machine:dev duckdb --version
```

For Ollama runtime host (only when Ollama add-on is included):

```bash
ollama list
```

For Python env in container:

```bash
python -c "import pandas, pyarrow, duckdb; print('ok')"
```

## 8) Update and rollback pattern

- Keep previous release tar files and checksums.
- Roll forward by `docker load` of new release and retag if needed.
- Roll back by reloading previous tar and re-running previous compose/run spec.

## Pros / Cons

**Pros**
- Minimal infrastructure in secure network
- Simple to reason about and audit

**Cons**
- Manual image distribution to multiple hosts
- Slower frequent updates
- Harder centralized lifecycle management
