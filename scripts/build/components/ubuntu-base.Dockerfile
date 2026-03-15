# Ubuntu base: OS packages, dartfx user, Supervisor, and workspace setup.
# This is always the first layer in the component chain; it always starts FROM ubuntu:latest.
FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Core OS packages: base utilities, build toolchain, supervisor.
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      curl wget git build-essential software-properties-common \
      apt-transport-https ca-certificates gnupg lsb-release \
      jq tmux tree unzip zstd net-tools htop ncdu fail2ban sudo \
      supervisor \
      bash-completion \
      make pkg-config m4 automake libtool && \
    rm -rf /var/lib/apt/lists/*

# Non-root operational user with passwordless sudo.
RUN useradd -m -s /bin/bash dartfx && \
    echo "dartfx:dartfx" | chpasswd && \
    usermod -aG sudo dartfx && \
    echo "dartfx ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/dartfx && \
    chmod 0440 /etc/sudoers.d/dartfx

COPY scripts/runtime /opt/dartfx/scripts/runtime
RUN find /opt/dartfx/scripts/runtime -type f -name "*.sh" -exec chmod +x {} +

# Default supervisor config (without Ollama; the ollama component overwrites this).
COPY supervisord.no-ollama.conf /etc/supervisor/supervisord.conf

RUN mkdir -p /var/log/supervisor /var/run

ENV PATH="/home/dartfx/.venvs/dartfx/bin:/home/dartfx/.local/bin:/usr/local/bin:${PATH}"

WORKDIR /workspace
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
