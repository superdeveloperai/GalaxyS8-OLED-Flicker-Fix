FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    python2 \
    python3 \
    git \
    cpio \
    xz-utils \
    lz4 \
    kmod \
    abootimg \
    device-tree-compiler \
    ca-certificates \
    && ln -sf /usr/bin/python2 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
