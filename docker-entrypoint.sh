#!/bin/bash
# Privilege-drop entrypoint.
#
#   PUID/PGID set (and running as root): remap the "pi" user to that uid/gid so
#     bind-mounted host state (~/.pi) is writable without chowning host files.
#   Neither set (running as root): just drop to the default pi user (uid 1000).
#   Already non-root (--user ...): exec pi directly.
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  if [ -n "${PUID:-}" ]; then
    groupmod -o -g "${PGID:-$PUID}" pi
    usermod -o -u "$PUID" pi
    # usermod does not chown anything; fix the prefixes the pi user writes to.
    # Shallow for /home/pi (a bind-mounted ~/.pi must keep host ownership),
    # recursive for linuxbrew only when it became unwritable, so a UID change
    # self-heals in one slow run and is skipped afterwards.
    chown pi:pi /home/pi
    if [ ! -w /home/linuxbrew/.linuxbrew ]; then
      echo "re-owning /home/linuxbrew for uid ${PUID} (one-time after UID change)"
      chown -R pi:pi /home/linuxbrew
    fi
    echo "pi user remapped to ${PUID}:${PGID:-$PUID}"
    if [ ! -w /home/linuxbrew/.linuxbrew ]; then
      echo "warning: /home/linuxbrew still not writable by ${PUID}; brew installs will fail." >&2
    fi
  fi
  # gosu sets HOME/USER for the target uid, so pi finds ~/.pi correctly.
  exec gosu "${PUID:-1000}:${PGID:-${PUID:-1000}}" pi "$@"
fi

exec pi "$@"
