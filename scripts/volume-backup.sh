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

BACKUP_FILENAME="${BACKUP_PREFIX:-"backup"}-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"

if ! aws s3 ls "s3://${BACKUP_S3_BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Bucket does not exit! '${BACKUP_S3_BUCKET_NAME}'"
  exit 1
else
  echo "Bucket '${BACKUP_S3_BUCKET_NAME}' already exists and is accessible."
fi

cd "${MOUNT_FOLDER}" || exit 1
# Ignore files changed on disk error. https://stackoverflow.com/a/31114992
tar --exclude=z -czvf "${BACKUP_FILENAME}" $(ls -A) || [[ $? -eq 1 ]]

aws s3 cp "${MOUNT_FOLDER}/${BACKUP_FILENAME}" s3://${BACKUP_S3_BUCKET_NAME}

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
