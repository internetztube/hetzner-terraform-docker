#!/bin/bash

set -e -u

# Runtime Environment: remote via terraform/ssh

# VOLUME_ID=

DEVICE="/dev/disk/by-id/scsi-0HC_Volume_${VOLUME_ID}"
MOUNT_POINT="/mnt/volume"

# Wait for the device to be available
while [ ! -b "${DEVICE}" ]; do
  sleep 5
done

# Wait for the device to be available
while [ ! -b "${DEVICE}" ]; do
  echo "Disk is not available!"
  exit 1
done

# Format the volume if not already formatted
if ! blkid "${DEVICE}"; then
  mkfs.ext4 -F "${DEVICE}"
fi

# Create the mount point directory
mkdir -p "${MOUNT_POINT}"

# Mount the volume
mount -o discard,defaults "${DEVICE}" "${MOUNT_POINT}"

# Add volume to fstab if not already present
if ! grep -qs "${DEVICE}" /etc/fstab; then
  echo "${DEVICE} ${MOUNT_POINT} ext4 discard,nofail,defaults 0 0" >> /etc/fstab
fi
