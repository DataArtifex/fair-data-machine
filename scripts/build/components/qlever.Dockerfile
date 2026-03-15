ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# QLever: RDF/SPARQL-oriented query engine (native package on amd64, Python venv fallback on arm64).
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    install_dir="/opt/qlever"; \
    mkdir -p "${install_dir}"; \
    if [[ "${arch}" == "amd64" ]]; then \
      echo "[QLever] Installing native Ubuntu package..."; \
      apt-get update; \
      apt-get install -y --no-install-recommends wget gpg ca-certificates; \
      wget -qO - https://packages.qlever.dev/pub.asc | gpg --dearmor -o /usr/share/keyrings/qlever.gpg; \
      codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"; \
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/qlever.gpg] https://packages.qlever.dev/ ${codename} main" >/etc/apt/sources.list.d/qlever.list; \
      apt-get update; \
      apt-get install -y --no-install-recommends qlever; \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo "[QLever] amd64 package unavailable; installing via Python venv for ${arch}..."; \
      python3 -m venv "${install_dir}/venv"; \
      "${install_dir}/venv/bin/pip" install --no-cache-dir --upgrade pip; \
      "${install_dir}/venv/bin/pip" install --no-cache-dir qlever; \
      ln -sf "${install_dir}/venv/bin/qlever" /usr/local/bin/qlever; \
    fi; \
    qlever --help >/dev/null; \
    echo "[QLever] Installed: $(qlever --version 2>/dev/null || echo 'version command unavailable')"

ENV DARTFX_INCLUDE_QLEVER=true
