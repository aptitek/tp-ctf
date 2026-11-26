# syntax=docker/dockerfile:1
FROM debian:12.9-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    busybox \
    coreutils \
    curl \
    file \
    findutils \
    gawk \
    grep \
    iproute2 \
    jq \
    less \
    micro \
    nano \
    openssh-server \
    procps \
    sed \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 operator \
    && groupadd --gid 10002 ecorp-web \
    && useradd --uid 10001 --gid 10001 --groups ecorp-web --create-home --shell /bin/bash operator \
    && mkdir -p \
        /etc/ecorp \
        /var/log/ecorp \
        /var/lib/ecorp/ssh \
        /var/www/ecorp/config \
        /var/run/ecorp \
        /opt/ecorp/bin \
    && chown -R operator:operator /etc/ecorp /var/log/ecorp /var/lib/ecorp /var/www/ecorp /var/run/ecorp /opt/ecorp /home/operator

COPY --chown=operator:operator services/zone-a-vitrine/index.html /var/www/ecorp/index.html
COPY --chown=operator:operator services/zone-a-vitrine/api.conf /var/www/ecorp/config/api.conf
COPY --chown=operator:operator services/zone-a-vitrine/deploy-check.sh /opt/ecorp/bin/deploy-check.sh
COPY --chmod=0755 services/zone-a-vitrine/generate-logs.sh /usr/local/bin/generate-logs.sh
COPY --chmod=0755 services/zone-a-vitrine/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY --chmod=0755 services/common/start-sshd.sh /usr/local/bin/start-sshd.sh
COPY --chmod=0755 services/common/beacon-loop.sh /usr/local/bin/beacon-loop.sh
COPY --chmod=0755 services/zone-a-vitrine/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/operator
USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
