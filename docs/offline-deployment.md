# Offline Deployment Guide

This project supports two secure no-internet deployment patterns:

1. **Artifact transfer (no registry in offline environment)**
2. **Local registry (private registry inside offline network)**

Both approaches assume:
- No outbound internet from runtime hosts
- An internal network is available
- Sensitive data stays inside the secure environment

## Which option to choose

Choose **artifact transfer** when:
- You only have a few hosts
- Release cadence is low
- You want minimal infrastructure inside the secure network

Choose **local registry** when:
- You have multiple hosts/environments
- You want faster rollouts and rollback workflows
- You need central governance of image versions

## Recommended baseline architecture

- **Connected build zone**: builds, scans, signs, and packages container artifacts.
- **Transfer boundary**: approved media/process for import into secure environment.
- **Secure runtime zone**: runs containers with egress blocked to internet.

## Shared release model

Use a base-plus-add-on release model:

- **Base image**: published baseline (`kulnor/fair-data-machine`) with core stack.
- **Composed image(s)**: optional add-ons baked in during connected-zone build (for example R, QLever, Oxygraph, Ollama).
- **Model pack artifact**: Ollama model store and model metadata (only when Ollama is included).

This keeps core updates lightweight while allowing project-specific composed images for offline deployment.

Important offline rule:
- Decide add-ons and build the exact composed image in the connected build zone.
- Do not rely on installing add-ons in secure/offline runtime zones unless you also operate internal package mirrors.

## Detailed guides

- See [Artifact Transfer Workflow](offline-artifact-transfer.md)
- See [Local Registry Workflow](offline-local-registry.md)

## Security and compliance controls (for both)

- Pin base image and package versions where practical.
- Generate SBOM and vulnerability reports in connected build zone.
- Sign release artifacts and verify signatures before import/deploy.
- Enforce runtime egress policy (no internet) while allowing internal services.
- Keep model and image checksums with release notes.

## Ollama model strategy (for both)

- Keep `gpt-oss:20b` as a separately versioned deliverable.
- Track model revision and release date in deployment notes.
- Validate model load/start in a smoke test after deployment.

## Add-on composition examples (connected build zone)

```bash
# Base only
make build-release RELEASE_TAG=2026.03.13

# Base + R (QLever is in base by default)
RELEASE_TAG=2026.03.13 scripts/build/r.sh

# Base + Ollama + R
RELEASE_TAG=2026.03.13 scripts/build/ollama-r.sh
```
