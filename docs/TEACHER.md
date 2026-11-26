# Guide Formateur — Opération E-Corp (`TEACHER.md`)

Ce document est destiné à l'équipe pédagogique (animateurs / enseignants de 1re année informatique). Il présente l'architecture, le déroulé type d'une séance de 2h à 3h, les solutions complètes par zone et l'activation du mode multijoueur **Arène (King of the Hill)**.

---

## 1. Objectifs Pédagogiques

| Zone | Compétences Linux pratiquées | Commandes clés |
| :--- | :--- | :--- |
| **Bastion** | Navigation, lecture de fichiers, SSH sans friction | `ls -la`, `cd`, `cat`/`bat`, `ssh`, `nc` |
| **Zone A** | Analyse de journaux, pipes, permissions POSIX, groupes | `grep`, `awk`, `sort`, `uniq -c`, `chmod`, `chown`, `stat` |
| **Zone B** | Arbre des processus, CPU, signaux, zombies, services | `ps aux`, `ps -eo pid,ppid,stat,comm`, `htop`, `kill -9`, `kill -HUP` |
| **Zone C** | Archives compressées, intégrité cryptographique, chiffrement | `tar`, `sha256sum -c`, `find`, `chmod 600`, `openssl enc` |

---

## 2. Sécurité & Isolation de l'Infrastructure

- **Aucun conteneur `privileged`** et **aucun montage de `/var/run/docker.sock`**.
- Tous les conteneurs s'exécutent sous un utilisateur non-root (`operator`, UID `10001`) avec `no-new-privileges:true` et un `init: true` (`tini`).
- Le réseau `ecorp-net` est configuré avec `internal: true` (isolé d'Internet).
- Les clés SSH sont générées de manière éphémère au démarrage dans un volume Docker (`ecorp-ssh-keys`) : aucun secret n'est présent dans le dépôt Git.
- `zone-b-rh` dispose de limites strictes (`cpus: "0.50"`, `memory: 128M`) : le démon parasite est borné et ne peut pas ralentir le poste de l'étudiant.
- Seul le service optionnel `net-bridge` (profil `arena`, désactivé par défaut) ajoute la capacité `NET_ADMIN` et `/dev/net/tun` pour l'interconnexion virtuelle.

---

## 3. Déroulé Recommandé d'une Séance (2h30)

1. **Lancement & Immersion (15 min)** :
   - Les étudiants clonent le dépôt et lancent `mise install && mise run start && mise run enter`.
   - Lecture collective de `mission` et test de `ecorp-radar`.
2. **Phase 1 — Mode Solo / Binôme (1h30)** :
   - Les étudiants résolvent les Zones A, B et C à leur rythme.
   - Ils suivent leur progression en temps réel avec `mise run status` depuis leur machine hôte.
   - En cas d'erreur irréversible (fichier supprimé, mauvaise commande), un simple `mise run reset` restaure l'état initial en quelques secondes.
3. **Phase 2 — Débriefing ou Mode Arène (45 min)** :
   - Revue des commandes élégantes (pipes, `ps -eo`, pourquoi `kill -9` ne tue pas un zombie, différence intégrité vs confidentialité).
   - Optionnel : activation du profil `arena` (voir section 5).

---

## 4. Corrigés Complets par Zone

### Zone A — `ssh zone-a` (`zone-a-vitrine`)

```bash
# 1. Repérer l'IP malveillante (10.66.42.199)
grep -E ' (401|403) ' /var/log/ecorp/access.log | awk '{print $1}' | sort | uniq -c | sort -nr

# 2. Ajouter l'IP à la blocklist
echo "10.66.42.199" >> /etc/ecorp/blocked_ips.list

# 3. Corriger les permissions POSIX et le groupe
chmod 0644 /var/www/ecorp/index.html
chmod 0640 /var/www/ecorp/config/api.conf
chown operator:ecorp-web /var/www/ecorp/config/api.conf
chmod +x /opt/ecorp/bin/deploy-check.sh
```

### Zone B — `ssh zone-b` (`zone-b-rh`)

```bash
# 1. Repérer et tuer le démon récalcitrant (ignore SIGTERM)
pgrep -af ecorp-sync-rogue
pkill -9 -f ecorp-sync-rogue.sh

# 2. Observer les zombies et remonter au parent (rh-dispatcher.py)
ps -eo pid,ppid,stat,comm | grep -E 'Z|rh-dispatcher'

# 3. Corriger la configuration
sed -i 's/REAP_CHILDREN=false/REAP_CHILDREN=true/' /etc/ecorp/rh-dispatcher.conf

# 4. Recharger le service (SIGHUP) ou le redémarrer
/opt/ecorp/daemons/rh-dispatcher.sh reload
```

### Zone C — `ssh zone-c` (`zone-c-vault`)

```bash
# 1. Extraire l'archive et vérifier l'intégrité
tar -xzf /var/backups/ecorp/ledger-2026.tar.gz -C /srv/vault/extracted/
cd /srv/vault/extracted && sha256sum -c /var/backups/ecorp/SHA256SUMS

# 2. Remplacer audit_q3.txt par la copie saine cachée et re-vérifier
cp /opt/ecorp/.recovery/audit_q3.txt /srv/vault/extracted/audit_q3.txt
sha256sum -c /var/backups/ecorp/SHA256SUMS

# 3. Reconstruire l'archive vérifiée et enregistrer son empreinte
tar -czf /srv/vault/ledger-verified.tar.gz -C /srv/vault/extracted \
  audit_q1.txt audit_q2.txt audit_q3.txt audit_q4.txt
sha256sum /srv/vault/ledger-verified.tar.gz > /srv/vault/ledger-verified.sha256

# 4. Sécuriser la clé et chiffrer l'archive
chmod 0600 /srv/vault/keys/vault.passphrase
openssl enc -aes-256-cbc -pbkdf2 -salt \
  -in /srv/vault/ledger-verified.tar.gz \
  -out /srv/vault/ledger-verified.tar.gz.enc \
  -pass file:/srv/vault/keys/vault.passphrase
```

---

## 5. Animer le Mode Arène (« King of the Hill »)

Le profil Compose `arena` active le conteneur `net-bridge` :

1. Créez un réseau virtuel ZeroTier pour la classe et notez son identifiant (16 caractères hexadécimaux).
2. Chaque équipe copie `.env.example` vers `.env` et renseigne `TEAM_NAME` et `ZEROTIER_NETWORK_ID`.
3. Lancement :
   ```bash
   mise run arena
   ```
4. Les équipes qui contrôlent une zone (`3/3` sur `mise run status`) peuvent inscrire leur nom d'équipe dans `/var/lib/ecorp/team.flag` et défendre la configuration pendant la manche chronométrée.

---

## 6. Dépannage Rapide

- **Un étudiant a cassé un fichier système** : exécuter `mise run reset` (repart d'un état propre en ~5s).
- **Erreur SSH `Connection refused`** : attendre 3 secondes après `mise run start` que `bastion` génère la clé partagée et que les zones démarrent `sshd`.
- **Vérifier les logs d'un conteneur** : `docker compose logs zone-b-rh`.
