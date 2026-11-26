#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/ecorp/rogue.log"

log_ignored() {
  local sig="${1}"
  printf "[%s] [ROGUE PID %d] Signal %s intercepté et IGNORÉ ! Seul SIGKILL peut m'arrêter.\n" \
    "$(date '+%H:%M:%S')" "$$" "${sig}" >> "${LOG_FILE}"
}

trap 'log_ignored SIGTERM' TERM
trap 'log_ignored SIGINT' INT
trap 'log_ignored SIGHUP' HUP

printf "[%s] [ROGUE PID %d] Démon parasite démarré — saturation CPU contrôlée.\n" \
  "$(date '+%H:%M:%S')" "$$" >> "${LOG_FILE}"

while true; do
  dd if=/dev/zero bs=64k count=32 2>/dev/null | sha256sum >/dev/null
  sleep 0.15
done
