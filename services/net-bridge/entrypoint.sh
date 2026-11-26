#!/usr/bin/env bash
set -euo pipefail

TEAM_NAME="${TEAM_NAME:-fsociety-alpha}"
ZT_NET_ID="${ZEROTIER_NETWORK_ID:-0000000000000000}"
LOG_FILE="/var/log/ecorp/net-bridge.log"
INFO_FILE="/var/lib/ecorp/arena/node.json"
READY_FILE="/tmp/net-bridge.ready"

log_msg() {
  printf "[%s] [ARENA-BRIDGE] %s\n" "$(date '+%H:%M:%S')" "${1}" | tee -a "${LOG_FILE}"
}

resolve_host_ip() {
  local host="${1}"
  getent hosts "${host}" | awk '{print $1; exit}'
}

add_dnat_rule() {
  local ext_port="${1}"
  local target_host="${2}"
  local target_port="${3}"
  local target_ip=""

  target_ip="$(resolve_host_ip "${target_host}" || true)"
  if [[ -z "${target_ip}" ]]; then
    log_msg "Impossible de résoudre ${target_host} pour le port ${ext_port}"
    return 0
  fi

  iptables -t nat -C PREROUTING -p tcp --dport "${ext_port}" \
    -j DNAT --to-destination "${target_ip}:${target_port}" 2>/dev/null || \
  iptables -t nat -A PREROUTING -p tcp --dport "${ext_port}" \
    -j DNAT --to-destination "${target_ip}:${target_port}"

  iptables -C FORWARD -p tcp -d "${target_ip}" --dport "${target_port}" -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -p tcp -d "${target_ip}" --dport "${target_port}" -j ACCEPT
}

configure_nat() {
  log_msg "Configuration des règles NAT/DNAT vers le réseau interne ecorp-net..."
  add_dnat_rule 8080 zone-a-vitrine 8080
  add_dnat_rule 2201 zone-a-vitrine 2222
  add_dnat_rule 2202 zone-b-rh 2222
  add_dnat_rule 8082 zone-b-rh 8082
  add_dnat_rule 2203 zone-c-vault 2222
  add_dnat_rule 8083 zone-c-vault 8083

  iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -j MASQUERADE
}

start_zerotier() {
  zerotier-one -d /var/lib/zerotier-one >/dev/null 2>&1 &
  sleep 2

  local node_id="pending"
  node_id="$(zerotier-cli -D/var/lib/zerotier-one info 2>/dev/null | awk '{print $3}' || echo 'pending')"
  log_msg "ZeroTier Node ID : ${node_id} (équipe=${TEAM_NAME})"

  if [[ "${ZT_NET_ID}" != "0000000000000000" ]]; then
    zerotier-cli -D/var/lib/zerotier-one join "${ZT_NET_ID}" >> "${LOG_FILE}" 2>&1 || true
    log_msg "Demande de connexion au réseau ZeroTier ${ZT_NET_ID} envoyée."
  else
    log_msg "Mode local : définissez ZEROTIER_NETWORK_ID via 'mise run join -- <ZT_NET_ID> <TEAM_NAME>'."
  fi

  local zt_ip="en-attente-autorisation"
  zt_ip="$(ip -4 -o addr show 2>/dev/null | awk '$2 ~ /^zt/ {split($4, a, "/"); print a[1]; exit}' || true)"
  zt_ip="${zt_ip:-en-attente-autorisation}"

  jq -n \
    --arg team "${TEAM_NAME}" \
    --arg network_id "${ZT_NET_ID}" \
    --arg node_id "${node_id}" \
    --arg zt_ip "${zt_ip}" \
    '{team: $team, network_id: $network_id, node_id: $node_id, zt_ip: $zt_ip}' > "${INFO_FILE}"
}

mkdir -p /var/lib/ecorp/arena /var/log/ecorp
configure_nat
start_zerotier
touch "${READY_FILE}"

while true; do
  sleep 10
  zt_ip="$(ip -4 -o addr show 2>/dev/null | awk '$2 ~ /^zt/ {split($4, a, "/"); print a[1]; exit}' || true)"
  if [[ -n "${zt_ip}" && -f "${INFO_FILE}" ]]; then
    jq --arg zt_ip "${zt_ip}" '.zt_ip = $zt_ip' "${INFO_FILE}" > "${INFO_FILE}.tmp"
    mv -f "${INFO_FILE}.tmp" "${INFO_FILE}"
  fi
done
