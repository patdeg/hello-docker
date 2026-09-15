# 11 — Health checks and restart policies

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
cd 11-healthchecks-and-restart-policies
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
2. **Make it unhealthy without crashing it.** Take away the server's
   permission to read its own files:
   `docker exec web3 chmod 000 /www`. The server is still running, but every
   request now gets an error — exactly the "running but broken" case. Watch
   `docker ps` — within about 30 seconds (3 failed checks, 10 seconds apart)
   it flips to `(unhealthy)`. Read why with the `docker inspect` command from
   exercise 1. Fix it with `docker exec web3 chmod 755 /www` and watch it
   return to `(healthy)`.

   Note that Docker did **not** restart the unhealthy container. Plain
   Docker only *reports* health; acting on it is the job of whatever manages
   your containers (a script, or an orchestrator like Kubernetes).

   (Why not just `docker exec web3 pkill -f http.server`? Try it — nothing
   happens. The server is PID 1, and PID 1 ignores signals it doesn't
   handle, as you saw in lesson [03](../03-managing-containers-and-images/).)
3. **Test the restart policy with a real crash.** Stopping a container
   yourself never triggers a restart — not `docker stop`, and not
   `docker kill` either. That's deliberate: otherwise you could never shut
   anything down. Try it:
   `docker kill web3`, then `docker ps -a` — it stays `Exited (137)`.

   To see `--restart` work, the program has to fail *on its own*. Run a
   container whose command crashes after 3 seconds:
   ```bash
   docker run -d --name crashy --restart on-failure webserver-health \
     python3 -c "import time; time.sleep(3); raise SystemExit(1)"
   ```
   Wait 15 seconds and check `docker inspect -f '{{.RestartCount}}' crashy`.
   Docker keeps bringing it back — the **same** container (same ID), started
   again, waiting a little longer between each attempt. Clean up with
   `docker rm -f crashy`.
4. Clean up: `docker rm -f web3`.

Next: [12-docker-compose-basics](../12-docker-compose-basics/) — run
several containers together instead of typing long `docker run` commands.
