# A real, working vanilla Minecraft: Java Edition server, using everything
# from lessons 01-12: a base image, installing a package, build ARGs,
# EXPOSE, and a VOLUME for the world data.
FROM eclipse-temurin:21-jre-jammy

# You must supply both of these at build time (see README for how to get
# them from the official Minecraft download page). There is deliberately
# no default — a hardcoded server.jar URL here would eventually go stale
# or point at the wrong version.
ARG MC_VERSION
ARG MC_SERVER_URL

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /data

RUN test -n "$MC_VERSION" || (echo "ERROR: --build-arg MC_VERSION=... is required. See README.md." && exit 1)
RUN test -n "$MC_SERVER_URL" || (echo "ERROR: --build-arg MC_SERVER_URL=... is required. See README.md." && exit 1)

RUN curl -fsSL -o server.jar "$MC_SERVER_URL"

# By running this server you are agreeing to the Mojang EULA yourself —
# read it first: https://www.minecraft.net/en-us/eula
RUN echo "eula=true" > eula.txt

# World data, configs, logs, player data all live under /data.
VOLUME /data

EXPOSE 25565

ENV JAVA_MEM=1024M

# `sh -c` is needed so ${JAVA_MEM} gets filled in. The `exec` matters just as
# much: it makes java REPLACE the shell and become PID 1. Without it, sh stays
# PID 1, never passes Docker's stop signal on to java, and `docker stop` ends
# up force-killing the server after 10s — before it has saved the world.
# (Lesson 03: "Why did docker stop only take a second?")
CMD ["sh", "-c", "exec java -Xmx${JAVA_MEM} -Xms${JAVA_MEM} -jar server.jar nogui"]
