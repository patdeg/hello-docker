# hello-docker

A hands-on path for learning Docker and Dockerfiles, one small step at a
time — starting from `echo "Hello, Docker!"` and ending with a **hardened
Minecraft server** you could actually run.

Each numbered folder is a self-contained lesson: a `Dockerfile` (or two), a
`README.md` explaining what's new and why, and things to try yourself. Do
them in order — each one builds on ideas from the last.

## Prerequisites

- Docker installed and running. Check with:
  ```bash
  docker --version
  docker run hello-world
  ```
- A terminal and basic comfort with `cd`, `ls`, editing text files.
- That's it. No prior Docker knowledge needed.

## The learning path

| # | Lesson | New concepts |
|---|--------|---------------|
| 01 | [hello-world](01-hello-world/) | `FROM`, `CMD`, `docker build`, `docker run` |
| 02 | [custom-image](02-custom-image/) | `COPY`, `RUN`, `ENTRYPOINT`, layers |
| 03 | [installing-packages](03-installing-packages/) | package managers in images, build cache |
| 04 | [environment-and-args](04-environment-and-args/) | `ENV`, `ARG`, `--build-arg`, `-e` |
| 05 | [exposing-ports](05-exposing-ports/) | `EXPOSE`, `-p`, running a real server |
| 06 | [volumes-and-persistence](06-volumes-and-persistence/) | `VOLUME`, `-v`, container vs. host filesystem |
| 07 | [multi-stage-builds](07-multi-stage-builds/) | build stages, tiny final images |
| 08 | [non-root-user](08-non-root-user/) | `USER`, why root-in-a-container is dangerous |
| 09 | [healthchecks-and-restart-policies](09-healthchecks-and-restart-policies/) | `HEALTHCHECK`, `--restart` |
| 10 | [docker-compose-basics](10-docker-compose-basics/) | multi-container apps, `docker-compose.yml` |
| 11 | [minecraft-server-basic](11-minecraft-server-basic/) | putting it together: a real, working server |
| 12 | [minecraft-server-hardened](12-minecraft-server-hardened/) | security hardening, capstone project |

## Why Minecraft?

A Minecraft server is a perfect capstone: it's a real long-running network
service (like anything you'd run in production), it's something you
personally care about keeping online, and "harden a server so strangers on
the internet can't break into it" is a genuinely useful skill — not just a
toy exercise.

Lesson 11 gets a vanilla server running in a container. Lesson 12 takes the
exact same server and asks: *what could go wrong, and how do we close each
hole?* — minimal base image, non-root user, read-only filesystem, dropped
Linux capabilities, resource limits, health checks, and a note on firewalling
the port. Those are the same questions you'd ask about any container you put
on the internet.

## Common commands cheat sheet

```bash
docker build -t <name> .          # build the image in the current folder
docker run --rm <name>            # run it once, clean up after
docker run -d --name x <name>     # run in the background, named "x"
docker ps                         # what's running
docker logs -f x                  # follow a container's output
docker exec -it x sh              # get a shell inside a running container
docker stop x && docker rm x      # stop and remove it
docker image ls                   # list images on this machine
docker image prune                # clean up dangling/unused images
```

## Repo layout

```
hello-docker/
├── 01-hello-world/
├── 02-custom-image/
├── ...
├── 11-minecraft-server-basic/
└── 12-minecraft-server-hardened/
```

Work through the folders in order. Each lesson's README ends with a few
"try it yourself" exercises — do those before moving on; that's where the
actual learning happens.
