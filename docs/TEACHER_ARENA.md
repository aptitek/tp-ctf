# Guide Formateur — Phase 2 : Arène Multijoueur ZeroTier (`TEACHER_ARENA.md`)

Ce guide détaille la mise en place et l'animation d'une séance compétitive **« King of the Hill / Domination : Zones A, B, C »** de 2h à 4h via **ZeroTier** conteneurisé (zéro installation sur les postes étudiants en dehors de `git`, `docker` et `mise`).

---

## 1. Architecture Réseau ZeroTier Conteneurisée

Chaque équipe dispose d'une **seule IP ZeroTier** portée par son conteneur `net-bridge` (profil `arena`). Le conteneur `net-bridge` active le routage (`net.ipv4.ip_forward=1`) et expose les zones internes via NAT/DNAT :

| Port exposé sur l'IP ZeroTier | Cible interne (`ecorp-net`) | Usage |
| :--- | :--- | :--- |
| `8080` | `zone-a-vitrine:8080` | HTTP Vitrine + endpoint `/status` |
| `2201` | `zone-a-vitrine:2222` | SSH Zone A |
| `2202` | `zone-b-rh:2222` | SSH Zone B |
| `8082` | `zone-b-rh:8082` | Balise télémétrie Zone B (Scorebot) |
| `2203` | `zone-c-vault:2222` | SSH Zone C |
| `8083` | `zone-c-vault:8083` | Balise télémétrie Zone C (Scorebot) |

Aucun routage complexe de sous-réseau n'est requis dans ZeroTier Central. L'identité ZeroTier est persistée dans le volume Docker `zt-identity`.

---

## 2. Préparation en 2 Minutes (`my.zerotier.com`)

1. Connectez-vous sur [my.zerotier.com](https://my.zerotier.com) et cliquez sur **Create A Network**.
2. Notez le **Network ID** à 16 caractères hexadécimaux (ex. `8056c2e21c000001`).
3. Vérifiez que le réseau est en mode **Private** (autorisation manuelle des nœuds) avec un plan d'adressage IPv4 automatique (ex. `10.147.20.0/24`).

---

## 3. Lancement de la Séance (Pas-à-Pas)

### Étape A — Démarrer l'Arbitre (`E-Corp Overseer`) sur le PC Formateur

```bash
mise run overseer -- <ZT_NETWORK_ID>
```

1. Autorisez le **Node ID** de l'Overseer dans ZeroTier Central.
2. Projetez le Dashboard temps réel au tableau : `http://localhost:9000`.

### Étape B — Connexion des Équipes Étudiantes

Chaque équipe (2 à 3 étudiants par instance) exécute :

```bash
mise run join -- <ZT_NETWORK_ID> <TEAM_ID>
```

1. La commande affiche clairement le **Node ID** ZeroTier de l'équipe.
2. Le formateur coche **Auth** pour chaque équipe sur `my.zerotier.com` et note l'IP ZeroTier attribuée.
3. Le formateur met à jour [overseer/teams.yml](../overseer/teams.yml) avec les `id`, `name` et `ip` des équipes (le Scorebot recharge le fichier à chaque tick de 15 secondes sans redémarrage !).

### Étape C — Vérification avant Top Départ

Les étudiants vérifient leur statut et leurs cibles avec :

```bash
mise run radar
```

---

## 4. Règles de Scoring & Anti-Triche (Tick toutes les 15s)

| Événement | Points | Condition |
| :--- | :--- | :--- |
| **SLA Respecté** | **+2 pts** / zone | Service UP + SSH joignable (`2201`/`2202`/`2203`) |
| **Contrôle de Zone** | **+3 pts** / zone | `TEAM_ID` présent dans `/var/run/ecorp/owner.token` d'une zone **UP** |
| **Coup d'Éclat Vault** | **+4 pts** | Zone C adverse chiffrée avec marqueur `/srv/vault/.locked_by_<TEAM_ID>` |
| **Restauration d'Urgence** | **-2 pts** / tick | Marqueur `/var/lib/ecorp/.emergency_restore.log` posé par `mise run emergency-restore` |

### Garde-fous Anti-Triche
- **Couper SSH ou le réseau ne paie pas** : si le Scorebot ne peut joindre le port SSH (`2201`/`2202`/`2203`) ou l'endpoint `/status`, la zone passe instantanément en statut `DOWN` (`0` point de SLA et `0` point de contrôle).
- **Protection des laptops étudiants** : chaque conteneur est borné par `pids_limit: 150` et des limites strictes `cpus`/`memory` empêchant toute fork-bomb accidentelle.

---

## 5. Scénarios Attaque / Défense par Zone

### Zone A — Vitrine (`8080` / SSH `2201`)
- **Défense** : corriger les permissions, bloquer les IP malveillantes, surveiller `/var/run/ecorp/owner.token` et maintenir HTTP 200 sur `/index.html`.
- **Attaque** : exploiter des droits faibles ou des clés mal protégées pour remplacer `/var/run/ecorp/owner.token` sans casser le serveur web.

### Zone B — Serveur RH (`8082` / SSH `2202`)
- **Défense** : surveiller `ps -eo pid,ppid,stat,comm`, éliminer tout processus récalcitrant avec `kill -9`, recharger `rh-dispatcher` avec `SIGHUP` si la conf est altérée.
- **Attaque** : remettre `REAP_CHILDREN=false` ou relancer `/opt/ecorp/daemons/ecorp-sync-rogue.sh` pour faire basculer la zone adverse en `ZOMBIE OVERLOAD`.

### Zone C — Vault (`8083` / SSH `2203`)
- **Défense** : protéger `/srv/vault/keys/vault.passphrase` (`chmod 0600`), vérifier l'intégrité (`sha256sum -c`). Si un adversaire chiffre le coffre, restaurer depuis l'archive froide cachée `/var/backups/.cold_storage/ledger-cold.tar.gz`, supprimer `/srv/vault/.locked_by_*` et durcir les permissions.
- **Attaque (Coup d'éclat Mr. Robot)** : chiffrer `/srv/vault/ledger-verified.tar.gz` avec une nouvelle clé `openssl`, effacer la clé locale (`shred -u`), et poser `/srv/vault/.locked_by_<MON_TEAM_ID>` pour verrouiller la zone en `ENCRYPTED` (+4 pts/tick).

---

## 6. Chronogramme Type (Séance de 3h)

| Temps | Phase |
| :--- | :--- |
| `00:00 - 00:20` | Briefing règles, création réseau ZeroTier, `mise run join` et autorisation des nœuds |
| `00:20 - 01:00` | **Trêve de Hardening (40 min)** : chaque équipe répare ses Zones A, B, C (passage à 3/3 UP) |
| `01:00 - 02:30` | **Manche Domination (1h30)** : attaques/défenses en direct, projection du Dashboard Overseer |
| `02:30 - 03:00` | Gel des scores, podium et débriefing technique (signaux, permissions, chiffrement, SLA) |
