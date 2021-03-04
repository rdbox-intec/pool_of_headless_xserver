#!/bin/sh

DRIVER_VERSION="$1"
PRODUCT_BRAND="$2"
url=""

if [ "${PRODUCT_BRAND}" = "Tesla" ]; then
  url="https://jp.download.nvidia.com/tesla/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run"
elif [ "${PRODUCT_BRAND}" = "GeForce" ]; then
  url="https://jp.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run"
else
  exit 1
fi

echo "${url}"
