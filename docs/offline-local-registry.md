# Local Registry Workflow (Internal Offline Network)

This workflow is for secure environments with no internet but with internal network connectivity and a private container registry.

## Overview

You import approved images into a local registry, then all runtime hosts pull from that registry. This is usually the best long-term operating model.

## 1) Deploy a local registry in secure environment

Use any approved platform (Harbor, Nexus, Artifactory, or Docker Distribution).

Minimum recommendations:
- TLS enabled
- authentication and RBAC
- immutable tags for released artifacts
- retention policy for old tags

## 2) Define repository layout and naming

Example repositories:

- `registry.local/kulnor/fair-data-machine`

Example tags:

- `2026.03.13`
- `2026.03.13-hotfix1`

Prefer immutable release tags and optionally add a moving alias (for example `stable`) only for convenience.

## 3) Build and validate in connected environment

Choose the image composition before build (base only, or base + selected add-ons).

Preferred path:

```bash
RELEASE_TAG=2026.03.13 \
REGISTRY_PREFIX=registry.local \
./scripts/deployment/build-release-images.sh
```

Composed examples:

```bash
# Base + R (QLever is in base by default)
RELEASE_TAG=2026.03.13 REGISTRY_PREFIX=registry.local ./scripts/build/r.sh

# Base + Ollama
RELEASE_TAG=2026.03.13 REGISTRY_PREFIX=registry.local ./scripts/build/ollama.sh
```

Run validations (examples):

```bash
docker run --rm registry.local/kulnor/fair-data-machine:2026.03.13 duckdb --version
docker run --rm registry.local/kulnor/fair-data-machine:2026.03.13 python -c "import pandas, pyarrow, duckdb"
```

Generate SBOM/security outputs and release notes in the connected zone.

## 4) Transfer and import to local registry

Preferred path (export in connected zone):

```bash
RELEASE_TAG=2026.03.13 \
REGISTRY_PREFIX=registry.local \
OUT_DIR=release/2026.03.13 \
./scripts/deployment/export-release-artifacts.sh
```

Preferred path (import + push in secure zone):

```bash
PUSH_TO_REGISTRY=true \
REGISTRY_PREFIX=registry.local \
./scripts/deployment/import-release-artifacts.sh release/2026.03.13
```

Manual equivalent:

If direct registry push from connected zone is not allowed, transfer via tar files:

```bash
docker save -o toolchain_2026.03.13.tar registry.local/kulnor/fair-data-machine:2026.03.13
```

In secure environment:

```bash
docker load -i toolchain_2026.03.13.tar
docker push registry.local/kulnor/fair-data-machine:2026.03.13
```

## 5) Configure runtime hosts

- Allow runtime hosts to access only internal services needed for operation:
  - local registry
  - internal DNS/NTP/logging/monitoring as required
- Block internet egress.
- Configure hosts to trust internal registry CA certificate.

## 6) Deploy from local registry

Example compose image references:

```yaml
services:
  dartfx:
    image: registry.local/kulnor/fair-data-machine:2026.03.13
```

## 7) Promotion and rollback strategy

Recommended environments inside secure network:
- `dev` → `staging` → `prod`

Promotion options:
- re-tag and copy the same digest between repos/namespaces
- keep the same digest and update deployment references

Rollback:
- deploy previous known-good immutable tag
- maintain previous model tag compatibility notes

## 8) Ollama model handling (only for Ollama-composed images)

Recommended pattern for closed environments:

- Store approved model tarballs in internal artifact storage.
- Restore into persistent model volumes at deployment (`/var/lib/ollama/models`).
- Keep model artifact versioning separate from container image tags.

## 9) Operations checklist

- Registry uptime/backup monitored
- Image signature verification policy enforced
- Release notes include image digests + model revision
- Periodic cleanup/retention applied without deleting active tags

## Pros / Cons

**Pros**
- Fast and repeatable multi-host rollouts
- Centralized lifecycle and governance
- Better long-term scalability

**Cons**
- Requires additional secure infrastructure
- Registry operations and backup responsibility
