#!/usr/bin/env bash
set -euo pipefail

ROGUE_MARKER="/var/lib/ecorp/.zone-b-rogue-spawned"

write_diag_hint() {
  cat > /var/log/ecorp/.rh_diag_hint <<'EOF'
[DIAGNOSTIC ZONE B — SERVEUR RH]
1. Utilise 'ps aux' ou 'htop' pour repérer le processus qui consomme du CPU.
   Consulte /var/log/ecorp/rogue.log si 'kill <PID>' ne suffit pas.
2. Utilise 'ps -eo pid,ppid,stat,comm' pour repérer les zombies (STAT = Z)
   et remonter à leur parent (PPID).
3. Édite /etc/ecorp/rh-dispatcher.conf puis recharge le service :
   /opt/ecorp/daemons/rh-dispatcher.sh reload
EOF
}

write_diag_hint

if [[ ! -f "${ROGUE_MARKER}" ]]; then
  /opt/ecorp/daemons/ecorp-sync-rogue.sh >/dev/null 2>&1 &
  touch "${ROGUE_MARKER}"
fi

/opt/ecorp/daemons/rh-dispatcher.sh start >/dev/null 2>&1

if ! pgrep -f "beacon-loop.sh zone-b" >/dev/null 2>&1; then
  /usr/local/bin/beacon-loop.sh zone-b /var/run/ecorp/web/status >/dev/null 2>&1 &
fi

if ! pgrep -f "busybox httpd -f -p 8082" >/dev/null 2>&1; then
  busybox httpd -f -p 8082 -h /var/run/ecorp/web >/dev/null 2>&1 &
fi

exec /usr/local/bin/start-sshd.sh "zone-b-rh"
