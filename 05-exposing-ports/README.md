# 05 — Exposing ports

## Goal

Run a real network service (a web server) inside a container and reach it
from your host machine's browser.

## New concepts

- **`WORKDIR`** — sets the working directory for subsequent instructions
  (and the default directory when the container starts), like `cd`.
- **`EXPOSE`** — documents which port the app inside the container listens
  on. It's metadata, not a firewall rule — it doesn't publish anything by
  itself.
- **`-p host_port:container_port`** on `docker run` — this is what actually
  maps a port on your machine to a port inside the container. Without it,
  the server is running but nothing on your host can reach it.

## Try it

```bash
cd 05-exposing-ports
docker build -t webserver .

# Map host port 8080 -> container port 8000
docker run --rm -d --name web -p 8080:8000 webserver

curl http://localhost:8080/
# or open http://localhost:8080/ in a browser
```

When you're done:

```bash
docker stop web
```

## Try it yourself

1. Run the container *without* `-p 8080:8000` and try `curl localhost:8080` —
   it should fail. This is the single most common "why can't I reach my
   container" mistake.
2. Run two containers from the same image on two different host ports at
   once: `-p 8080:8000` and `-p 8081:8000`. One image, multiple running
   instances.
3. Edit `www/index.html`, rebuild, and confirm you need to rebuild (and
   restart the container) to see the change — a running container doesn't
   see changes to the files that were `COPY`'d into its image.
4. `docker port web` shows you the port mapping for a running container.

This is the exact pattern the Minecraft server lessons use later, just with
port `25565` instead of `8000`.

Next: [06-volumes-and-persistence](../06-volumes-and-persistence/) — keep
data around after a container is removed.
