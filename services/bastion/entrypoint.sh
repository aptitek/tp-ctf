#!/usr/bin/env bash
set -euo pipefail

KEY_DIR="/run/ecorp-keys"
PRIV_KEY="${KEY_DIR}/id_ed25519"
PUB_KEY="${KEY_DIR}/id_ed25519.pub"
SSH_HOME="/home/operator/.ssh"

mkdir -p "${KEY_DIR}" "${SSH_HOME}"
chmod 0700 "${SSH_HOME}"

if [[ ! -f "${PRIV_KEY}" ]]; then
  ssh-keygen -q -t ed25519 -N "" -C "operator@ecorp-bastion" -f "${PRIV_KEY}"
  chmod 0600 "${PRIV_KEY}"
  chmod 0644 "${PUB_KEY}"
fi

cp -f "${PRIV_KEY}" "${SSH_HOME}/id_ed25519"
cp -f "${PUB_KEY}" "${SSH_HOME}/id_ed25519.pub"
chmod 0600 "${SSH_HOME}/id_ed25519"
chmod 0644 "${SSH_HOME}/id_ed25519.pub"

cat > "${SSH_HOME}/config" <<'EOF'
Host zone-a zone-a-vitrine
  HostName zone-a-vitrine
  Port 2222
  User operator
  IdentityFile /home/operator/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR

Host zone-b zone-b-rh
  HostName zone-b-rh
  Port 2222
  User operator
  IdentityFile /home/operator/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR

Host zone-c zone-c-vault
  HostName zone-c-vault
  Port 2222
  User operator
  IdentityFile /home/operator/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
chmod 0600 "${SSH_HOME}/config"

exec sleep infinity
