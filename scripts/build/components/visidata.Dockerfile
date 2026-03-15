ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# VisiData: terminal-first interactive tabular data exploration.
RUN apt-get update && \
    apt-get install -y --no-install-recommends visidata && \
    rm -rf /var/lib/apt/lists/*
