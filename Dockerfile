# Pi coding agent container image.
# Based on the official "Plain Docker" pattern:
# https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/containerization.md

FROM node:24-bookworm-slim

# Pin the pi version; override at build time with --build-arg PI_VERSION=x.y.z
ARG PI_VERSION=1.3.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      git \
      ripgrep \
      openssh-client \
      less \
      procps \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION} \
 && npm cache clean --force

WORKDIR /workspace

ENTRYPOINT ["pi"]
