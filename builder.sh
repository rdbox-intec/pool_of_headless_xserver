#!/bin/bash

set -x

docker build \
  --build-arg DRIVER_VERSION="$(nvidia-smi -a | grep "Driver Version" | cut -d ":" -f 2 | sed "s/ //g")" \
  --build-arg PRODUCT_BRAND="$(nvidia-smi -a | grep "Product Brand" | cut -d ":" -f 2 | sed "s/ //g")" \
  -t rdbox/xserver-nvidia-tesla:v0.0.1 \
  -f Dockerfile .