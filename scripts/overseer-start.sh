#!/usr/bin/env bash
set -euo pipefail

ZT_NET_ID="${1:-0000000000000000}"

if [[ "${ZT_NET_ID}" != "0000000000000000" && ! "${ZT_NET_ID}" =~ ^[0-9a-fA-F]{16}$ ]]; then
  printf "[ERREUR] ZT_NETWORK_ID doit contenir 16 caractères hexadécimaux.\n"
  exit 1
fi

cat > .env <<EOF
COMPOSE_PROJECT_NAME=ecorp-ops
TEAM_NAME=overseer
ZEROTIER_NETWORK_ID=${ZT_NET_ID}
EOF

printf "\n[OVERSEER] Construction et lancement du Scorebot & Dashboard...\n"
docker compose -f overseer/compose.overseer.yml up -d --build
sleep 3

node_id="$(docker compose -f overseer/compose.overseer.yml exec -T overseer \
  zerotier-cli -D/var/lib/zerotier-one info 2>/dev/null | awk '{print $3}' || echo 'en-cours')"

printf "\n============================================================\n"
printf "   E-CORP OVERSEER — TABLEAU DE BORD FORMATEUR\n"
printf "============================================================\n"
printf "  Dashboard Web : http://localhost:9000\n"
printf "  Réseau ZT     : %s\n" "${ZT_NET_ID}"
printf "  ZT Node ID    : %s   (à autoriser sur my.zerotier.com)\n" "${node_id}"
printf "  Fichier teams : overseer/teams.yml\n"
printf "============================================================\n\n"
