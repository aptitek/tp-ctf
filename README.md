# Opération E-Corp — TP Terminal Linux

```text
  ______      _____ ____  _____  _____
 |  ____|    / ____/ __ \|  __ \|  __ \
 | |__ _____| |   | |  | | |__) | |__) |
 |  __|_____| |   | |  | |  _  /|  ___/
 | |____    | |___| |__| | | \ \| |
 |______|    \_____\____/|_|  \_\_|
      [ OPÉRATION E-CORP // TERMINUS OPS ]
```

> *« Hello, friend. »*
> Trois serveurs critiques d'E-Corp viennent de basculer en état dégradé.
> Pas d'interface graphique. Pas de magie. Juste toi, un terminal Linux et tes commandes.

---

## Démarrage Rapide (Zéro Friction)

Prérequis déjà installés sur ta machine : `git`, `docker` (avec Compose) et `mise`.

```bash
# 1. Installer les outils du projet (go-task, jq)
mise install

# 2. Construire et démarrer l'infrastructure E-Corp
mise run start

# 3. Entrer dans ton terminal Bastion
mise run enter
```

Une fois dans le bastion, tape `mission` pour lire ton briefing et `ecorp-radar` pour scanner les cibles.

---

## Commandes Essentielles

| Commande | Action |
| :--- | :--- |
| `mise run start` | Construit et démarre tous les serveurs E-Corp |
| `mise run enter` | Ouvre un shell interactif dans le conteneur `bastion` |
| `mise run status` | Affiche l'état de contrôle des Zones **A**, **B** et **C** |
| `mise run reset` | Remet tout l'environnement à zéro en cas d'erreur critique |
| `mise run stop` | Met en pause l'infrastructure |
| `mise run arena` | Active le mode multijoueur « Roi de la Colline » (profil `arena`) |
| `mise run join -- <ZT_ID> <TEAM>` | Rejoint l'Arène ZeroTier et affiche ton `Node ID` + IP |
| `mise run radar` | Affiche ton identité ZeroTier, les pairs et l'état des Zones A, B, C |
| `mise run emergency-restore -- <zone>` | Restaure une zone cassée (avec marqueur de pénalité Scorebot) |
| `mise run overseer -- <ZT_ID>` | *(Formateur)* Lance le Scorebot & Dashboard sur `http://localhost:9000` |

---

## Architecture du Terrain

```text
                  ┌───────────────────────┐
                  │        bastion        │  <-- mise run enter
                  │   (MISSION.md + SSH)  │
                  └───────────┬───────────┘
                              │ réseau isolé (ecorp-net)
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ zone-a-vitrine  │  │    zone-b-rh    │  │  zone-c-vault   │
│  Logs & Droits  │  │ Process & Sign. │  │ Tar, Hash & Enc │
│   ssh zone-a    │  │   ssh zone-b    │  │   ssh zone-c    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## Tes 3 Zones à Reprendre

- **Zone A (`ssh zone-a`) — Serveur Web / Frontal** : filtrage de logs (`grep`, `awk`, `sort`, `uniq`) et réparation de permissions POSIX (`chmod`, `chown`).
- **Zone B (`ssh zone-b`) — Serveur Interne RH** : diagnostic de processus (`ps`, `htop`), signaux Linux (`kill -9`, `SIGHUP`), élimination de processus zombies et correction de configuration.
- **Zone C (`ssh zone-c`) — Coffre de Sauvegardes** : extraction/création d'archives (`tar`), contrôle d'intégrité (`sha256sum`) et chiffrement symétrique (`openssl`) avec gestion sécurisée des clés.

Besoin d'un rappel sur les commandes ? Consulte [docs/CHEATSHEET.md](docs/CHEATSHEET.md).

---

*Formateurs : le guide Phase 1 se trouve dans [docs/TEACHER.md](docs/TEACHER.md) et le guide Arène Multijoueur ZeroTier dans [docs/TEACHER_ARENA.md](docs/TEACHER_ARENA.md).*
