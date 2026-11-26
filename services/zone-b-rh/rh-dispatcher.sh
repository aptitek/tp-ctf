#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/tmp/rh-dispatcher.pid"
DAEMON_BIN="/opt/ecorp/daemons/rh-dispatcher.py"

get_pid() {
  if [[ -f "${PID_FILE}" ]]; then
    cat "${PID_FILE}"
  fi
}

start_daemon() {
  if pgrep -f "${DAEMON_BIN}" >/dev/null 2>&1; then
    printf "[INFO] rh-dispatcher est déjà actif.\n"
    return 0
  fi
  python3 "${DAEMON_BIN}" >/dev/null 2>&1 &
  sleep 1
  printf "[OK] rh-dispatcher démarré.\n"
}

stop_daemon() {
  local pid=""
  pid="$(get_pid)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill -TERM "${pid}"
    sleep 1
    printf "[OK] rh-dispatcher arrêté (PID %s).\n" "${pid}"
  else
    pkill -TERM -f "${DAEMON_BIN}" 2>/dev/null || true
    printf "[INFO] rh-dispatcher arrêté.\n"
  fi
}

reload_daemon() {
  local pid=""
  pid="$(get_pid)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill -HUP "${pid}"
    printf "[OK] Signal SIGHUP envoyé à rh-dispatcher (PID %s).\n" "${pid}"
  else
    start_daemon
  fi
}

case "${1:-status}" in
  start)
    start_daemon
    ;;
  stop)
    stop_daemon
    ;;
  reload)
    reload_daemon
    ;;
  restart)
    stop_daemon
    start_daemon
    ;;
  status)
    if pgrep -af "${DAEMON_BIN}" >/dev/null 2>&1; then
      printf "[UP] rh-dispatcher actif (PID %s).\n" "$(get_pid)"
    else
      printf "[DOWN] rh-dispatcher arrêté.\n"
      exit 1
    fi
    ;;
  *)
    printf "Usage: %s {start|stop|reload|restart|status}\n" "${0}"
    exit 1
    ;;
esac
