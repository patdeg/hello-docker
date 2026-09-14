#!/bin/sh
# Injects RCON settings from an environment variable at container START time,
# instead of baking any secret into the image at BUILD time. Anyone who
# `docker history`/`docker inspect`s the image sees no password at all —
# only a container that was actually run with RCON_PASSWORD set has one.
set -eu

if [ -n "${RCON_PASSWORD:-}" ]; then
  if [ -f /data/server.properties ]; then
    grep -v -E '^(enable-rcon|rcon\.password|rcon\.port)=' /data/server.properties > /data/server.properties.new || true
  else
    : > /data/server.properties.new
  fi
  {
    cat /data/server.properties.new
    echo "enable-rcon=true"
    echo "rcon.password=${RCON_PASSWORD}"
    echo "rcon.port=${RCON_PORT:-25575}"
  } > /data/server.properties
  rm -f /data/server.properties.new
fi

exec java -Xmx"${JAVA_MEM}" -Xms"${JAVA_MEM}" -jar /data/server.jar nogui
