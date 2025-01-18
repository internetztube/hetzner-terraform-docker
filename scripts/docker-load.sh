#!/bin/bash

set -euo pipefail

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
  fi
done

services=$(yq -r '.services | keys[]' /root/docker-compose.yml)
for service in ${services}; do
  mkdir -p "/app/volume/${service}"
done

systemctl restart docker-compose
