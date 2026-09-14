# 10 — Docker Compose basics

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
  lesson 09 are for, in more advanced Compose setups).
- One `docker compose up` replaces a whole sequence of `docker build` /
  `docker run` / `docker network create` commands.

## Try it

```bash
cd 10-docker-compose-basics
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
4. Add a `HEALTHCHECK` to `web/Dockerfile` (from lesson 09) and a matching
   `depends_on: web: condition: service_healthy` under `counter` in the
   compose file — now `counter` genuinely waits for `web` to be healthy,
   not just started.

This is the exact structure lessons 11 and 12 use for the Minecraft server:
one `docker-compose.yml`, meaningful restart policies, and (in lesson 12)
resource limits and security options layered on top.

Next: [11-minecraft-server-basic](../11-minecraft-server-basic/) — put
everything so far together into a real, working Minecraft server.
