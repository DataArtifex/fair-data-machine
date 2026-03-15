ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Gemini CLI: Google AI coding assistant (npm global package; requires Node.js in base).
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; \
  source "$NVM_DIR/nvm.sh"; \
  npm install -g @google/gemini-cli; \
  mkdir -p "$HOME/.gemini"'
