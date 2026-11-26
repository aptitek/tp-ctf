#!/usr/bin/env bash
set -euo pipefail

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

print_header() {
  printf "\n${CYAN}============================================================${RESET}\n"
  printf "${CYAN}   OPÉRATION E-CORP — TABLEAU DE CONTRÔLE DES ZONES${RESET}\n"
  printf "${CYAN}============================================================${RESET}\n"
}

check_container_running() {
  local service="${1}"
  local cid=""
  cid="$(docker compose ps -q "${service}" 2>/dev/null || true)"
  [[ -n "${cid}" ]]
}

print_zone_status() {
  local service="${1}"
  local label="${2}"

  if ! check_container_running "${service}"; then
    printf "  %-18s ${RED}[OFFLINE]${RESET}      Conteneur non démarré\n" "${label}"
    return 1
  fi

  local report=""
  local rc=0
  report="$(docker compose exec -T "${service}" /usr/local/bin/healthcheck.sh --report 2>/dev/null)" || rc=$?

  local score="${report%%|*}"
  local details="${report#*|}"

  if [[ "${rc}" -eq 0 ]]; then
    printf "  %-18s ${GREEN}[CONTRÔLÉE %s]${RESET} %s\n" "${label}" "${score}" "${details}"
    return 0
  fi

  if [[ "${score}" == 0/* || -z "${score}" ]]; then
    printf "  %-18s ${RED}[COMPROMISE %s]${RESET} %s\n" "${label}" "${score:-0/?}" "${details}"
  else
    printf "  %-18s ${YELLOW}[EN COURS   %s]${RESET} %s\n" "${label}" "${score}" "${details}"
  fi
  return 1
}

main() {
  local secured=0

  print_header

  if check_container_running "bastion"; then
    printf "  %-18s ${GREEN}[PRÊT]${RESET}         Accès via : mise run enter\n" "Bastion"
  else
    printf "  %-18s ${RED}[OFFLINE]${RESET}      Démarrez avec : mise run start\n" "Bastion"
  fi

  printf "${CYAN}------------------------------------------------------------${RESET}\n"

  if print_zone_status "zone-a-vitrine" "Zone A (Vitrine)"; then
    secured=$((secured + 1))
  fi
  if print_zone_status "zone-b-rh" "Zone B (RH)"; then
    secured=$((secured + 1))
  fi
  if print_zone_status "zone-c-vault" "Zone C (Coffre)"; then
    secured=$((secured + 1))
  fi

  if check_container_running "net-bridge"; then
    printf "${CYAN}------------------------------------------------------------${RESET}\n"
    printf "  %-18s ${GREEN}[ARÈNE ACTIVE]${RESET} Pont réseau multijoueur démarré\n" "Net-Bridge"
  fi

  printf "${CYAN}============================================================${RESET}\n"
  printf "  Score global : %d / 3 zones sous contrôle.\n\n" "${secured}"
}

main
