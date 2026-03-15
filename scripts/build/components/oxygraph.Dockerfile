ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG OXYGRAPH_VERSION=latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Oxygraph: lightweight RDF graph database (arch-aware binary installation).
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) oxy_asset_arch="x86_64_linux_gnu" ;; \
      arm64) oxy_asset_arch="aarch64_linux_gnu" ;; \
      *) echo "[Oxygraph] Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    version="${OXYGRAPH_VERSION}"; \
    if [[ "${version}" == "latest" ]]; then \
      version="$(curl -fsSL https://api.github.com/repos/oxigraph/oxigraph/releases/latest | jq -r '.tag_name')"; \
    fi; \
    asset="oxigraph_${version}_${oxy_asset_arch}"; \
    url="https://github.com/oxigraph/oxigraph/releases/download/${version}/${asset}"; \
    install_dir="/opt/oxygraph"; \
    mkdir -p "${install_dir}"; \
    curl -fsSL "${url}" -o "${install_dir}/oxigraph"; \
    chmod +x "${install_dir}/oxigraph"; \
    ln -sf "${install_dir}/oxigraph" /usr/local/bin/oxigraph; \
    oxigraph --help >/dev/null; \
    echo "[Oxygraph] Installed: ${version} (${oxy_asset_arch})"

ENV DARTFX_INCLUDE_OXYGRAPH=true
