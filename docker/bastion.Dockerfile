# syntax=docker/dockerfile:1
FROM debian:12.9-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bat \
    ca-certificates \
    coreutils \
    curl \
    dnsutils \
    exa \
    file \
    findutils \
    gawk \
    gnupg \
    grep \
    htop \
    iproute2 \
    iputils-ping \
    jq \
    less \
    micro \
    nano \
    netcat-openbsd \
    openssh-client \
    openssl \
    procps \
    sed \
    tar \
    tree \
    vim-tiny \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && ln -sf /usr/bin/exa /usr/local/bin/eza \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 operator \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash operator \
    && mkdir -p /run/ecorp-keys /home/operator/.ssh /home/operator/ops \
    && chown -R operator:operator /run/ecorp-keys /home/operator

COPY --chown=operator:operator docs/MISSION.md /home/operator/MISSION.md
COPY --chown=operator:operator services/bastion/bashrc /home/operator/.bashrc
COPY --chmod=0755 services/bastion/ecorp-radar.sh /usr/local/bin/ecorp-radar
COPY --chmod=0755 services/bastion/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/operator
USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
