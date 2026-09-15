# 13 — A real Minecraft server

## Goal

Put lessons 01-12 together into something you'll actually use: a working
vanilla Minecraft: Java Edition server running in Docker.

This lesson intentionally does **not** worry about security hardening yet —
it's "make it work" first. Lesson 14 takes this exact server and hardens it.

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
cd 13-minecraft-server-basic
docker compose up --build
```

The first boot generates the world and takes a minute or two — watch the
logs for `Done (...)! For help, type "help"`.

From another terminal or your Minecraft client, connect to
`localhost:25565` (or `<this-machine's-LAN-IP>:25565` from another device
on the same network).

## Running the server day to day

This is where the command-line skills from lessons
[03](../03-managing-containers-and-images/), [06](../06-exposing-ports/),
[07](../07-volumes-and-persistence/), and [12](../12-docker-compose-basics/)
pay off. Run all of these from the `13-minecraft-server-basic` folder.

### Start it in the background and watch it

```bash
docker compose up -d --build   # -d: give me my terminal back
docker compose logs -f         # watch it boot; Ctrl+C stops watching, not the server
docker compose ps              # STATUS "Up", PORTS 0.0.0.0:25565->25565/tcp
```

### Talking to the server console

```bash
docker compose attach minecraft
```

You're now attached to the server's console — type commands like `list`,
`say hello`, or `save-all` directly. To leave, detach with **`Ctrl+P` then
`Ctrl+Q`**. Don't press Ctrl+C here: it goes straight to the server and
shuts it down.

### Stopping it properly

```bash
docker compose stop     # saves the world, then stops. Start again with: docker compose start
docker compose down     # same, and also removes the container (the world volume stays)
```

Don't shut it down by typing `stop` in the console. The server would exit
cleanly — and then `restart: unless-stopped` would notice the container
stopped *without you asking Docker to stop it*, and start it right back up.
Restart policies only stand down for `docker stop` / `docker compose stop`.

Two details in this lesson's files make `docker compose stop` safe, both
straight from lesson 03's PID 1 discussion:

- The Dockerfile's `CMD` says `exec java ...`, so Java is PID 1 and actually
  receives the stop signal (and saves the world) instead of a shell that
  ignores it.
- `docker-compose.yml` sets `stop_grace_period: 1m`, so Docker waits up to
  a minute for the save instead of force-killing after 10 seconds.

### Poking around inside

```bash
docker compose exec minecraft sh              # a shell next to the running server
ls /data                                      # world/, server.properties, logs/, ...
tail -20 /data/logs/latest.log
exit
```

### Editing `server.properties`

The config file lives in the volume. Copy it out, edit it with your normal
editor, copy it back, restart:

```bash
docker compose cp minecraft:/data/server.properties ./server.properties
# edit ./server.properties — e.g. change motd= or difficulty=
docker compose cp ./server.properties minecraft:/data/server.properties
docker compose restart
```

### Where the world lives

```bash
docker volume ls | grep minecraft
# local     hello-docker-minecraft_mc-data
docker run --rm -v hello-docker-minecraft_mc-data:/data alpine:3.20 du -sh /data/world
```

The name is `<project>_<volume>`. The project name is fixed by the `name:`
line at the top of `docker-compose.yml` — without it, Compose would use the
folder name, and renaming the folder would quietly start you on an empty
world.

## Try it yourself

1. `docker compose down` then `docker compose up -d` again (no `--build`) —
   your world should still be there, because it lives in the `mc-data`
   named volume, not in the container. (`docker compose down -v` would
   delete the volume too. Don't.)
2. Bump `JAVA_MEM` in `docker-compose.yml` to `"2048M"` and restart —
   notice you didn't need to rebuild the image, just recreate the
   container, because `JAVA_MEM` is an `ENV` with a run-time override
   (lesson 05).
3. Look at `docker stats` while a friend or your Minecraft client is
   connected — watch CPU/memory usage live.
4. **LAN only.** Change the port line to `"127.0.0.1:25565:25565"`,
   `docker compose up -d`, and check that your own Minecraft client can
   still connect to `localhost` but a friend's computer on your network
   can't. Put it back when you're done (lesson 06).
5. **Predict, then test: a bind mount instead of the volume.** In
   `docker-compose.yml`, change `mc-data:/data` to `./data:/data` (lesson 08).
   *Before* running it, look at the Dockerfile: where did it put
   `server.jar` and `eula.txt`? Now `docker compose up` and read the error:
   `Unable to access jarfile server.jar`. The bind mount covered `/data` and
   hid everything the image had put there — and `ls -l data/` shows the
   folder is empty and owned by `root`. (A brand-new *named volume* behaves
   differently: the first time it's used, Docker copies the image's files
   into it. That's why the original setup works.) Switch back to
   `mc-data:/data`, remove the stray folder with
   `docker run --rm -v "$(pwd):/work" alpine:3.20 rm -rf /work/data`, and
   your world is still there.
6. Ask yourself: this server is running as `root` inside the container
   (check with `docker compose exec minecraft whoami`), the image still has
   `curl` and a full Debian userland installed, and there are no resource
   limits — if someone found a remote-code-execution bug in Minecraft
   itself, what could they do from inside this container? Keep that
   question in mind for lesson 14.

Next: [14-minecraft-server-hardened](../14-minecraft-server-hardened/) —
answer that question.
