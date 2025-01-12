#!/bin/bash

set -e -u

# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# BACKUP_BUCKET_LOCATION=
# BACKUP_BUCKET_NAME=
# BACKUP_SSH_PRIVATE_KEY=
# BACKUP_TERRAFORM_MODULE_PATH=

SERVER_IP=$(terraform console <<< "${BACKUP_TERRAFORM_MODULE_PATH}.server_ipv4" | tr -d '"')
BACKUP_SSH_PRIVATE_KEY="${BACKUP_SSH_PRIVATE_KEY}"
BACKUP_BUCKET_LOCATION="${BACKUP_BUCKET_LOCATION}"

echo "Connecting to ${SERVER_IP} ..."
echo "${BACKUP_SSH_PRIVATE_KEY}" > id_rsa
chmod 600 id_rsa

# Create .ssh directory
mkdir -p ~/.ssh

# Add remote host to known_hosts to prevent host key verification failure
ssh-keyscan -H "${SERVER_IP}" >> ~/.ssh/known_hosts

# Optional: Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/known_hosts

ssh -i id_rsa root@"${SERVER_IP}" bash -s <<EOF
  export AWS_REGION="${BACKUP_BUCKET_LOCATION}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
  export BUCKET_NAME="${BACKUP_BUCKET_NAME}"
  export BACKUP_FILENAME_PREFIX="${BACKUP_TERRAFORM_MODULE_PATH}"
  sh /root/volume-backup.sh
EOF
