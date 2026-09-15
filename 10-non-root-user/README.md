# 10 — Running as a non-root user

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
cd 10-non-root-user
docker build -t webserver-nonroot .
docker run --rm -d --name web2 -p 8080:8000 webserver-nonroot

docker exec web2 whoami
# -> app   (not root!)

curl http://localhost:8080/
docker stop web2
```

## Non-root, seen from the command line

```bash
docker run --rm -d --name web2 -p 8080:8000 webserver-nonroot

docker exec web2 id
# uid=100(app) gid=101(app) groups=101(app)

docker exec -it web2 sh     # your shell is ALSO the "app" user now
docker exec -u root web2 whoami
# root
```

`docker exec -u root` gets you a root shell in *any* container, whatever
its `USER` line says. That's handy for debugging — and it's a reminder that
**anyone who can run `docker` commands on a computer is effectively root on
it.** `USER` protects you from the app, not from people with Docker access.

Now look at the same process from your computer's side:

```bash
docker top web2 -o user,pid,args
# USER      PID     COMMAND
# dhcpcd    53128   python3 -m http.server 8000     <- (the name varies per computer)
```

Surprise: your computer may show some unrelated user name. Inside the
container, `app` is user number **100**; your computer looks up number 100
in *its own* user list and finds whoever happens to have it. User IDs are
just numbers, and names are a per-machine lookup. That's why the hardened
Minecraft server in lesson 14 picks a fixed, unusual number (10000) on
purpose. It's also what decides who owns files a container writes into a
bind mount (lesson [08](../08-bind-mounts/)).

```bash
docker stop web2
```

## Try it yourself

1. Compare with lesson 06's image: `docker run --rm webserver whoami`
   (no `USER` line there) — that one prints `root`.
2. Try to break it: add `RUN mkdir /etc/should-fail` *after* the `USER app`
   line, rebuild, and watch it fail with "Permission denied" — `app` can't
   write to `/etc`. Move the line back above `USER app` and it works,
   because it runs as root during the build at that point.
3. Look up `docker run --user`: even without changing the Dockerfile at
   all, you can force a container to run as a specific user/UID at run
   time. Try `docker run --rm --user 1000:1000 webserver id` against the
   *original* lesson-06 image. (`whoami` would say `unknown uid 1000`: the
   user number exists, it just has no name inside that image.)
4. Some images (like the official Minecraft-friendly `eclipse-temurin`
   base used later) don't create a non-root user for you — you'll do it
   yourself, exactly like this lesson, in [14-minecraft-server-hardened](../14-minecraft-server-hardened/).

Next: [11-healthchecks-and-restart-policies](../11-healthchecks-and-restart-policies/)
— teach Docker to notice when your app is broken.
