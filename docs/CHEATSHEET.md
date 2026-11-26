# Mémo Commandes Linux — Opération E-Corp

## Navigation & Exploration

| Commande | Description |
| :--- | :--- |
| `ls -la` | Liste tous les fichiers, y compris les fichiers cachés (`.fichier`) et leurs droits |
| `find /opt -maxdepth 3` | Recherche des fichiers/dossiers dans une arborescence |
| `cat` / `less` / `bat` | Affiche le contenu d'un fichier |
| `micro fichier` | Éditeur de texte simple (`Ctrl+S` sauvegarder, `Ctrl+Q` quitter) |

## Filtrage de Texte & Logs

| Commande | Description |
| :--- | :--- |
| `grep -E '401\|403' fichier` | Filtre les lignes contenant `401` ou `403` |
| `awk '{print $1}'` | Extrait la première colonne de chaque ligne |
| `sort \| uniq -c \| sort -nr` | Compte et trie les occurrences par ordre décroissant |

## Permissions POSIX

| Commande | Description |
| :--- | :--- |
| `stat -c '%a %U:%G' fichier` | Affiche les droits octaux, le propriétaire et le groupe |
| `chmod 0640 fichier` | Lecture/écriture propriétaire, lecture groupe, rien pour les autres |
| `chmod 0600 fichier` | Lecture/écriture uniquement pour le propriétaire (clés privées) |
| `chmod +x script.sh` | Rend un script exécutable |
| `chown operator:ecorp-web f` | Change le groupe propriétaire du fichier |

## Processus & Signaux

| Commande | Description |
| :--- | :--- |
| `ps aux` | Liste tous les processus en cours |
| `ps -eo pid,ppid,stat,comm` | Affiche PID, PID parent (`PPID`), état (`Z` = zombie) et commande |
| `htop` | Moniteur interactif CPU/RAM (`q` pour quitter) |
| `kill -TERM <PID>` | Demande un arrêt propre (signal 15, interceptable) |
| `kill -HUP <PID>` | Demande un rechargement de configuration (signal 1) |
| `kill -9 <PID>` | Arrêt forcé immédiat (`SIGKILL`, non interceptable) |

## Archives, Intégrité & Chiffrement

| Commande | Description |
| :--- | :--- |
| `tar -xzf archive.tar.gz -C dir/` | Extrait une archive `.tar.gz` dans `dir/` |
| `tar -czf out.tar.gz -C dir/ f1 f2` | Crée une archive `.tar.gz` |
| `sha256sum -c SHA256SUMS` | Vérifie l'intégrité des fichiers contre une liste d'empreintes |
| `openssl enc -aes-256-cbc -pbkdf2 -salt -in A -out B -pass file:K` | Chiffre le fichier `A` vers `B` avec la clé `K` |
