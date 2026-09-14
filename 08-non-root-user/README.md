# 08 — Running as a non-root user

## Goal

Stop running container processes as `root`. This is one of the single
highest-value hardening steps for any container, including the Minecraft
server later.

## Why this matters

By default, unless a Dockerfile says otherwise, everything inside a
container runs as `root` — same username as the most powerful account on a
real Linux machine. Inside the container's own filesystem that's mostly
harmless *by itself*, but it's the first domino in a lot of real container
breakout chains: root inside the container plus some other misconfiguration
(a mounted host path, a kernel vulnerability, an overly generous capability)
adds up to root on the host. Running as an unprivileged user removes that
first domino even if everything else about your setup is imperfect.

## New concepts

- **`addgroup` / `adduser`** — Alpine's user-management commands (Debian
  uses `groupadd`/`useradd` instead).
- **`USER <name>`** — every instruction *after* this line in the Dockerfile,
  and the container's main process at run time, runs as that user instead
  of root.
- File ownership matters once you're not root: a non-root user can only
  read/write files it has permission to, so `chown` the files it needs
  *before* switching `USER`.

## Try it

```bash
cd 08-non-root-user
docker build -t webserver-nonroot .
docker run --rm -d --name web2 -p 8080:8000 webserver-nonroot

docker exec web2 whoami
# -> app   (not root!)

curl http://localhost:8080/
docker stop web2
```

## Try it yourself

1. Compare with lesson 05's image: `docker run --rm webserver whoami`
   (no `USER` line there) — that one prints `root`.
2. Try to break it: add `RUN mkdir /etc/should-fail` *after* the `USER app`
   line, rebuild, and watch it fail with "Permission denied" — `app` can't
   write to `/etc`. Move the line back above `USER app` and it works,
   because it runs as root during the build at that point.
3. Look up `docker run --user`: even without changing the Dockerfile at
   all, you can force a container to run as a specific user/UID at run
   time. Try `docker run --rm --user 1000:1000 webserver whoami` against
   the *original* lesson-05 image.
4. Some images (like the official Minecraft-friendly `eclipse-temurin`
   base used later) don't create a non-root user for you — you'll do it
   yourself, exactly like this lesson, in [12-minecraft-server-hardened](../12-minecraft-server-hardened/).

Next: [09-healthchecks-and-restart-policies](../09-healthchecks-and-restart-policies/)
— teach Docker to notice when your app is broken.
