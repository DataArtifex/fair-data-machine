ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ReadStat: converts and reads SPSS, Stata, and SAS formats; built from source.
# Depends on build-essential, automake, libtool, pkg-config, m4 (present in ubuntu-base).
RUN set -eux; \
    git clone --depth 1 https://github.com/WizardMac/ReadStat.git /tmp/ReadStat; \
    cd /tmp/ReadStat; \
    mkdir -p m4; \
    ./autogen.sh; \
    ./configure; \
    make -j"$(nproc)"; \
    make install; \
    ldconfig; \
    rm -rf /tmp/ReadStat
