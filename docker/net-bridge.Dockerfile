# syntax=docker/dockerfile:1
FROM debian:12.9-slim

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    dnsutils \
    gnupg \
    iproute2 \
    iptables \
    iputils-ping \
    jq \
    libcap2-bin \
    netcat-openbsd \
    procps \
    && curl -fsSL https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg \
        -o /usr/share/keyrings/zerotier-archive-keyring.asc \
    && printf 'deb [signed-by=/usr/share/keyrings/zerotier-archive-keyring.asc] https://download.zerotier.com/debian/bookworm bookworm main\n' \
        > /etc/apt/sources.list.d/zerotier.list \
    && apt-get update && apt-get install -y --no-install-recommends zerotier-one \
    && setcap cap_net_admin,cap_net_raw+eip /usr/sbin/zerotier-one \
    && setcap cap_net_admin,cap_net_raw+eip /usr/sbin/xtables-nft-multi \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 operator \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash operator \
    && mkdir -p /var/lib/ecorp/arena /var/log/ecorp /var/lib/zerotier-one \
    && chown -R operator:operator /var/lib/ecorp /var/log/ecorp /var/lib/zerotier-one /home/operator

COPY --chmod=0755 services/net-bridge/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/operator
USER operator

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
