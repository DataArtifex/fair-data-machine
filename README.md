# FAIR Data Machine

Welcome to the High-Value Data FAIRification machine.

Data work often starts with a directory of files: raw, master, or analytical dataset versions, plus documentation, scripts, and other descriptive artifacts.

To turn these assets into reusable digital products that can be consumed by users, loaded into databases, exposed through APIs, or leveraged by AI agents, data stewards (producers, librarians, researchers, and others) must process, transform, and package them consistently.

FAIR alignment also calls for machine-actionable metadata that follows generic or domain-specific standards and best practices.

To enable this, this Docker stack provides a practical “toolkit in a box” with a lean published base image and optional add-on layers you can compose for your use case.

The core principle is simple: associate the container with a workspace (the root directory where the data lives) and run FAIRification workflows in a reproducible, portable setup.

Guidance and tools are provided for deployment in closed environments (without Internet access, or with only intermittent access), which is common when working with sensitive data.

## Quick start

```bash
DATA_DIR="$HOME/data/my-project"
mkdir -p "$DATA_DIR"

docker run --rm -d \
  --name fair-data-machine \
  -p 5432:5432 \
  -v "$DATA_DIR":/workspace \
  kulnor/fair-data-machine:dev
```

This maps your local data/work directory (`$DATA_DIR`) into the container at `/workspace`.

Default services are managed by Supervisor:
- PostgreSQL

Useful runtime commands:

```bash
docker exec -it fair-data-machine supervisorctl status
docker exec -it fair-data-machine bash   # open interactive shell in the container
```

Need Ollama or other optional tooling? Build a derived image from the base (examples in “Compose add-ons from base image”).

## Technology stack and tools

This stack is intentionally practical and will be refined over time.

### Published base image (`kulnor/fair-data-machine`)

