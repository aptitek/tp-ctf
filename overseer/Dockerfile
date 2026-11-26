# syntax=docker/dockerfile:1
FROM python:3.12.8-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    gnupg \
    iproute2 \
    libcap2-bin \
    && curl -fsSL https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg \
        -o /usr/share/keyrings/zerotier-archive-keyring.asc \
    && printf 'deb [signed-by=/usr/share/keyrings/zerotier-archive-keyring.asc] https://download.zerotier.com/debian/bookworm bookworm main\n' \
        > /etc/apt/sources.list.d/zerotier.list \
    && apt-get update && apt-get install -y --no-install-recommends zerotier-one \
    && setcap cap_net_admin,cap_net_raw+eip /usr/sbin/zerotier-one \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 overseer \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash overseer \
    && mkdir -p /app /var/lib/zerotier-one \
    && chown -R overseer:overseer /app /var/lib/zerotier-one /home/overseer

COPY --chown=overseer:overseer overseer/models.py /app/models.py
COPY --chown=overseer:overseer overseer/config.py /app/config.py
COPY --chown=overseer:overseer overseer/probes.py /app/probes.py
COPY --chown=overseer:overseer overseer/scorer.py /app/scorer.py
COPY --chown=overseer:overseer overseer/server.py /app/server.py
COPY --chown=overseer:overseer overseer/dashboard.html /app/dashboard.html
COPY --chown=overseer:overseer overseer/teams.yml /app/teams.yml
COPY --chmod=0755 overseer/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /app
USER overseer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
