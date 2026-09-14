# 09 — Health checks and restart policies

## Goal

Teach Docker to notice when your app is stuck or broken, and to bring it
back automatically.

## New concepts

- **`HEALTHCHECK`** in a Dockerfile defines a command Docker runs
  periodically *inside* the container. Its exit code decides the
  container's health status: `0` = healthy, anything else = unhealthy.
  - `--interval` — how often to check.
  - `--timeout` — how long a single check may run before it's considered
    failed.
  - `--start-period` — a grace period after startup during which failures
    don't count yet (your app might just be slow to boot).
  - `--retries` — how many consecutive failures before the container is
    marked `unhealthy`.
- **`docker run --restart`** — a *run-time* flag (not a Dockerfile
  instruction) that tells Docker's daemon what to do when a container
  stops. Common values: `no` (default), `on-failure`, `unless-stopped`,
  `always`.

Health checks and restart policies solve different problems: a health check
tells you (and Docker) *whether* something is wrong; a restart policy is
what actually *does* something about a crash. A hung-but-still-running
process (health check territory) is a different failure than a crashed
process (restart-policy territory) — you generally want both.

## Try it

```bash
cd 09-healthchecks-and-restart-policies
docker build -t webserver-health .
docker run -d --name web3 -p 8080:8000 --restart on-failure webserver-health

# Watch the health status change from "starting" to "healthy"
watch docker ps
# or just:
docker ps
```

The `STATUS` column should eventually show `Up ... (healthy)`.

## Try it yourself

1. `docker inspect --format='{{json .State.Health}}' web3` — see the raw
   health-check history Docker is keeping.
2. Kill the web server process *inside* the container without stopping the
   container itself: `docker exec web3 pkill -f http.server`. Watch
   `docker ps` — the container should flip to `unhealthy` within a couple
   of health-check intervals (but note: Docker does *not* automatically
   restart on an unhealthy status by itself — that's what an orchestrator
   like Compose's `restart` or Kubernetes would act on).
3. Now test the restart policy directly: `docker stop web3` (simulating a
   crash) is the wrong test since a manual `docker stop` doesn't trigger
   `--restart on-failure` — that's intentional, or you could never
   deliberately stop a container. Instead, kill the *container's* main
   process from outside: `docker kill --signal=SIGKILL web3`, then check
   `docker ps` again — it should be running again with a fresh container ID
   for the same name, restarted by the daemon.
4. Clean up: `docker stop web3 && docker rm web3`.

Next: [10-docker-compose-basics](../10-docker-compose-basics/) — run
several containers together instead of typing long `docker run` commands.
