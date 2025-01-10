#!/bin/bash

set -e -u

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
    CONTAINER_NAME="$(basename "${tar_file}" .tar)"
    mkdir -p "/mnt/volume/${CONTAINER_NAME}"
  fi
done
systemctl restart docker-compose
