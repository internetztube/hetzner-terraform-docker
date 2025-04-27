#!/bin/bash

set -eu

# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_REGION=
# AWS_ENDPOINT_URL="https://${AWS_REGION}.your-objectstorage.com"
# BACKUP_S3_BUCKET_NAME=
# BACKUP_SSH_PRIVATE_KEY=
# BACKUP_TERRAFORM_MODULE_PATH=
# BACKUP_FILE_NAME=

SERVER_IP=$(
  terraform show -json \
    | jq -r "
      .values.root_module.child_modules[]
      | select(.address==\"${BACKUP_TERRAFORM_MODULE_PATH}\")
      | .resources[]
      | select(.address==\"${BACKUP_TERRAFORM_MODULE_PATH}.hcloud_server.default\")
      | .values.ipv4_address
    "
)

AWS_REGION="${AWS_REGION}"
AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-"https://${AWS_REGION}.your-objectstorage.com"}"
BACKUP_SSH_PRIVATE_KEY="${BACKUP_SSH_PRIVATE_KEY}"
BACKUP_PREFIX="${BACKUP_PREFIX:-"${BACKUP_TERRAFORM_MODULE_PATH}"}"

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

ssh -i id_rsa "root@${SERVER_IP}" bash -s <<EOF
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
  export AWS_REGION="${AWS_REGION}"
  export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL}"

  export BACKUP_S3_BUCKET_NAME="${BACKUP_S3_BUCKET_NAME}"
  export BACKUP_FILE_NAME="${BACKUP_FILE_NAME}"
  export BACKUP_PREFIX="${BACKUP_PREFIX}"
  sh /root/volume-restore.sh
EOF
