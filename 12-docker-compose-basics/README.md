# 12 — Docker Compose basics

## Goal

Run more than one container together, defined declaratively, instead of
juggling long `docker run` commands and remembering to start things in the
right order.

## New concepts

- **`docker-compose.yml`** describes a set of **services** (each one maps
  to a container), how to build/run each one, and how they relate.
- Compose automatically creates a private network for your project and
  gives every service a **DNS name equal to its service name**. In this
  lesson, the `counter` service reaches the `web` service just by calling
  `http://web:8000/` — no IP addresses, no manual `docker network` commands.
- **`depends_on`** controls *start order* (it does **not** wait for the
  dependency to be "ready" — just started — that's what health checks from
  lesson 11 are for, in more advanced Compose setups).
- One `docker compose up` replaces a whole sequence of `docker build` /
  `docker run` / `docker network create` commands.

## Try it

```bash
cd 12-docker-compose-basics
docker compose up --build
```

Watch the logs: you'll see `counter`'s output interleaved with `web`'s,
each line prefixed with which service produced it. In another terminal:

```bash
curl http://localhost:8080/
```

Stop everything with `Ctrl+C`, then fully tear it down:

```bash
docker compose down
```

## Compose from the command line

Everything you learned in lesson [03](../03-managing-containers-and-images/)
has a Compose version. The difference: you use the **service name** from
`docker-compose.yml` (`web`, `counter`) instead of a container name, and
you run the commands from the folder that has the `docker-compose.yml`.

```bash
docker compose up -d --build     # start everything in the background (-d, like docker run -d)
docker compose ps                # what's running in THIS project
docker compose logs -f counter   # follow one service's output
docker compose exec web sh       # a shell inside the running "web" service
docker compose stop              # stop everything (containers are kept)
docker compose start             # start them again
docker compose restart counter   # restart just one service
docker compose down              # stop AND remove containers + the project network
```

| Plain Docker | Compose |
|---|---|
| `docker ps` | `docker compose ps` |
| `docker logs -f NAME` | `docker compose logs -f SERVICE` |
| `docker exec -it NAME sh` | `docker compose exec SERVICE sh` |
| `docker stop NAME` / `docker start NAME` | `docker compose stop` / `docker compose start` |
| `docker rm -f NAME` | `docker compose down` |
| `docker image ls` | `docker compose images` |

Notice `docker compose stop` takes about 10 seconds: both services' main
processes are PID 1 and ignore SIGTERM — lesson 03's rule again.

Compose containers are still normal containers — `docker ps` shows them
too, with names like `12-docker-compose-basics-web-1`.

> ⚠️ **`down` vs `down -v`.** `docker compose down` keeps named volumes.
> `docker compose down -v` deletes them as well. For the Minecraft server in
> lessons 13-14, `-v` means **deleting your world**. Don't add it out of habit.

## `docker run` flags → YAML

The `web` service in this lesson's `docker-compose.yml` uses both a port
mapping and a bind mount. Here's how the flags you already know translate:

| `docker run` flag | `docker-compose.yml` |
|---|---|
| `--name web` | the service name, `web:` |
| `-p 8080:8000` | `ports: ["8080:8000"]` |
| `-p 127.0.0.1:8080:8000` | `ports: ["127.0.0.1:8080:8000"]` |
| `-v mydata:/data` (named volume) | `volumes: ["mydata:/data"]` + a top-level `volumes: {mydata:}` |
| `-v "$(pwd)/web/www:/www:ro"` (bind mount) | `volumes: ["./web/www:/www:ro"]` |
| `-e NAME=value` | `environment: {NAME: value}` |
| `--restart unless-stopped` | `restart: unless-stopped` |
| `--user 1000:1000` | `user: "1000:1000"` |

Try the bind mount: with the project running, edit `web/www/index.html`,
save, and `curl http://localhost:8080/` — the new version is served
immediately, without `--build`.

## Try it yourself

1. `docker compose ps` (while it's running) — see both containers and how
   Compose named them (`<project>-<service>-<n>`).
2. `docker compose logs -f counter` — follow just one service's logs.
3. Scale the counter: `docker compose up --build --scale counter=3` — now
   three `counter` containers are all pinging the same `web` service.
   Compose load-balances requests made *to* `web` if you scaled it instead
   — try `--scale web=2` and see what `docker compose ps` shows (note:
   scaling `web` this way conflicts with the fixed `8080:8000` port mapping
   — that's a great real error message to read carefully).
4. Add a `HEALTHCHECK` to `web/Dockerfile` (from lesson 11) and a matching
   `depends_on: web: condition: service_healthy` under `counter` in the
   compose file — now `counter` genuinely waits for `web` to be healthy,
   not just started.

This is the exact structure lessons 13 and 14 use for the Minecraft server:
one `docker-compose.yml`, meaningful restart policies, and (in lesson 14)
resource limits and security options layered on top.

Next: [13-minecraft-server-basic](../13-minecraft-server-basic/) — put
everything so far together into a real, working Minecraft server.
