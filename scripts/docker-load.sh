#!/bin/bash

set -e -u

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
  fi
done

services="$(yq eval '.services | keys[]' /root/docker-compose.yml)"
for service_name in $services; do
  mkdir -p "/mnt/volume/${service_name}"
done

systemctl restart docker-compose
