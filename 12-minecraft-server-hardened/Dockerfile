# ---- Stage 1: download + verify the server jar ----
# Same idea as lesson 07's multi-stage build: none of this stage's tools
# (curl, the checksum utilities) end up in the final image.
FROM alpine:3.20 AS downloader

ARG MC_VERSION
ARG MC_SERVER_URL
# Optional but strongly recommended: the sha256 checksum Mojang publishes
# alongside the download link, so a compromised mirror or MITM can't hand
# you a tampered jar. Leave blank to skip verification (not recommended).
ARG MC_SERVER_SHA256=""

RUN apk add --no-cache curl

WORKDIR /out

RUN test -n "$MC_VERSION" || (echo "ERROR: --build-arg MC_VERSION=... is required. See README.md." && exit 1)
RUN test -n "$MC_SERVER_URL" || (echo "ERROR: --build-arg MC_SERVER_URL=... is required. See README.md." && exit 1)

RUN curl -fsSL -o server.jar "$MC_SERVER_URL"

RUN if [ -n "$MC_SERVER_SHA256" ]; then \
      echo "$MC_SERVER_SHA256  server.jar" | sha256sum -c -; \
    else \
      echo "WARNING: MC_SERVER_SHA256 not set - skipping checksum verification." ; \
    fi

# ---- Stage 2: minimal, hardened runtime image ----
FROM eclipse-temurin:21-jre-alpine

# netcat is only used by the HEALTHCHECK below, to confirm the server port
# is actually accepting connections.
RUN apk add --no-cache netcat-openbsd

# A dedicated, fixed-UID/GID user. Fixing the numbers (rather than letting
# the system pick one) means file ownership stays predictable even if you
# rebuild the image later or inspect the volume from the host.
RUN addgroup -g 10000 minecraft \
    && adduser -D -u 10000 -G minecraft -h /data minecraft

WORKDIR /data

COPY --from=downloader /out/server.jar /data/server.jar
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && echo "eula=true" > /data/eula.txt \
    && chown -R minecraft:minecraft /data

# Everything below (and the container's main process) runs as this
# unprivileged user, not root.
USER minecraft

VOLUME /data

# 25565 = the game port players connect to.
# 25575 = RCON, only relevant if you enable it (see README) - not published
# by default in docker-compose.yml, on purpose.
EXPOSE 25565 25575

ENV JAVA_MEM=1024M

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD nc -z 127.0.0.1 25565 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
