# syntax=docker/dockerfile:1
ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends r-base r-base-dev && \
    rm -rf /var/lib/apt/lists/*

COPY r-packages.txt /opt/dartfx/r-packages.txt
ENV DARTFX_INCLUDE_R=true

RUN <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

MANIFEST_PATH="/opt/dartfx/r-packages.txt"
CRAN_MIRROR="https://cloud.r-project.org"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "[r] Manifest not found: $MANIFEST_PATH"
  exit 1
fi

mapfile -t packages < <(sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$MANIFEST_PATH" | awk 'NF')

if (( ${#packages[@]} == 0 )); then
  echo "[r] No supplemental packages listed in ${MANIFEST_PATH}"
  exit 0
fi

Rscript - "${CRAN_MIRROR}" "${packages[@]}" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
repos <- args[1]
packages <- unique(args[-1])
installed <- rownames(installed.packages())
to_install <- packages[!packages %in% installed]

if (length(to_install) == 0) {
  cat(sprintf("[r] All %d supplemental package(s) already installed\n", length(packages)))
  quit(save = "no", status = 0)
}

ncpus <- max(1L, parallel::detectCores(logical = TRUE) - 1L)
install.packages(to_install, repos = repos, Ncpus = ncpus)
cat(sprintf("[r] Installed %d supplemental package(s): %s\n", length(to_install), paste(to_install, collapse = ", ")))
RS
SCRIPT
