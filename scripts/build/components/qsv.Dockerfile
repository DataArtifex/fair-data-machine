ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG QSV_VERSION=latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# QSV: high-performance CSV toolkit (datHere repo on amd64, GitHub binary on arm64).
RUN set -eux; \
    version="${QSV_VERSION}"; \
    if [[ "${version}" == "latest" ]]; then \
      version="$(curl -fsSL https://api.github.com/repos/dathere/qsv/releases/latest | jq -r '.tag_name')"; \
    fi; \
    arch="$(dpkg --print-architecture)"; \
    if [[ "$arch" == "amd64" ]]; then \
      wget -O - https://dathere.github.io/qsv-deb-releases/qsv-deb.gpg | gpg --dearmor -o /usr/share/keyrings/qsv-deb.gpg; \
      echo "deb [signed-by=/usr/share/keyrings/qsv-deb.gpg] https://dathere.github.io/qsv-deb-releases ./" >/etc/apt/sources.list.d/qsv.list; \
      apt-get update; \
      apt-get install -y --no-install-recommends qsv; \
      rm -rf /var/lib/apt/lists/*; \
    elif [[ "$arch" == "arm64" ]]; then \
      curl -fsSL "https://github.com/dathere/qsv/releases/download/${version}/qsv-${version}-aarch64-unknown-linux-gnu.zip" -o /tmp/qsv.zip; \
      unzip /tmp/qsv.zip -d /tmp/qsv; \
      install -m 0755 /tmp/qsv/qsv /usr/local/bin/qsv; \
      rm -rf /tmp/qsv /tmp/qsv.zip; \
    else \
      echo "Unsupported architecture for qsv: ${arch}"; \
      exit 1; \
    fi
