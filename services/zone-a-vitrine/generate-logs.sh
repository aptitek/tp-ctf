#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/ecorp/access.log"
LEGIT_IPS=(
  "192.168.10.14"
  "192.168.10.22"
  "192.168.10.35"
  "192.168.10.48"
  "192.168.10.61"
)
LEGIT_PATHS=(
  "/index.html"
  "/assets/logo.svg"
  "/status"
  "/about"
  "/contact"
)
ATTACK_PATHS=(
  "/admin/login"
  "/api/v1/tokens"
  "/internal/export"
)

write_log_entries() {
  local idx=0
  local ip=""
  local path=""
  local sec=0

  : > "${LOG_FILE}"

  for ((idx = 1; idx <= 180; idx++)); do
    ip="${LEGIT_IPS[$((idx % ${#LEGIT_IPS[@]}))]}"
    path="${LEGIT_PATHS[$((idx % ${#LEGIT_PATHS[@]}))]}"
    sec=$((idx % 60))
    printf '%s - - [26/Nov/2026:09:%02d:%02d +0000] "GET %s HTTP/1.1" 200 1420\n' \
      "${ip}" "$((idx / 10))" "${sec}" "${path}" >> "${LOG_FILE}"
  done

  for ((idx = 1; idx <= 147; idx++)); do
    path="${ATTACK_PATHS[$((idx % ${#ATTACK_PATHS[@]}))]}"
    sec=$((idx % 60))
    local code="401"
    if (( idx % 3 == 0 )); then
      code="403"
    fi
    printf '10.66.42.199 - - [26/Nov/2026:10:%02d:%02d +0000] "POST %s HTTP/1.1" %s 312\n' \
      "$((idx / 10))" "${sec}" "${path}" "${code}" >> "${LOG_FILE}"
  done
}

write_clues() {
  cat > /var/log/ecorp/.incident_note <<'EOF'
[NOTE INTERNE - SOC E-CORP]
Une adresse IP inonde /admin/login et /api/v1/tokens de requêtes 401/403.
Commande utile :
  grep -E ' (401|403) ' /var/log/ecorp/access.log | awk '{print $1}' | sort | uniq -c | sort -nr

Une fois l'IP identifiée, ajoute-la dans /etc/ecorp/blocked_ips.list.
Vérifie aussi les permissions dans /var/www/ecorp/ et /opt/ecorp/bin/ !
EOF

  cat > /etc/ecorp/vitrine.conf <<'EOF'
# Configuration du frontal Zone A
DOC_ROOT=/var/www/ecorp
BLOCKLIST=/etc/ecorp/blocked_ips.list
WEB_GROUP=ecorp-web
HTTP_PORT=8080
EOF

  if [[ ! -f /etc/ecorp/blocked_ips.list ]]; then
    printf "# Ajoutez une adresse IP suspecte par ligne\n" > /etc/ecorp/blocked_ips.list
  fi
}

write_log_entries
write_clues
