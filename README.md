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
| 03 | [managing-containers-and-images](03-managing-containers-and-images/) | `ps -a`, `logs`, `exec -it … sh`, `stop`/`start`, `rm`/`rmi`, `cp`, `inspect`, safe cleanup |
| 04 | [installing-packages](04-installing-packages/) | package managers in images, build cache, `docker history` |
| 05 | [environment-and-args](05-environment-and-args/) | `ENV`, `ARG`, `--build-arg`, `-e` |
| 06 | [exposing-ports](06-exposing-ports/) | `EXPOSE`, `-p`, `127.0.0.1` binding, `-P`, debugging unreachable ports |
| 07 | [volumes-and-persistence](07-volumes-and-persistence/) | `VOLUME`, named volumes, `docker volume …`, anonymous volumes |
| 08 | [bind-mounts](08-bind-mounts/) | sharing a folder with your computer, `:ro`, `--mount`, file ownership |
| 09 | [multi-stage-builds](09-multi-stage-builds/) | build stages, tiny final images, `--target` |
| 10 | [non-root-user](10-non-root-user/) | `USER`, why root-in-a-container is dangerous, UIDs |
| 11 | [healthchecks-and-restart-policies](11-healthchecks-and-restart-policies/) | `HEALTHCHECK`, `--restart` |
| 12 | [docker-compose-basics](12-docker-compose-basics/) | multi-container apps, `docker-compose.yml`, `docker compose …` |
| 13 | [minecraft-server-basic](13-minecraft-server-basic/) | putting it together: a real, working server |
| 14 | [minecraft-server-hardened](14-minecraft-server-hardened/) | security hardening, backups, capstone project |

## Why Minecraft?

A Minecraft server is a perfect capstone: it's a real long-running network
service (like anything you'd run in production), it's something you
personally care about keeping online, and "harden a server so strangers on
the internet can't break into it" is a genuinely useful skill — not just a
toy exercise.

Lesson 13 gets a vanilla server running in a container. Lesson 14 takes the
exact same server and asks: *what could go wrong, and how do we close each
hole?* — minimal base image, non-root user, read-only filesystem, dropped
Linux capabilities, resource limits, health checks, and a note on firewalling
the port. Those are the same questions you'd ask about any container you put
on the internet.

## Command cheat sheet

The number in brackets is the lesson that teaches it.

**Images**

```bash
docker build -t NAME .                 # build the image in this folder         [01]
docker image ls                        # list images                             [03]
docker image rm NAME                   # delete an image                         [03]
docker tag NAME NAME:v1                # add another tag (label) to an image     [03]
docker history NAME                    # the layers an image is made of          [04]
docker image inspect NAME              # all details (env, cmd, ...)             [05]
```

**Running containers**

```bash
docker run --rm NAME                   # run once, remove when it exits          [01]
docker run -it --rm NAME sh            # throwaway interactive shell             [03]
docker run -d --name x NAME            # run in the background, named "x"        [03]
docker run -e VAR=value NAME           # set an environment variable             [05]
docker run -p 8080:8000 NAME           # host port 8080 -> container port 8000   [06]
docker run -p 127.0.0.1:8080:8000 NAME # ...reachable from this computer only    [06]
docker run -v myvol:/data NAME         # named volume                            [07]
docker run -v "$(pwd)/dir:/data:ro" NAME   # bind mount a folder, read-only      [08]
docker run --user "$(id -u):$(id -g)" NAME # run as you, not root                [08]
docker run --restart unless-stopped NAME   # bring it back if it crashes         [11]
```

**Looking after containers**

```bash
docker ps                              # running containers                      [03]
docker ps -a                           # all containers, including stopped       [03]
docker logs -f x                       # follow a container's output             [03]
docker exec -it x sh                   # get a shell inside a running container  [03]
docker stop x / docker start x         # stop politely / start again             [03]
docker restart x                       # stop + start                            [03]
docker rm x   (-f if running)          # remove a container                      [03]
docker cp x:/path/file .               # copy a file out (or in)                 [03]
docker inspect x                       # all details                             [03]
docker stats                           # live CPU / memory                       [03]
docker port x                          # show its port mappings                  [06]
```

**Volumes**

```bash
docker volume ls                       # list volumes                            [07]
docker volume inspect myvol            # details, incl. where it's stored        [07]
docker volume rm myvol                 # delete it AND its data                  [07]
docker run --rm -v myvol:/data alpine:3.20 ls /data   # peek inside a volume     [07]
```

**Compose** (run from the folder with `docker-compose.yml`)

```bash
docker compose up -d --build           # build + start everything                [12]
docker compose ps                      # this project's containers               [12]
docker compose logs -f SERVICE         # follow one service                      [12]
docker compose exec SERVICE sh         # shell inside a service                  [12]
docker compose stop / start            # stop / start, keep containers           [12]
docker compose down                    # stop + remove containers (keeps volumes)[12]
```

**Cleaning up**

```bash
docker system df                       # what's using disk                       [03]
docker rm $(docker ps -aq --filter ancestor=NAME)   # remove only NAME's containers [03]
docker container prune / image prune   # bulk delete — WHOLE machine, careful!   [03]
```

## Repo layout

```
hello-docker/
├── 01-hello-world/
├── 02-custom-image/
├── ...
├── 13-minecraft-server-basic/
└── 14-minecraft-server-hardened/
```

Work through the folders in order. Each lesson's README ends with a few
"try it yourself" exercises — do those before moving on; that's where the
actual learning happens.
