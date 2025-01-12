#!/bin/bash

set -e -u

# Runtime Environment: remote via github actions/ssh

# AWS_REGION=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# BUCKET_NAME=
# BACKUP_CLEANUP=true
# BACKUP_FILENAME_PREFIX=backup

MOUNT_FOLDER="/mnt/volume"
BACKUP_KEEP_COUNT="${BACKUP_KEEP_COUNT:=5}"
BACKUP_CLEANUP="${BACKUP_CLEANUP:="true"}"

BACKUP_FILENAME="${BACKUP_FILENAME_PREFIX:="backup"}-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
export AWS_ENDPOINT_URL="https://${AWS_REGION}.your-objectstorage.com"

if ! aws s3 ls "s3://${BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Bucket '${BUCKET_NAME}' does not exist. Proceeding to create it."
  aws s3api create-bucket --bucket "${BUCKET_NAME}" --acl "private"
  aws s3api wait bucket-exists --bucket "${BUCKET_NAME}"
else
  echo "Bucket '${BUCKET_NAME}' already exists and is accessible."
fi

cd "${MOUNT_FOLDER}" || exit 1
tar --exclude=z -czvf "${BACKUP_FILENAME}" $(ls -A)

aws s3 cp "${MOUNT_FOLDER}/${BACKUP_FILENAME}" "s3://${BUCKET_NAME}/${BACKUP_FILENAME}"
rm -rf "${MOUNT_FOLDER}/${BACKUP_FILENAME}"

if [ "$BACKUP_CLEANUP" = "true" ]; then
  aws s3 ls "s3://${BUCKET_NAME}" | \
  sort -r | \
  tail -n +"$((BACKUP_KEEP_COUNT + 1))" | \
  awk '{print $4}' | \
  while read -r key; do
    aws s3 rm "s3://${BUCKET_NAME}/$key"
  done
  echo "Cleanup completed: Old files deleted."
else
  echo "Cleanup skipped: BACKUP_CLEANUP is not set to true."
fi
