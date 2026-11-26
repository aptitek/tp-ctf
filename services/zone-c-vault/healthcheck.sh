#!/usr/bin/env bash
set -euo pipefail

KEY_FILE="/srv/vault/keys/vault.passphrase"
VERIFIED_TAR="/srv/vault/ledger-verified.tar.gz"
ENCRYPTED_TAR="/srv/vault/ledger-verified.tar.gz.enc"
SHA_FILE="/srv/vault/ledger-verified.sha256"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR:?}"' EXIT

PASSED=0
DETAILS=()

record_check() {
  local label="${1}"
  shift
  if "$@"; then
    PASSED=$((PASSED + 1))
    DETAILS+=("${label}:OK")
  else
    DETAILS+=("${label}:FAIL")
  fi
}

check_key_perms() {
  local mode=""
  mode="$(stat -c '%a' "${KEY_FILE}" 2>/dev/null || echo '000')"
  [[ "${mode}" == "600" ]]
}

check_archive_integrity() {
  [[ -f "${VERIFIED_TAR}" ]] || return 1
  mkdir -p "${TMP_DIR}/ext"
  tar -xzf "${VERIFIED_TAR}" -C "${TMP_DIR}/ext" 2>/dev/null || return 1
  (
    cd "${TMP_DIR}/ext" || exit 1
    sha256sum -c /var/backups/ecorp/SHA256SUMS >/dev/null 2>&1
  )
}

check_archive_encrypted() {
  [[ -f "${ENCRYPTED_TAR}" && -f "${VERIFIED_TAR}" && -f "${KEY_FILE}" ]] || return 1
  openssl enc -d -aes-256-cbc -pbkdf2 \
    -in "${ENCRYPTED_TAR}" \
    -out "${TMP_DIR}/dec.tar.gz" \
    -pass "file:${KEY_FILE}" >/dev/null 2>&1 || return 1
  cmp -s "${VERIFIED_TAR}" "${TMP_DIR}/dec.tar.gz"
}

check_sha256_recorded() {
  [[ -f "${VERIFIED_TAR}" && -f "${SHA_FILE}" ]] || return 1
  local expected=""
  expected="$(sha256sum "${VERIFIED_TAR}" | awk '{print $1}')"
  grep -Fq "${expected}" "${SHA_FILE}"
}

main() {
  record_check "key_perms" check_key_perms
  record_check "archive_integrity" check_archive_integrity
  record_check "archive_encrypted" check_archive_encrypted
  record_check "sha256_recorded" check_sha256_recorded

  if [[ "${1:-}" == "--report" ]]; then
    printf "%d/4|%s\n" "${PASSED}" "${DETAILS[*]}"
  fi

  [[ "${PASSED}" -eq 4 ]]
}

main "${1:-}"
