ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -fsSL https://ollama.com/install.sh | sh && \
    su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; \
      source "$NVM_DIR/nvm.sh"; \
      npm install -g @tcsenpai/ollama-code; \
      mkdir -p "$HOME/.config/ollama-code"; \
      printf "%s\n" "{" "  \"baseUrl\": \"http://localhost:11434/v1\"," "  \"model\": \"gpt-oss:20b\"" "}" >"$HOME/.config/ollama-code/config.json"'

COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV DARTFX_INCLUDE_OLLAMA=true
ENV OLLAMA_MODELS=/var/lib/ollama/models

RUN mkdir -p /var/lib/ollama/models && chown -R dartfx:dartfx /var/lib/ollama