| Component | Description | FAIRification |
| --- | --- | --- |
| [Ubuntu 24.04](https://ubuntu.com/) base image | Stable Linux base for all tooling and scripts. | Improves reproducibility and portability of FAIR workflows across environments. |
| `dartfx` user with sudo access | Non-root operational user for day-to-day work. | Supports safer, auditable data processing practices in shared or sensitive setups. |
| [Supervisor](http://supervisord.org/) | Process manager for long-running services in container. | Keeps key FAIR infrastructure services available and restartable. |
| Workspace-oriented container runtime | Mount host workspace into the container. | Lets data, metadata, and scripts stay co-located for traceable pipeline execution. |

### Frameworks

| Component | Description | FAIRification |
| --- | --- | --- |
| [Python](https://www.python.org/) + [`uv`](https://docs.astral.sh/uv/) | Fast Python dependency and environment management. | Enables reproducible metadata processing, validation, and transformation scripts. |
| [Node.js](https://nodejs.org/) via [`nvm`](https://github.com/nvm-sh/nvm) + [`pnpm`](https://pnpm.io/) | JavaScript runtime and package manager stack. | Supports FAIR-related API utilities, agents, and automation tooling. |

### Tools

| Component | Description | FAIRification |
| --- | --- | --- |
| [VisiData](https://www.visidata.org/) (`vd`) | Terminal-first interactive tabular data exploration. | Speeds rapid inspection and curation of raw/master datasets before FAIR publication. |
| [QSV](https://github.com/jqnatividad/qsv) CLI | High-performance CSV toolkit. | Streamlines schema checks, profiling, and normalization of common exchange formats. |
| [ReadStat](https://github.com/WizardMac/ReadStat) CLI | Converts/reads statistical formats (SPSS/Stata/SAS). | Improves interoperability when FAIRifying legacy statistical datasets. |

### Databases

| Component | Description | FAIRification |
| --- | --- | --- |
| [PostgreSQL](https://www.postgresql.org/) + [`pgvector`](https://github.com/pgvector/pgvector) | Relational DB plus vector extension. | Supports structured metadata storage and semantic/embedding-based retrieval workflows. |
| [DuckDB](https://duckdb.org/) CLI | Embedded analytical SQL engine. | Efficiently profiles and transforms large tabular data with reproducible SQL steps. |
| [QLever](https://github.com/ad-freiburg/qlever) | RDF/SPARQL query tooling. | Serves as a default triple-store/query component for FAIR graph workflows. |

### AI

| Component | Description | FAIRification |
| --- | --- | --- |
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview) | Terminal-based Claude assistant for development tasks. | Supports assisted metadata authoring, transformation scripting, and FAIR workflow acceleration. |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Terminal-based Gemini assistant for development and automation workflows. | Enables AI-assisted documentation, pipeline scripting, and FAIR-oriented task automation. |

### Optional add-ons (build your own combinations)

| Add-on | Description | Typical when |
| --- | --- | --- |
| [R](https://www.r-project.org/) (`R` / `Rscript`) | Statistical computing/runtime layer. | You need disclosure control, statistical QA, or R-native workflows. |
| [Oxygraph](https://github.com/oxigraph/oxigraph) | Lightweight RDF graph database tooling. | You need local graph storage/querying for linked data. |
| [Ollama](https://ollama.com/) + [`ollama-code`](https://www.npmjs.com/package/@tcsenpai/ollama-code) | Local LLM runtime and coding/chat client. | You need offline/local model serving and coding assistant workflows. |
| [Nginx Proxy Manager](https://nginxproxymanager.com/) | Reverse proxy and TLS management utility. | You need HTTP ingress/TLS routing in deployment topologies. |

## AI CLI authentication (shell only)

The image includes both `claude` and `gemini` CLIs. Configure credentials at runtime in your shell (recommended) rather than baking secrets into image layers.

### Claude Code CLI

Interactive OAuth login:

```bash
claude auth login
claude auth status
```

Non-interactive API key auth:

```bash
export ANTHROPIC_API_KEY='your-anthropic-api-key'
claude auth status
```

Optional token-based auth (if you already have an OAuth token):

```bash
export CLAUDE_CODE_OAUTH_TOKEN='your-oauth-token'
```

### Gemini CLI

API key auth (use one of these env vars):

```bash
export GEMINI_API_KEY='your-gemini-api-key'
# or
export GOOGLE_API_KEY='your-google-api-key'
```

Vertex AI auth:

```bash
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT='your-project-id'
export GOOGLE_CLOUD_LOCATION='us-central1'
```

If you see a warning about `~/.gemini/projects.json`, initialize the directory once:

```bash
mkdir -p ~/.gemini
```


## Build

```bash
make build-release
```

### Build cache strategy

Builds are composed from layered component Dockerfiles in `scripts/build/components/`:
- Foundation first: `ubuntu-base.Dockerfile`.
- Then base components: `python`, `node`, `visidata`, `qsv`, `readstat`, `postgres`, `duckdb`, optional `qlever`, then `claude` and `gemini`.
- Add-ons (`r`, `ollama`, `oxygraph`) are derived on top of base via `scripts/build/*.sh`.

Practical guidance:
- If you change one component Dockerfile, only that layer and later layers in the chain rebuild.
- If you change `pyproject.toml` or `r-packages.txt`, only Python/R-related component layers rebuild.
- Runtime script/supervisor changes mainly affect the foundation and final runtime behavior.

### Image size profile

Measured on 2026-03-14 from local image sizes (`docker image inspect ... .Size`) using `:dev` tags.

| Component / Variant | Approx size | How measured |
| --- | ---: | --- |
| Base image (`kulnor/fair-data-machine:dev`) | ~1.02 GiB | Direct image size |
| QLever (default in base) | ~7.6 MiB | `base - base-no-qlever` |
| R add-on | ~84.8 MiB | `base-r - base` |
| Oxygraph add-on | ~7.5 MiB | `base-oxygraph - base` |
| Ollama add-on | ~2.01 GiB | `base-ollama - base` |
| R on top of Ollama | ~92.4 MiB | `base-ollama-r - base-ollama` |

Notes:
- Numbers are approximate and can vary by architecture, upstream package updates, and cache state.
- Derived add-on builds now use `FROM base`, so these deltas represent practical incremental cost for composed images.

Why Docker may report more than in-container `du` totals:
- `docker image ls` / `docker system df` report uncompressed layer accounting and snapshot overhead.
- In-container filesystem size can appear lower than Docker Desktop “disk usage”.
- Build cache is separate from final image size and can be large after repeated builds.

Useful diagnostics:

```bash
docker image inspect kulnor/fair-data-machine:dev kulnor/fair-data-machine-r:dev kulnor/fair-data-machine-ollama:dev --format '{{index .RepoTags 0}}|{{.Size}}'
docker history --no-trunc kulnor/fair-data-machine:dev
docker run --rm kulnor/fair-data-machine:dev bash -lc 'du -x -h -d1 / | sort -h'
docker system df -v
```

### Compose add-ons from base image

Only the base image is published by default. Add-ons are composed as derived images from the published base.

Build published base image:

```bash
make build-release
```

Compose with supported commands:

```bash
# base + R
scripts/build/r.sh

# base + Ollama
scripts/build/ollama.sh

# base + Ollama + R
scripts/build/ollama-r.sh
```

Preset combo scripts (examples)

For convenience, common compositions are also provided as executable wrappers in `scripts/build`:

```bash
scripts/build/base.sh
scripts/build/ollama.sh
scripts/build/r.sh
scripts/build/ollama-r.sh
```

These scripts are user-invoked examples only. They are not executed by default `make build-release`, `make build-release-ollama`, or CI smoke workflows unless explicitly called.

Behavior:
- `base.sh` builds the base image.
- Add-on scripts (`r.sh`, `ollama.sh`, `ollama-r.sh`) build derived images `FROM` base.
- If base is not available locally, add-on scripts run `base.sh` first, then build only add-on layers.

Common overrides:
- `RELEASE_TAG`, `REGISTRY_PREFIX`, `RUN_POST_BUILD_TESTS`
- `TOOLCHAIN_IMAGE_NAME` (output image name)
- `BASE_IMAGE_NAME` (base image repo, default `kulnor/fair-data-machine`)

Example:

```bash
RELEASE_TAG=2026.03.14 RUN_POST_BUILD_TESTS=false scripts/build/ollama-r.sh
```

### Component build architecture

Each add-on is defined exactly once in `scripts/build/components/`:

| File | Installs |
| --- | --- |
| `components/r.Dockerfile` | R runtime (`r-base`, `r-base-dev`) |
| `components/ollama.Dockerfile` | Ollama runtime + `ollama-code` CLI |

All build orchestration — base bootstrap, component layering, temp-image chaining, and smoke test invocation — is centralized in `scripts/build/lib.sh`. The preset wrapper scripts (`r.sh`, `ollama.sh`, `ollama-r.sh`) only declare which components to compose; no installation code is repeated across scripts.

To add a new component:
1. Create `scripts/build/components/<name>.Dockerfile` with `ARG BASE_IMAGE` at the top.
2. Reference the component by name in any wrapper script that calls `build_composed_image`.

Important: combinations must still be built into a concrete image tag (`docker pull` cannot merge arbitrary tags at pull time).

### Build versioned images (toolchain by default)

```bash
RELEASE_TAG=2026.03.13 \
./scripts/deployment/build-release-images.sh
```

Or with Make:

```bash
make build-release RELEASE_TAG=2026.03.13
```

By default, `build-release` runs post-build smoke tests against the built image.

Skip tests when needed:

```bash
make build-release RELEASE_TAG=2026.03.13 RUN_POST_BUILD_TESTS=false
```

Run smoke tests directly:

```bash
make test-image RELEASE_TAG=2026.03.13
```

Smoke test architecture:
- Main suite: `scripts/test/smoke-test-inner.sh` (always-on base checks and orchestration).
- Add-on suite: `scripts/test/smoke-test-addons.sh` (optional component checks).
- Runner: `scripts/test/smoke-test-image.sh` mounts the test directory into the container and executes the main suite.

Add-on behavior:
- Add-on checks run when the component is discovered in the image (for example via `command -v`).
- Missing optional components are reported as skipped.
- If a build flag indicates an add-on should be present but it is missing, the smoke test fails.

On Apple Silicon macOS, regular local builds already produce Linux arm64 images when using the default Docker engine architecture.

CI note: the same smoke tests run automatically in GitHub Actions on push, pull request, and manual dispatch via [.github/workflows/smoke-tests.yml](.github/workflows/smoke-tests.yml).

See [Release automation](docs/release-automation.md) for full options.

### Export/import image artifacts (Make)

```bash
make export-release RELEASE_TAG=2026.03.13
make import-release ARTIFACT_DIR=release/2026.03.13
```

Push imported artifacts to an internal registry:

```bash
make import-release-push ARTIFACT_DIR=release/2026.03.13 REGISTRY_PREFIX=registry.local
```

### Push images to a Docker registry

Login first:

```bash
docker login
```

Build images tagged for your registry namespace and push:

```bash
make build-release \
  RELEASE_TAG=2026.03.13 \
  REGISTRY_PREFIX=docker.io

docker push docker.io/kulnor/fair-data-machine:2026.03.13
```

For private/internal registries:

```bash
docker login registry.local
make build-release RELEASE_TAG=2026.03.13 REGISTRY_PREFIX=registry.local
docker push registry.local/kulnor/fair-data-machine:2026.03.13
```

If you imported image tar artifacts first, use:

```bash
make import-release-push ARTIFACT_DIR=release/2026.03.13 REGISTRY_PREFIX=registry.local
```

## Optional integration notes

QLever, Oxygraph, and Nginx Proxy Manager are treated as optional add-ons in this model.

Nginx Proxy Manager remains configured in `docker-compose.yml` behind compose profile `npm-hook` (it does not start with default `docker compose up`).

## Offline deployment (secure no-internet)

Use the dedicated guides:
- [Offline deployment overview](docs/offline-deployment.md)
- [Artifact transfer workflow (no local registry)](docs/offline-artifact-transfer.md)
- [Local registry workflow (internal network)](docs/offline-local-registry.md)
- [Release automation (build/export/import)](docs/release-automation.md)

## Pre-installed language packages

### Python

Python supplemental packages are installed via `uv` into `/home/dartfx/.venvs/dartfx` from `pyproject.toml`.

Current default groups include:
- `core`: `ipython`, `jupyterlab`
- `data`: `duckdb`, `psycopg[binary]`, `pandas`, `pyarrow`
- `dartfx`: `dartfx-ddi`, `dartfx-rdf`

Update package groups in `pyproject.toml` under `[tool.dartfx.python.packages]`.

### Node

Node is installed for `dartfx` via `nvm` (LTS), and the following global npm packages are pre-installed:
- `pnpm`
- `@anthropic-ai/claude-code`
- `@google/gemini-cli`

`@tcsenpai/ollama-code` is installed only in images that include the Ollama add-on.

`package.json` is currently empty and is not used as the source of preinstalled Node dependencies in the image build.

### R

R is treated as an optional add-on in the composition model.

If you include R in a derived image, supplemental packages are defined in `r-packages.txt` (one package per line; comments allowed) and installed during the R component build.

Manifest layout note:
- Keep `pyproject.toml` and `package.json` at repository root (tooling convention).
- Keep `r-packages.txt` at repository root so Docker can copy it into the image.
- Put internal-only project configuration under a dedicated folder such as `config/` to avoid confusion.
