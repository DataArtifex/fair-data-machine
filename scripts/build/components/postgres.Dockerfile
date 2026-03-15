ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG PGVECTOR_VERSION=latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# PostgreSQL server, client, contrib, and dev headers for extensions.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      postgresql postgresql-client postgresql-contrib postgresql-server-dev-all && \
    rm -rf /var/lib/apt/lists/*

# pgvector: vector similarity search extension, built from source at selected version.
RUN set -eux; \
    version="${PGVECTOR_VERSION}"; \
    if [[ "${version}" == "latest" ]]; then \
      version="$(curl -fsSL https://api.github.com/repos/pgvector/pgvector/releases/latest | jq -r '.tag_name // empty' || true)"; \
      if [[ -z "${version}" || "${version}" == "null" ]]; then \
        version="$(curl -fsSL https://api.github.com/repos/pgvector/pgvector/tags | jq -r '.[0].name')"; \
      fi; \
    fi; \
    git clone --depth 1 --branch "${version}" https://github.com/pgvector/pgvector.git /tmp/pgvector; \
    make -C /tmp/pgvector; \
    make -C /tmp/pgvector install; \
    rm -rf /tmp/pgvector
