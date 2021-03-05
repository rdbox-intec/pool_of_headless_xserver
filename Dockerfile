FROM ubuntu:focal-20200925

# Make all NVIDIA GPUS visible, but I want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
# Supress interactive menu while installing keyboard-configuration
ARG DEBIAN_FRONTEND=noninteractive

# Error constructing proxy for org.gnome.Terminal:/org/gnome/Terminal/Factory0: Failed to execute child process dbus-launch (No such file or directory)
# fix by setting LANG https://askubuntu.com/questions/608330/problem-with-gnome-terminal-on-gnome-3-12-2
# to install locales https://stackoverflow.com/questions/39760663/docker-ubuntu-bin-sh-1-locale-gen-not-found
RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# (1) Install Xorg and NVIDIA driver inside the container
# Almost same procesure as nvidia/driver https://gitlab.com/nvidia/driver/blob/master/ubuntu16.04/Dockerfile

# (1-1) Install prerequisites
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gnupg2 \
        apt-utils \
        build-essential \
        ca-certificates \
        curl \
        kmod \
        file \
        libelf-dev \
        libglvnd-dev \
        pkg-config

# (1-2) Install xorg server and xinit BEFORE INSTALLING NVIDIA DRIVER.
# After this installation, command Xorg and xinit can be used in the container
# if you need full ubuntu desktop environment, the line below should be added.
        # ubuntu-desktop \
RUN apt-get install -y \
        xinit

# (1-3) Install NVIDIA drivers, including X graphic drivers
# Same command as nvidia/driver, except --x-{prefix,module-path,library-path,sysconfig-path} are omitted in order to make use default path and enable X drivers.
# Driver version must be equal to host's driver
# Install the userspace components and copy the kernel module sources.
COPY generate_url.sh /generate_url.sh
ARG DRIVER_VERSION
ENV DRIVER_VERSION $DRIVER_VERSION
ARG PRODUCT_BRAND
ENV PRODUCT_BRAND $PRODUCT_BRAND
RUN cd /tmp && \
    curl -fSsl -O $(sh /generate_url.sh $DRIVER_VERSION $PRODUCT_BRAND) && \
    sh NVIDIA-Linux-x86_64-$DRIVER_VERSION.run -x && \
    cd NVIDIA-Linux-x86_64-$DRIVER_VERSION && \
    ./nvidia-installer --silent \
                      --no-kernel-module \
                      --install-compat32-libs \
                      --no-nouveau-check \
                      --no-nvidia-modprobe \
                      --no-rpms \
                      --no-backup \
                      --no-check-for-alternate-installs \
                      --no-libglx-indirect \
                      --no-install-libglvnd && \
    mkdir -p /usr/src/nvidia-$DRIVER_VERSION && \
    mv LICENSE mkprecompiled kernel /usr/src/nvidia-$DRIVER_VERSION && \
    sed '9,${/^\(kernel\|LICENSE\)/!d}' .manifest > /usr/src/nvidia-$DRIVER_VERSION/.manifest

# (2) Configurate Xorg
# (2-1) Optional vulkan support
# vulkan-utils includes vulkan-smoketest, benchmark software of vulkan API
RUN apt-get install -y --no-install-recommends \
        libvulkan1 vulkan-utils

# Xorg segfault error
# dbus-core: error connecting to system bus: org.freedesktop.DBus.Error.FileNotFound (Failed to connect to socket /var/run/dbus/system_bus_socket: No such file or directory)
# related? https://github.com/Microsoft/WSL/issues/2016
RUN apt-get install -y --no-install-recommends \
      dbus-x11 \
      libdbus-c++-1-0v5 && \
    rm -rf /var/lib/apt/lists/*

# (3) Run Xorg server
COPY entrypoint.sh /entrypoint.sh
COPY xorg_generator_tesla.py /xorg_generator_tesla.py
COPY xorg_generator_geforce.py /xorg_generator_geforce.py
ENTRYPOINT ["/entrypoint.sh"]
CMD tail -f /dev/null
