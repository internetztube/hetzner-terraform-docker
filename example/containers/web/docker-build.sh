#!/bin/bash

# This file is optional!

# All environment variables from the pipeline are available.
# In addition, you have access to those environment variables:
# CONTAINER_TAG=
# CONTAINER_NAME=

docker build -t "${CONTAINER_TAG}" -f Dockerfile .
