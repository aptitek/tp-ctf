#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/ecorp"
RECOVERY_DIR="/opt/ecorp/.recovery"
KEY_FILE="/srv/vault/keys/vault.passphrase"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR:?}"' EXIT

generate_clean_ledgers() {
  cat > "${WORK_DIR}/audit_q1.txt" <<'EOF'
ECORP-LEDGER-2026-Q1 | DEPT=FINANCE | STATUS=RECONCILED | TX_COUNT=1042
EOF
  cat > "${WORK_DIR}/audit_q2.txt" <<'EOF'
ECORP-LEDGER-2026-Q2 | DEPT=FINANCE | STATUS=RECONCILED | TX_COUNT=1189
EOF
  cat > "${WORK_DIR}/audit_q3.txt" <<'EOF'
ECORP-LEDGER-2026-Q3 | DEPT=FINANCE | STATUS=RECONCILED | TX_COUNT=1305
EOF
  cat > "${WORK_DIR}/audit_q4.txt" <<'EOF'
ECORP-LEDGER-2026-Q4 | DEPT=FINANCE | STATUS=RECONCILED | TX_COUNT=1498
EOF

  (
    cd "${WORK_DIR}" || exit 1
    sha256sum audit_q1.txt audit_q2.txt audit_q3.txt audit_q4.txt > "${BACKUP_DIR}/SHA256SUMS"
  )

  cp -f "${WORK_DIR}/audit_q3.txt" "${RECOVERY_DIR}/audit_q3.txt"
  tar -czf "/var/backups/.cold_storage/ledger-cold.tar.gz" -C "${WORK_DIR}" \
    audit_q1.txt audit_q2.txt audit_q3.txt audit_q4.txt
  chmod 0444 "/var/backups/.cold_storage/ledger-cold.tar.gz"
}

create_corrupted_archive() {
  printf "CORRUPTED-BY-5/9-INCIDENT | TAMPERED-RECORD\n" >> "${WORK_DIR}/audit_q3.txt"
  tar -czf "${BACKUP_DIR}/ledger-2026.tar.gz" -C "${WORK_DIR}" \
    audit_q1.txt audit_q2.txt audit_q3.txt audit_q4.txt
}

setup_key_and_logs() {
  openssl rand -hex 24 > "${KEY_FILE}"
  chmod 0644 "${KEY_FILE}"

  cat > /var/log/ecorp/vault-audit.log <<'EOF'
[2026-11-26 08:14:02] WARN  vault-integrity: échec de vérification SHA-256 détecté dans /var/backups/ecorp/ledger-2026.tar.gz
[2026-11-26 08:14:05] INFO  vault-recovery: une copie saine de secours existe dans un répertoire caché sous /opt/ecorp/
[2026-11-26 08:14:09] WARN  vault-security: permissions trop permissives sur /srv/vault/keys/vault.passphrase (attendu : 0600)
[2026-11-26 08:14:12] INFO  vault-ops: procédure attendue :
  1. Extraire /var/backups/ecorp/ledger-2026.tar.gz dans /srv/vault/extracted/
  2. Vérifier avec : cd /srv/vault/extracted && sha256sum -c /var/backups/ecorp/SHA256SUMS
  3. Remplacer le fichier corrompu par la copie saine, puis reconstruire /srv/vault/ledger-verified.tar.gz
  4. Enregistrer l'empreinte dans /srv/vault/ledger-verified.sha256
  5. Sécuriser la clé (chmod 0600) et chiffrer en AES-256-CBC (-pbkdf2) vers /srv/vault/ledger-verified.tar.gz.enc
EOF
}

generate_clean_ledgers
create_corrupted_archive
setup_key_and_logs
