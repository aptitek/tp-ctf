#!/usr/bin/env bash
set -euo pipefail

printf "\n[E-CORP] Réinitialisation complète de l'infrastructure...\n"
docker compose --profile arena down -v --remove-orphans

printf "[E-CORP] Reconstruction et redémarrage des services...\n"
docker compose up -d --build

printf "[E-CORP] Attente de l'initialisation des zones...\n"
sleep 3

bash scripts/status.sh
