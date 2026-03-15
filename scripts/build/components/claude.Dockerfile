ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Claude CLI: Anthropic AI coding assistant (npm global package; requires Node.js in base).
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; \
  source "$NVM_DIR/nvm.sh"; \
  npm install -g @anthropic-ai/claude-code'
