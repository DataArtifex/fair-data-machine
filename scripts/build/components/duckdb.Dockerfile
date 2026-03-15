ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DUCKDB_VERSION=latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DuckDB CLI: embedded analytical SQL engine (arch-aware binary installation).
RUN set -eux; \
    version="${DUCKDB_VERSION}"; \
    if [[ "${version}" == "latest" ]]; then \
      version="$(curl -fsSL https://api.github.com/repos/duckdb/duckdb/releases/latest | jq -r '.tag_name')"; \
    fi; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) duck_arch="linux-amd64" ;; \
      arm64) duck_arch="linux-arm64" ;; \
      *) echo "Unsupported architecture for DuckDB: ${arch}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/duckdb/duckdb/releases/download/${version}/duckdb_cli-${duck_arch}.zip" -o /tmp/duckdb.zip; \
    unzip /tmp/duckdb.zip -d /usr/local/bin; \
    chmod +x /usr/local/bin/duckdb; \
    rm -f /tmp/duckdb.zip
