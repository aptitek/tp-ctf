# OPÉRATION E-CORP — BRIEFING DE MISSION

```text
  ______      _____ ____  _____  _____
 |  ____|    / ____/ __ \|  __ \|  __ \
 | |__ _____| |   | |  | | |__) | |__) |
 |  __|_____| |   | |  | |  _  /|  ___/
 | |____    | |___| |__| | | \ \| |
 |______|    \_____\____/|_|  \_\_|
        [ TERMINUS OPS // FSOCIETY ]
```

Bienvenue, opérateur.

L'infrastructure interne d'E-Corp vient de subir une série d'incidents critiques.
Trois zones stratégiques sont hors de contrôle. Ton objectif : reprendre la main
uniquement via le terminal Linux, réparer chaque système et sécuriser la configuration.

## 1. Cartographie du réseau

Depuis ce bastion, les connexions SSH sont préconfigurées (aucun mot de passe requis) :

| Zone | Commande SSH | Rôle |
| :--- | :--- | :--- |
| **Zone A** | `ssh zone-a` | Serveur Web / Frontal (`zone-a-vitrine`) |
| **Zone B** | `ssh zone-b` | Serveur Interne RH (`zone-b-rh`) |
| **Zone C** | `ssh zone-c` | Coffre de Sauvegardes (`zone-c-vault`) |

Astuce : exécute `ecorp-radar` pour vérifier la joignabilité des zones depuis ce bastion.

## 2. Objectifs par Zone

### Zone A — `zone-a-vitrine` (Logs & Permissions POSIX)
1. **Analyse des logs** : Inspecte `/var/log/ecorp/access.log` (`grep`, `awk`, `sort`, `uniq -c`).
   Identifie l'adresse IP responsable du pic d'erreurs `401`/`403` et inscris-la dans
   `/etc/ecorp/blocked_ips.list`.
2. **Permissions POSIX** :
   - `/var/www/ecorp/index.html` est illisible : rétablis des droits de lecture (`0644` ou `0640`).
   - `/var/www/ecorp/config/api.conf` est ouvert à tous : restreins ses droits (`0640`)
     et attribue-le au groupe `ecorp-web` (`chown operator:ecorp-web`).
   - `/opt/ecorp/bin/deploy-check.sh` doit devenir exécutable (`chmod +x`).
3. **Indice caché** : explore `/var/log/ecorp/` avec `ls -la` et `/etc/ecorp/`.

### Zone B — `zone-b-rh` (Processus, Signaux & Zombies)
1. **Processus récalcitrant** : Un démon (`ecorp-sync-rogue.sh`) sature le CPU et ignore `SIGTERM`.
   Repère son PID (`ps aux`, `htop`), observe `/var/log/ecorp/rogue.log`, puis stoppe-le
   avec le bon signal (`kill -9`).
2. **Processus zombies** : Des processus `<defunct>` (`STAT = Z`) s'accumulent.
   - Trouve leur processus parent (`PPID`) avec `ps -eo pid,ppid,stat,comm`.
   - Corrige sa configuration dans `/etc/ecorp/rh-dispatcher.conf` (`REAP_CHILDREN=true`).
   - Recharge ou redémarre proprement le service via `/opt/ecorp/daemons/rh-dispatcher.sh reload`
     (ou `restart`).

### Zone C — `zone-c-vault` (Archives, Intégrité & Chiffrement)
1. **Intégrité d'archive** :
   - Extrais `/var/backups/ecorp/ledger-2026.tar.gz` dans `/srv/vault/extracted/`.
   - Vérifie les empreintes avec `sha256sum -c /var/backups/ecorp/SHA256SUMS`.
   - Un fichier a été altéré ! Consulte `/var/log/ecorp/vault-audit.log` pour trouver
     la copie saine cachée dans `/opt/ecorp/`, remplace le fichier corrompu et re-vérifie.
   - Reconstruis une archive propre : `/srv/vault/ledger-verified.tar.gz`.
   - Enregistre son empreinte SHA-256 dans `/srv/vault/ledger-verified.sha256`.
2. **Chiffrement & Clé** :
   - Sécurise la clé `/srv/vault/keys/vault.passphrase` en mode `0600`.
   - Chiffre l'archive avec OpenSSL (AES-256-CBC + PBKDF2) :
     `openssl enc -aes-256-cbc -pbkdf2 -salt -in /srv/vault/ledger-verified.tar.gz -out /srv/vault/ledger-verified.tar.gz.enc -pass file:/srv/vault/keys/vault.passphrase`

## 3. Validation
Depuis ta machine hôte (hors du bastion), exécute à tout moment :
```bash
mise run status
```
Bonne chance, opérateur. *Hello, friend.*
