#!/bin/bash

docker run -it --rm --gpus all \
  --device=/dev/tty0:/dev/tty0 \
  --device=/dev/tty1:/dev/tty1 \
  --device=/dev/tty2:/dev/tty2 \
  --device=/dev/tty3:/dev/tty3 \
  --device=/dev/tty4:/dev/tty4 \
  --device=/dev/tty5:/dev/tty5 \
  --device=/dev/tty6:/dev/tty6 \
  -e RESOLUTION=1280x720 \
  -v /tmp/.rdbox.X11-unix:/tmp/.X11-unix \
  --name xserver-nvidia-tesla rdbox/xserver-nvidia-tesla:v0.0.1