#!/bin/bash

set -eu

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
  fi
done

# Each container from docker-compose.yml gets their own persistent folder.
services=$(yq -r '.services | keys[]' /root/docker-compose.yml)
for service in ${services}; do
  mkdir -p "/root/volume/${service}"
done

# Pull latest container images.
docker compose pull --ignore-pull-failures

# Restart!
systemctl restart docker-compose

# Delete old container images.
docker image prune -f
