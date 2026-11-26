#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="/var/lib/ecorp/ssh"
HOST_KEY="${SSH_DIR}/ssh_host_ed25519_key"
SSHD_CFG="/etc/ecorp/sshd_config"
ZONE_NAME="${1:-ecorp-node}"

mkdir -p "${SSH_DIR}"

if [[ ! -f "${HOST_KEY}" ]]; then
  ssh-keygen -q -t ed25519 -N "" -f "${HOST_KEY}"
fi

cat > "${SSHD_CFG}" <<EOF
Port 2222
ListenAddress 0.0.0.0
HostKey ${HOST_KEY}
PidFile /tmp/sshd.pid
AuthorizedKeysFile /run/ecorp-keys/id_ed25519.pub
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
UsePAM no
StrictModes no
PrintMotd yes
Subsystem sftp internal-sftp
EOF

if [[ ! -f "/home/operator/.bashrc.ecorp" ]]; then
  cat > "/home/operator/.bashrc.ecorp" <<EOF
export PS1='\[\033[1;31m\][operator@${ZONE_NAME}\[\033[0m\] \[\033[1;36m\]\w\[\033[1;31m\]]\$\[\033[0m\] '
alias ll='ls -la'
EOF
  printf '\n[ -f ~/.bashrc.ecorp ] && . ~/.bashrc.ecorp\n' >> /home/operator/.bashrc
fi

exec /usr/sbin/sshd -D -e -f "${SSHD_CFG}"
