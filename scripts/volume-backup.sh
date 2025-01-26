#!/bin/bash

set -eu

# Runtime Environment: remote via github actions/ssh

# AWS_REGION=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_ENDPOINT_URL=
# BACKUP_S3_BUCKET_NAME=
# BACKUP_PREFIX=backup
# BACKUP_KEEP_COUNT=5

# BACKUP_CLEANUP=true

MOUNT_FOLDER="/root/volume"
BACKUP_KEEP_COUNT="${BACKUP_KEEP_COUNT:-5}"
BACKUP_CLEANUP="${BACKUP_CLEANUP:-"true"}"
RCLONE_CONFIG_FILE_PATH="/root/rclone-config"

BACKUP_FILENAME="${BACKUP_PREFIX:-"backup"}-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"

if ! aws s3 ls "s3://${BACKUP_S3_BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Bucket '${BACKUP_S3_BUCKET_NAME}' does not exist. Proceeding to create it."
  aws s3api create-bucket --bucket "${BACKUP_S3_BUCKET_NAME}" --acl "private"
  aws s3api wait bucket-exists --bucket "${BACKUP_S3_BUCKET_NAME}"
else
  echo "Bucket '${BACKUP_S3_BUCKET_NAME}' already exists and is accessible."
fi

cd "${MOUNT_FOLDER}" || exit 1
tar --exclude=z -czvf "${BACKUP_FILENAME}" $(ls -A)

# Got the following error when using `aws s3 cp`. Therefore, using rclone here.
# fatal error: argument of type 'NoneType' is not iterable
rclone selfupdate

echo "[s3]
type = s3
provider = Other
access_key_id = ${AWS_ACCESS_KEY_ID}
secret_access_key = ${AWS_SECRET_ACCESS_KEY}
endpoint = ${AWS_ENDPOINT_URL}
region = ${AWS_REGION}" >> "${RCLONE_CONFIG_FILE_PATH}"

rclone -vv --config /root/rclone-config copy "${MOUNT_FOLDER}/${BACKUP_FILENAME}" s3:${BACKUP_S3_BUCKET_NAME}
rm -f "${RCLONE_CONFIG_FILE_PATH}"
rm -f "${MOUNT_FOLDER}/${BACKUP_FILENAME}"

if [ "${BACKUP_CLEANUP}" = "true" ]; then
  aws s3 ls "s3://${BACKUP_S3_BUCKET_NAME}" | \
  sort -r | \
  tail -n +"$((BACKUP_KEEP_COUNT + 1))" | \
  awk '{print $4}' | \
  while read -r key; do
    aws s3 rm "s3://${BACKUP_S3_BUCKET_NAME}/${key}"
  done
  echo "Cleanup completed: Old files deleted."
else
  echo "Cleanup skipped: BACKUP_CLEANUP is not set to true."
fi
