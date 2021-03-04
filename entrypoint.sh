#!/bin/bash

set -x

# inside docker script
trap 'kill $(jobs -p)' EXIT

# 0. generate xorg.conf
NUMBER_OF_GPU=$(nvidia-xconfig --query-gpu-info | grep 'PCI BusID' | sed -r 's/\s*PCI BusID : PCI:(.*)/\1/' | wc -l)
/xorg_generator.py "${NUMBER_OF_GPU}" "${RESOLUTION}" > /etc/X11/xorg.conf

# 0. confirm xorg.conf
cat /etc/X11/xorg.conf

# 1. dbus start.
/etc/init.d/dbus start
sleep 2

# 2. launch X server
Xorg :10 &
sleep 5
cat /var/log/Xorg.10.log

exec "$@"
