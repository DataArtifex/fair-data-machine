# Optimized FAIR Data Machine Build
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Suppress service starts during build
RUN printf '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# System Dependencies
RUN apt-get update && \
    apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    --no-install-recommends --no-install-suggests \
      apt-transport-https \
      automake \
      bash-completion \
      build-essential \
      ca-certificates \
      curl \
      git \
      gnupg \
      htop \
      jq \
      libtool \
      lsb-release \
      m4 \
      make \
      ncdu \
      net-tools \
      pkg-config \
      postgresql \
      postgresql-client \
      postgresql-contrib \
      postgresql-server-dev-all \
      python3 \
      python3-dev \
      python3-venv \
      r-base \
      r-base-dev \
      software-properties-common \
      sudo \
      supervisor \
      tmux \
      tree \
      unzip \
      visidata \
      wget \
      zstd \
    && rm -rf /var/lib/apt/lists/* /usr/sbin/policy-rc.d

# Process Manager Configuration
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Environment Variables
ENV DARTFX_INCLUDE_PYTHON="true"
ENV DARTFX_INCLUDE_VISIDATA="true"
ENV DARTFX_INCLUDE_OXYGRAPH="true"
ENV DARTFX_INCLUDE_READSTAT="true"
ENV DARTFX_INCLUDE_NODE="true"
ENV DARTFX_INCLUDE_GEMINI="true"
ENV DARTFX_INCLUDE_CLAUDE="true"
ENV DARTFX_INCLUDE_POSTGRES="true"
ENV DARTFX_INCLUDE_QLEVER="true"
ENV DARTFX_INCLUDE_DUCKDB="true"
ENV DARTFX_INCLUDE_QSV="true"
ENV DARTFX_INCLUDE_R="true"

# Component: ubuntu-base
RUN useradd -m -s /bin/bash dartfx
RUN echo "dartfx:dartfx" | chpasswd
RUN usermod -aG sudo dartfx
RUN echo "dartfx ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/dartfx
RUN chmod 0440 /etc/sudoers.d/dartfx
RUN mkdir -p /var/log/supervisor /var/run /opt/dartfx /home/dartfx/workspace
RUN chown dartfx:dartfx /opt/dartfx /home/dartfx/workspace

# Component: python
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
# Python: Install packages into venv
COPY pyproject.toml /opt/dartfx/pyproject.toml
RUN mkdir -p /home/dartfx/.venvs && chown dartfx:dartfx /home/dartfx/.venvs
RUN su - dartfx -c '/usr/local/bin/uv venv /home/dartfx/.venvs/dartfx'
RUN su - dartfx -c '/usr/local/bin/uv pip install -r /opt/dartfx/pyproject.toml --python /home/dartfx/.venvs/dartfx/bin/python'

# Component: oxygraph
RUN arch=$(dpkg --print-architecture); case "$arch" in amd64) oxy_asset_arch="x86_64_linux_gnu" ;; arm64) oxy_asset_arch="aarch64_linux_gnu" ;; *) exit 1 ;; esac; version=$(curl -fsSL https://api.github.com/repos/oxigraph/oxigraph/releases/latest | jq -r '.tag_name'); asset="oxigraph_${version}_${oxy_asset_arch}"; url="https://github.com/oxigraph/oxigraph/releases/download/${version}/${asset}"; mkdir -p /opt/oxygraph; curl -fsSL "${url}" -o /opt/oxygraph/oxigraph; chmod +x /opt/oxygraph/oxigraph; ln -sf /opt/oxygraph/oxigraph /usr/local/bin/oxigraph

# Component: readstat
RUN git clone --depth 1 https://github.com/WizardMac/ReadStat.git /tmp/ReadStat; cd /tmp/ReadStat; mkdir -p m4; ./autogen.sh; ./configure; make -j$(nproc); make install; ldconfig; rm -rf /tmp/ReadStat

# Component: node
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; source "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default lts/*; npm install -g pnpm; pnpm setup'

# Component: gemini
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; export PNPM_HOME="$HOME/.local/share/pnpm"; export PATH="$PNPM_HOME:$PATH"; pnpm add -g @google/gemini-cli; mkdir -p "$HOME/.gemini"'

# Component: claude
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; export PNPM_HOME="$HOME/.local/share/pnpm"; export PATH="$PNPM_HOME:$PATH"; pnpm add -g @anthropic-ai/claude-code'

# Component: postgres
RUN git clone --depth 1 https://github.com/pgvector/pgvector.git /tmp/pgvector
RUN make -C /tmp/pgvector
RUN make -C /tmp/pgvector install
RUN rm -rf /tmp/pgvector

# Component: qlever
RUN arch=$(dpkg --print-architecture); if [[ "$arch" == "amd64" ]]; then wget -qO - https://packages.qlever.dev/pub.asc | gpg --dearmor -o /usr/share/keyrings/qlever.gpg; codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}"); echo "deb [arch=amd64 signed-by=/usr/share/keyrings/qlever.gpg] https://packages.qlever.dev/ ${codename} main" >/etc/apt/sources.list.d/qlever.list; apt-get update; apt-get install -y --no-install-recommends qlever; else python3 -m venv /opt/qlever/venv; /opt/qlever/venv/bin/pip install --no-cache-dir qlever; ln -sf /opt/qlever/venv/bin/qlever /usr/local/bin/qlever; fi

# Component: duckdb
RUN arch=$(dpkg --print-architecture); case "$arch" in amd64) duck_arch="linux-amd64" ;; arm64) duck_arch="linux-arm64" ;; *) exit 1 ;; esac; version=$(curl -fsSL https://api.github.com/repos/duckdb/duckdb/releases/latest | jq -r '.tag_name'); curl -fsSL "https://github.com/duckdb/duckdb/releases/download/${version}/duckdb_cli-${duck_arch}.zip" -o /tmp/duckdb.zip; unzip /tmp/duckdb.zip -d /usr/local/bin; chmod +x /usr/local/bin/duckdb; rm -f /tmp/duckdb.zip

# Component: qsv
RUN arch=$(dpkg --print-architecture); if [[ "$arch" == "amd64" ]]; then wget -O - https://dathere.github.io/qsv-deb-releases/qsv-deb.gpg | gpg --dearmor -o /usr/share/keyrings/qsv-deb.gpg; echo "deb [signed-by=/usr/share/keyrings/qsv-deb.gpg] https://dathere.github.io/qsv-deb-releases ./" >/etc/apt/sources.list.d/qsv.list; apt-get update; apt-get install -y --no-install-recommends qsv; elif [[ "$arch" == "arm64" ]]; then version=$(curl -fsSL https://api.github.com/repos/dathere/qsv/releases/latest | jq -r '.tag_name'); curl -fsSL "https://github.com/dathere/qsv/releases/download/${version}/qsv-${version}-aarch64-unknown-linux-gnu.zip" -o /tmp/qsv.zip; unzip /tmp/qsv.zip -d /tmp/qsv; install -m 0755 /tmp/qsv/qsv /usr/local/bin/qsv; rm -rf /tmp/qsv /tmp/qsv.zip; fi

WORKDIR /home/dartfx/workspace
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]