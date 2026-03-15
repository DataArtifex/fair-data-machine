# AI Agent Guide (AGENTS.md)

This document defines the baseline goals for the `fair-data-machine` image. The aim is to provide a reproducible Docker environment for the Data Artifex ecosystem that can be extended over time.

## Scope

Build a Docker image with the following baseline stack:

| Category | Component | Short description | Why useful for FAIRification |
| --- | --- | --- | --- |
| Core platform | Ubuntu 24.04 base image | Stable Linux base for all tooling and scripts. | Improves reproducibility and portability of FAIR workflows across environments. |
| Core platform | `dartfx` user with sudo access | Non-root operational user for day-to-day work. | Supports safer, auditable data processing practices in shared or sensitive setups. |
| Core platform | Supervisor | Process manager for long-running services in container. | Keeps key FAIR infrastructure services available and restartable. |
| Core platform | Workspace-oriented container runtime | Mount host workspace into the container. | Lets data, metadata, and scripts stay co-located for traceable pipeline execution. |
| Data and metadata tooling | Python + `uv` | Fast Python dependency and environment management. | Enables reproducible metadata processing, validation, and transformation scripts. |
| Data and metadata tooling | R (`R` / `Rscript`) | Statistical computing and reporting runtime. | Supports data quality analysis, disclosure control, and FAIR-ready statistical workflows. |
| Data and metadata tooling | VisiData (`vd`) | Terminal-first interactive tabular data exploration. | Speeds data inspection and curation before publication. |
| Data and metadata tooling | DuckDB CLI | Embedded analytical SQL engine. | Efficiently profiles and transforms large tabular data with reproducible SQL steps. |
| Data and metadata tooling | QSV CLI | High-performance CSV toolkit. | Streamlines schema checks, profiling, and normalization of common exchange formats. |
| Data and metadata tooling | ReadStat CLI | Converts/reads statistical formats (SPSS/Stata/SAS). | Improves interoperability when FAIRifying legacy statistical datasets. |
| Application and AI tooling | Node via `nvm` + `pnpm` | JavaScript runtime and package manager stack. | Supports FAIR-related API utilities, agents, and automation tooling. |
| Application and AI tooling | Ollama + `ollama-code` | Local LLM runtime and coding/chat client. | Enables private, offline-capable AI assistance for metadata authoring and transformation tasks. |
| Databases and extensions | PostgreSQL + `pgvector` | Relational DB plus vector extension. | Supports structured metadata storage and semantic/embedding-based retrieval workflows. |
| Integrations | QLever | RDF/SPARQL-oriented query engine tooling. | Helps expose and query FAIR knowledge graph outputs. |
| Integrations | Oxygraph | Lightweight RDF graph database tooling. | Supports machine-actionable linked-data publishing and validation patterns. |
| Integrations | Nginx Proxy Manager | Reverse proxy and TLS management utility. | Simplifies controlled access to FAIR data services and internal endpoints. |

## Operating System

Use a current Ubuntu base and include the usual development and administration tools needed for package installation, builds, networking, monitoring, and shell usage.

## Users

Provide a `dartfx` user with sudo access for day-to-day development inside the container.

## Python

Install Python and expose `uv` in `PATH`.

Use `pyproject.toml` as the Python dependency manifest. By default, install Python dependencies into a `dartfx`-owned virtual environment rather than the system interpreter.

## Node

Install Node.js for `dartfx` using `nvm` and use `pnpm` as the default package manager.

## Ollama

Install the Ollama runtime and `@tcsenpai/ollama-code`.

Seed a default local configuration targeting `gpt-oss:20b`.

## PostgreSQL

Include PostgreSQL server/client support and the `pgvector` extension.

## DuckDB

Include DuckDB CLI/runtime support suitable for the target image architecture.

## Optional Integrations

Leave room for future integration of QLever, Oxygraph, and Nginx Proxy Manager, but keep those integrations lightweight and easy to refine.


