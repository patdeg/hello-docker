# 12 — Hardening the Minecraft server (capstone)

## Goal

Take the working server from lesson 11 and answer the question it ended on:
*if something inside this container ever got exploited, how much damage
could it actually do?* Every change in this lesson exists to shrink that
answer.

This is also a good general checklist for hardening **any** container you
put on a network, not just Minecraft.

## What changed, and why

| Hardening step | Lesson 11 (basic) | Lesson 12 (hardened) | Why it matters |
|---|---|---|---|
| Base image | `eclipse-temurin:21-jre-jammy` (full Debian userland) | `eclipse-temurin:21-jre-alpine` via a multi-stage build | Fewer installed tools = less an attacker can use if they get a shell |
| User | root (default) | dedicated `minecraft` user, fixed UID/GID 10000 | Root inside a container is the first domino in most container-escape chains ([08](../08-non-root-user/)) |
| Filesystem | fully writable | `read_only: true` + a `tmpfs` for `/tmp` | Even a successful exploit can't modify the image's own files or drop new executables anywhere but `/data` |
| Linux capabilities | full default set | `cap_drop: [ALL]` | The server needs zero special kernel privileges; don't hand out what isn't used |
| Privilege escalation | allowed | `security_opt: [no-new-privileges:true]` | Blocks a whole class of "gain more privileges than you started with" tricks |
| Resources | unlimited | `mem_limit`, `cpus`, `pids_limit` | A runaway or compromised process can't starve/crash the rest of the host |
| Secrets (RCON password) | n/a | injected at **run time** via `.env` → `entrypoint.sh`, never baked into the image | `docker history`/`docker inspect` on the image reveals nothing; only a *running* container that was given the secret has it |
| Download integrity | trust the URL | optional `MC_SERVER_SHA256` checksum verification during build | Detects a tampered/corrupted download before it ever runs |
| Healthcheck | none | `HEALTHCHECK` via `nc -z` on the game port | Docker (and you) can actually tell if the server has silently died |

None of this replaces keeping Minecraft itself patched and choosing trusted
mods/plugins — it limits the *blast radius* if something still goes wrong.

## Try it

Same as lesson 11: get `MC_VERSION` and `MC_SERVER_URL` from
<https://www.minecraft.net/en-us/download/server> (and read the EULA at
<https://www.minecraft.net/en-us/eula>). Optionally also grab the sha256
checksum shown on that page for `MC_SERVER_SHA256`.

```bash
cd 12-minecraft-server-hardened
cp .env.example .env
# edit .env if you want RCON enabled and/or a different JAVA_MEM

# edit docker-compose.yml, replacing the three REPLACE_ME build args
docker compose up --build
```

## Verify the hardening actually did something

```bash
# 1. Confirm it's not root
docker compose exec minecraft whoami
# -> minecraft

# 2. Confirm the filesystem is really read-only outside /data
docker compose exec minecraft sh -c "touch /test-file"
# -> touch: /test-file: Read-only file system

# 3. Confirm /data is still writable (the server can save the world)
docker compose exec minecraft sh -c "touch /data/test-file && rm /data/test-file && echo ok"
# -> ok

# 4. Confirm capabilities were actually dropped
docker inspect $(docker compose ps -q minecraft) --format '{{.HostConfig.CapDrop}}'
# -> [ALL]

# 5. Watch the healthcheck
docker compose ps
# STATUS column should show "(healthy)" once the server is up
```

## About the firewall

`docker compose up` publishing a port makes it reachable from your whole
network (and, if your machine has a public IP with no router/firewall in
front of it, the whole internet) - Docker's own port publishing bypasses a
lot of host firewalls by manipulating `iptables`/`nftables` directly. Before
running this anywhere other than your own laptop for testing:

- If the host has a firewall (e.g. `ufw`), scope access to only the
  network you actually want reaching it (e.g. your home LAN's subnet),
  not "anywhere," unless you deliberately want a public server.
- Never publish the RCON port (25575) beyond `localhost`/your LAN - it's a
  plaintext-password remote admin console for the server.
- Keep the checklist in mind any time you're about to expose a new port
  from a container to the world, on any project, not just this one.

## Backups

The whole point of the world living in the `mc-data` **volume**
([06](../06-volumes-and-persistence/)) instead of inside the container is
that you can back it up independently of the server software:

```bash
docker run --rm -v hello-docker-minecraft-hardened_mc-data:/data \
  -v "$(pwd)":/backup alpine \
  tar czf /backup/world-backup-$(date +%Y%m%d).tar.gz -C /data .
```

(Adjust the volume name to whatever `docker volume ls` actually shows for
this project - Compose prefixes it with the project/folder name.)

## Try it yourself

1. Try to `docker compose exec minecraft apk add curl` — it should fail:
   there's no writable place for `apk` to install to, *and* the
   `minecraft` user isn't root anyway, so it's blocked twice over.
2. Set `RCON_PASSWORD` in `.env`, recreate the container
   (`docker compose up -d --build`), then `docker compose exec minecraft
   grep rcon /data/server.properties` to confirm it landed. Then check
   `docker history <image>` and confirm the password is **nowhere** in the
   image's build history.
3. Install [Trivy](https://github.com/aquasecurity/trivy) (a free
   open-source container image scanner) and run it against your built
   image: `trivy image hello-docker-minecraft-hardened-minecraft` (or
   whatever `docker images` shows) — see what known CVEs exist in the base
   image's packages, and whether newer base image tags fix them.
4. Try lowering `mem_limit` to something unreasonably small (e.g. `256m`)
   and watch what happens when the JVM can't get the memory it asked for
   via `-Xmx` — this is what resource limits protecting the *host* actually
   look like from the *container's* side.
5. Compare `docker image ls` between lesson 11's image and this one — the
   Alpine-based multi-stage build should be noticeably smaller.

## Where to go from here

You now have a real, reasonably hardened service running in Docker. Ideas
for extending this repo further on your own:

- Add a second Compose service for scheduled world backups (build on
  lesson 10's multi-service patterns).
- Look into Docker's `--read-only` + `secrets` support (Compose `secrets:`
  top-level key) as a more formal alternative to the `.env` approach here.
- Pin the base image by digest (`FROM eclipse-temurin:21-jre-alpine@sha256:...`)
  instead of just a tag, so a rebuild months from now can't silently pull a
  different image than the one you tested.
- Run this on a machine with a real firewall in front of it and practice
  the checklist above for real.
