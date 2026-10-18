# Pi coding agent container image.
# Based on the official "Plain Docker" pattern:
# https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/containerization.md
#
# Runtime model:
#   - Starts as root ONLY to optionally re-map the unprivileged "pi" user to
#     PUID/PGID (linuxserver-style), then drops privileges via gosu.
#   - HOME=/home/pi; mount your host ~/.pi at /home/pi/.pi to carry over
#     agent config, audit registry, memory store, guard state, etc.
#   - Linuxbrew lives in /home/linuxbrew; mount a named volume there so
#     `brew install` survives container restarts.

FROM node:24-bookworm-slim

# Pin the pi version; override at build time with --build-arg PI_VERSION=x.y.z
ARG PI_VERSION=1.3.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      build-essential \
      ca-certificates \
      curl \
      file \
      git \
      gosu \
      less \
      openssh-client \
      procps \
      ripgrep \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION} \
 && npm cache clean --force

# The node base image already ships a uid/gid-1000 user "node"; rename it (and
# its group + home) to "pi" rather than fighting "UID 1000 is not unique".
RUN usermod -l pi -d /home/pi -m node \
 && groupmod -o -n pi node \
 && mkdir -p /home/linuxbrew \
 && chown pi:pi /home/linuxbrew

USER pi
ENV HOME=/home/pi
ENV CI=1
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
 && brew --version
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}" \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_ENV_HINTS=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1

USER root
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["docker-entrypoint.sh"]
CMD []
