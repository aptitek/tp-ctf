#!/usr/bin/env bash
set -euo pipefail

INIT_MARKER="/var/lib/ecorp/.zone-a-initialized"

initialize_faults() {
  /usr/local/bin/generate-logs.sh
  chmod 0000 /var/www/ecorp/index.html
  chmod 0777 /var/www/ecorp/config/api.conf
  chmod 0644 /opt/ecorp/bin/deploy-check.sh
  touch "${INIT_MARKER}"
}

if [[ ! -f "${INIT_MARKER}" ]]; then
  initialize_faults
fi

if ! pgrep -f "busybox httpd -f -p 8080" >/dev/null 2>&1; then
  busybox httpd -f -p 8080 -h /var/www/ecorp >/var/log/ecorp/httpd.log 2>&1 &
fi

if ! pgrep -f "beacon-loop.sh zone-a" >/dev/null 2>&1; then
  /usr/local/bin/beacon-loop.sh zone-a /var/www/ecorp/status >/dev/null 2>&1 &
fi

exec /usr/local/bin/start-sshd.sh "zone-a-vitrine"
