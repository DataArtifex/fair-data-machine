ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Node.js LTS via nvm, with pnpm as the default package manager.
RUN su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; \
  source "$NVM_DIR/nvm.sh"; \
  nvm install --lts; \
  nvm alias default lts/*; \
  npm install -g pnpm'
