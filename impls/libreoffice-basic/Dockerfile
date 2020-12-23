# -*- mode: shell-script -*-

FROM ubuntu:18.04

RUN apt-get update \
  && apt-get -y install --no-install-recommends \
    libreoffice-calc \
    ruby \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create ~/.config/libreoffice
RUN libreoffice --headless --terminate_after_init

WORKDIR /root/work
