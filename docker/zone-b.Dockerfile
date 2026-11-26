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
    grep \
    htop \
    iproute2 \
    jq \
    less \
    micro \
    nano \
    openssh-server \
    procps \
    psmisc \
    python3-minimal \
    sed \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 operator \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash operator \
    && mkdir -p \
        /etc/ecorp \
        /var/log/ecorp \
        /var/lib/ecorp/ssh \
        /var/run/ecorp/web \
        /opt/ecorp/daemons \
    && chown -R operator:operator /etc/ecorp /var/log/ecorp /var/lib/ecorp /var/run/ecorp /opt/ecorp /home/operator

COPY --chown=operator:operator services/zone-b-rh/rh-dispatcher.conf /etc/ecorp/rh-dispatcher.conf
COPY --chmod=0755 --chown=operator:operator services/zone-b-rh/rh-dispatcher.py /opt/ecorp/daemons/rh-dispatcher.py
COPY --chmod=0755 --chown=operator:operator services/zone-b-rh/rh-dispatcher.sh /opt/ecorp/daemons/rh-dispatcher.sh
COPY --chmod=0755 --chown=operator:operator services/zone-b-rh/rogue-daemon.sh /opt/ecorp/daemons/ecorp-sync-rogue.sh
COPY --chmod=0755 services/zone-b-rh/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY --chmod=0755 services/common/start-sshd.sh /usr/local/bin/start-sshd.sh
COPY --chmod=0755 services/common/beacon-loop.sh /usr/local/bin/beacon-loop.sh
COPY --chmod=0755 services/zone-b-rh/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/operator
USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
