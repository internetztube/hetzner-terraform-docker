#!/bin/bash

set -eu

# Runtime Environment: remote via terraform/ssh

for tar_file in /root/container-artifacts/*.tar; do
  if [ -f "${tar_file}" ]; then
    echo "Loading Docker image from: ${tar_file}"
    docker load -i "${tar_file}"
  fi
done

# Create volume folders
cd /root
yq -r ".services.[].volumes[] | split(\":\")[0]" docker-compose.yml | tr '\n' '\0' | xargs -0 mkdir -p

# Pull latest container images.
docker compose pull --ignore-pull-failures

# Restart!
systemctl restart docker-compose

# Delete old container images.
docker image prune -f
