#!/bin/bash

set -eu

# Runtime Environment: remote via github actions/ssh

# AWS_REGION=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# BUCKET_NAME=
# BACKUP_FILE_NAME=

MOUNT_FOLDER="/root/volume"
export AWS_ENDPOINT_URL="https://${AWS_REGION}.your-objectstorage.com"

# Check if file exists
if ! aws s3 ls "s3://${BUCKET_NAME}/${BACKUP_FILE_NAME}" > /dev/null 2>&1; then
  echo "File \"s3://${BUCKET_NAME}/${BACKUP_FILE_NAME}\" does not exist in bucket \"${BUCKET_NAME}\"!"
  exit 1
fi

# Creating a final backup.
echo ""
echo "Creating new backup:"
export BACKUP_CLEANUP="false"
sh /root/volume-backup.sh

# Downloading selected Backup and unpack.
echo ""
echo "Downloading \"${BACKUP_FILE_NAME}\"..."
backup_folder_restore="${MOUNT_FOLDER}/restore"
rm -rf "${backup_folder_restore}"
mkdir -p "${backup_folder_restore}"
cd "${backup_folder_restore}"
aws s3 cp "s3://${BUCKET_NAME}/${BACKUP_FILE_NAME}" "${BACKUP_FILE_NAME}"
tar -xf "${BACKUP_FILE_NAME}"
rm -rf "${BACKUP_FILE_NAME}"

# Stop Docker Containers to ensure a smooth restore.
systemctl stop docker-compose

# Move files and folders into ${MOUNT_FOLDER}.
for item in *; do
  if [ "${item}" = "." ] || [ "${item}" = ".." ]; then
    continue
  fi
  target="${MOUNT_FOLDER}/${item}"
  if [ -e "${target}" ]; then
    rm -rf "${target}"
  fi
  mv "${item}" "../"
  echo "Moved \"${item}\" to parent."
done
rm -rf "${backup_folder_restore}"

# Start Docker files.
systemctl start docker-compose
