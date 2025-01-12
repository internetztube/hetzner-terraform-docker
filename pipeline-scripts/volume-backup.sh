#!/bin/bash

set -e -u

# TERRAFORM_MODULE_PATH=
# TF_VAR_ssh_private_key=
# AWS_REGION=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# BUCKET_NAME=

terraform init

SERVER_IP=$(terraform console <<< "${TERRAFORM_MODULE_PATH}.server_ipv4" | tr -d '"')
TF_VAR_ssh_private_key="${TF_VAR_ssh_private_key}"

echo "Connecting to ${SERVER_IP} ..."
echo "${TF_VAR_ssh_private_key}" > id_rsa
chmod 600 id_rsa

# Create .ssh directory
mkdir -p ~/.ssh

# Add remote host to known_hosts to prevent host key verification failure
ssh-keyscan -H "${SERVER_IP}" >> ~/.ssh/known_hosts

# Optional: Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/known_hosts

ssh -i id_rsa root@"${SERVER_IP}" bash -s <<EOF
  export AWS_REGION="${AWS_REGION}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
  export BUCKET_NAME="${BUCKET_NAME}"
  export BACKUP_FILENAME_PREFIX="${TERRAFORM_MODULE_PATH}"
  sh /root/volume-backup.sh
EOF
