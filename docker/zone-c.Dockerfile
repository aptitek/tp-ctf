# syntax=docker/dockerfile:1
FROM debian:12.9-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    busybox \
    coreutils \
    file \
    findutils \
    gawk \
    gnupg \
    grep \
    gzip \
    iproute2 \
    jq \
    less \
    micro \
    nano \
    openssh-server \
    openssl \
    procps \
    sed \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 operator \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash operator \
    && mkdir -p \
        /etc/ecorp \
        /var/log/ecorp \
        /var/lib/ecorp/ssh \
        /var/backups/ecorp \
        /var/backups/.cold_storage \
        /var/run/ecorp/web \
        /srv/vault/extracted \
        /srv/vault/keys \
        /opt/ecorp/.recovery \
    && chown -R operator:operator /etc/ecorp /var/log/ecorp /var/lib/ecorp /var/backups/ecorp /var/backups/.cold_storage /var/run/ecorp /srv/vault /opt/ecorp /home/operator

COPY --chmod=0755 services/zone-c-vault/setup-vault.sh /usr/local/bin/setup-vault.sh
COPY --chmod=0755 services/zone-c-vault/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY --chmod=0755 services/common/start-sshd.sh /usr/local/bin/start-sshd.sh
COPY --chmod=0755 services/common/beacon-loop.sh /usr/local/bin/beacon-loop.sh
COPY --chmod=0755 services/zone-c-vault/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/operator
USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
