#!/usr/bin/env bash
set -euo pipefail

INIT_MARKER="/var/lib/ecorp/.zone-c-initialized"

if [[ ! -f "${INIT_MARKER}" ]]; then
  /usr/local/bin/setup-vault.sh
  touch "${INIT_MARKER}"
fi

if ! pgrep -f "beacon-loop.sh zone-c" >/dev/null 2>&1; then
  /usr/local/bin/beacon-loop.sh zone-c /var/run/ecorp/web/status >/dev/null 2>&1 &
fi

if ! pgrep -f "busybox httpd -f -p 8083" >/dev/null 2>&1; then
  busybox httpd -f -p 8083 -h /var/run/ecorp/web >/dev/null 2>&1 &
fi

exec /usr/local/bin/start-sshd.sh "zone-c-vault"
