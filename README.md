# pool of headless xserver

Provides GPU-based OpenGL hardware acceleration for the R2S2(RDBOX Robotics Simulation System).  

This repository's Dockerfile based on [glx\-docker\-headless\-gpu/Dockerfile](https://github.com/ryought/glx-docker-headless-gpu/blob/master/Dockerfile).  
Change: In the R2S2, the display process is executed externally by using VirtualGL. For this reason, the display system processing has been omitted.

## Overview

![xserver](https://github.com/rdbox-intec/vgl_client/raw/main/docs/images/r2s2_queueing.png)

The above figure is a system overview of the R2S2 queuing system. `The pool of headless xserver` is container of those falling under `(Deployment X window server)`.  
This container is deployed by Kubernetes Deployment workloads to nodes with GPUs, depending on the number of replicas specified. Then, depending on the number of GPUs installed on the node with GPU and the Product Brand of the GPU, one or more Xorg processes will be resident.
They are used by VirtualGL containers via Unix domain socket communication. (In it, OpenGL applications such as Unity are running.)
