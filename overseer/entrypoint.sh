#!/usr/bin/env bash
set -euo pipefail

ZT_NET_ID="${ZEROTIER_NETWORK_ID:-0000000000000000}"

zerotier-one -d /var/lib/zerotier-one >/dev/null 2>&1 &
sleep 2

node_id="$(zerotier-cli -D/var/lib/zerotier-one info 2>/dev/null | awk '{print $3}' || echo 'pending')"
printf "[OVERSEER] ZeroTier Node ID : %s\n" "${node_id}"

if [[ "${ZT_NET_ID}" != "0000000000000000" ]]; then
  zerotier-cli -D/var/lib/zerotier-one join "${ZT_NET_ID}" >/dev/null 2>&1 || true
  printf "[OVERSEER] Rejoint le réseau ZeroTier : %s\n" "${ZT_NET_ID}"
fi

exec python3 /app/server.py
