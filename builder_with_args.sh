#!/bin/bash

set -x

DRIVER_VERSION="$1" # 450.102.04
PRODUCT_BRAND="$2"  # Tesla

docker build \
  --build-arg DRIVER_VERSION="$DRIVER_VERSION" \
  --build-arg PRODUCT_BRAND="$PRODUCT_BRAND" \
  -t rdbox/xserver-nvidia-tesla:v0.0.1 \
  -f Dockerfile .