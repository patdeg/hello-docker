# 11 — A real Minecraft server

## Goal

Put lessons 01-10 together into something you'll actually use: a working
vanilla Minecraft: Java Edition server running in Docker.

This lesson intentionally does **not** worry about security hardening yet —
it's "make it work" first. Lesson 12 takes this exact server and hardens it.

## Before you start: get the server download link and read the EULA

Mojang requires anyone running a server to agree to their End User License
Agreement. Read it yourself: <https://www.minecraft.net/en-us/eula>. The
Dockerfile writes `eula=true` into `eula.txt` for you, but that's not a
substitute for actually reading it.

Then get the current server download:

1. Go to <https://www.minecraft.net/en-us/download/server>.
2. Right-click the `.jar` download link/button and choose "Copy Link
   Address" — this is your `MC_SERVER_URL`.
3. Note the version number shown on that page — this is your `MC_VERSION`.

Server jar URLs change with every Minecraft version, which is exactly why
the Dockerfile requires you to pass these in yourself with `--build-arg`
instead of a hardcoded link that would eventually break.

## Try it

Edit `docker-compose.yml` and replace both `REPLACE_ME` placeholders with
the version and URL you just copied. Then:

```bash
cd 11-minecraft-server-basic
docker compose up --build
```

The first boot generates the world and takes a minute or two — watch the
logs for `Done (...)! For help, type "help"`.

From another terminal or your Minecraft client, connect to
`localhost:25565` (or `<this-machine's-LAN-IP>:25565` from another device
on the same network).

## Talking to the server console

```bash
docker attach <container-name-from-"docker compose ps">
```

You're now attached to the server's console — type commands like `list`,
`say hello`, or `save-all` directly. **Do not press Ctrl+C** to leave (that
sends the interrupt signal and can stop the server); detach cleanly instead
with `Ctrl+P` then `Ctrl+Q`.

To shut the server down cleanly (saves the world properly first):

```bash
docker attach <container-name>
# type: stop
```

## Try it yourself

1. `docker compose down` then `docker compose up` again (no `--build`) —
   your world should still be there, because it lives in the `mc-data`
   named volume, not in the container.
2. Bump `JAVA_MEM` in `docker-compose.yml` to `"2048M"` and restart —
   notice you didn't need to rebuild the image, just recreate the
   container, because `JAVA_MEM` is an `ENV` with a run-time override
   (lesson 04).
3. Look at `docker stats` while a friend or your Minecraft client is
   connected — watch CPU/memory usage live.
4. Ask yourself: this server is running as `root` inside the container
   (check with `docker compose exec minecraft whoami`), the image still has
   `curl` and a full Debian userland installed, and there are no resource
   limits — if someone found a remote-code-execution bug in Minecraft
   itself, what could they do from inside this container? Keep that
   question in mind for lesson 12.

Next: [12-minecraft-server-hardened](../12-minecraft-server-hardened/) —
answer that question.
