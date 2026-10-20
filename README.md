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

Using **Podman** instead of Docker? See the [Podman Rosetta Stone](PODMAN.md):
the same lessons, command by command, and where the two differ.

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

### Security track: containers that can't be quietly changed

Lessons 15-19 go deeper on one question: *how do you make a container that
a buggy program, a tricked program, or an AI agent following a bad
instruction can't secretly rewrite, including its own logs?* Every lesson
has an "attack it" exercise you run twice, once with the protection off (the
attack works) and once with it on (it's blocked), plus a box listing what
the protection does **not** cover.

| # | Lesson | New concepts |
|---|--------|---------------|
| 15 | [walls-not-requests](15-walls-not-requests/) | rules vs permissions, code owned by root, attacking your own container |
| 16 | [lock-every-window](16-lock-every-window/) | `--read-only`, `--tmpfs` (`noexec`), `--cap-drop`/`--cap-add`, `no-new-privileges`, setuid |
| 17 | [logs-the-app-cant-erase](17-logs-the-app-cant-erase/) | a separate log keeper, `:ro` mounts, `docker network create`, `docker logs`, logging drivers |
| 18 | [tamper-evident-logbook](18-tamper-evident-logbook/) | SHA-256 fingerprints, hash chains, checkpoints kept somewhere else |
| 19 | [pin-by-digest-and-honest-limits](19-pin-by-digest-and-honest-limits/) | tags vs image IDs vs digests, `FROM …@sha256:`, user namespaces, what Docker can't protect |

### A second capstone: a real game server

| # | Lesson | New concepts |
|---|--------|---------------|
| 20 | [nakama-game-server](20-nakama-game-server/) | a real open-source multiplayer server + its database as two Compose services, taking an upstream project's own Compose file and hardening it for public use |

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
docker images --digests                # registry fingerprints of your images    [19]
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
docker run --read-only --tmpfs /tmp NAME   # read-only, with a scratch folder   [16]
docker run --cap-drop ALL NAME         # no root superpowers                     [16]
docker run --security-opt no-new-privileges NAME  # setuid can't add power      [16]
docker run -v myvol:/data:ro NAME      # volume read-only                        [17]
docker run --rm sha256:IMAGE-ID       # run exactly this image, by fingerprint  [19]
docker pull NAME@sha256:DIGEST         # pull exactly this image from a registry [19]
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
├── 14-minecraft-server-hardened/
├── 15-walls-not-requests/            <- security track starts here
├── ...
├── 19-pin-by-digest-and-honest-limits/
├── 20-nakama-game-server/            <- second capstone: a real multiplayer server
└── PODMAN.md                         <- Docker -> Podman command guide
```

Work through the folders in order. Each lesson's README ends with a few
"try it yourself" exercises — do those before moving on; that's where the
actual learning happens.

## Where this goes next: from one box to a cluster

Lessons 01-19 are deliberately **single-machine Docker only** — that's the
whole point of the name. But almost everything here has a direct equivalent
one level up, when you start running containers across *more than one*
computer with an orchestrator like **k3s** (lightweight Kubernetes):

| You already know (Docker/Compose) | Becomes (Kubernetes/k3s) |
|---|---|
| a `docker-compose.yml` service | a **Deployment** (how many copies, what image, what restart policy) |
| Compose's private network + DNS-by-service-name (lesson 12) | a **Service** (same idea: call it by name, not IP) |
| a named volume (lesson 07) | a **PersistentVolume** / **PersistentVolumeClaim** |
| `-e VAR=value` / `.env` (lesson 05, 14) | a **ConfigMap** (plain values) or **Secret** (passwords, tokens) |
| `-p 8080:8000` (lesson 06) | an **Ingress** or a `NodePort`/`LoadBalancer` Service |
| `HEALTHCHECK` + `--restart` (lesson 11) | **liveness/readiness probes** + the Deployment's own restart behavior |
| `--read-only`, `--cap-drop`, `--user` (lessons 10, 16) | the same flags, now under a pod's `securityContext` |
| `docker compose up --scale counter=3` (lesson 12) | `kubectl scale deployment … --replicas=3` |

None of that is new *ideas* — it's the same questions ("where does this
save its data", "how do two services find each other", "what happens when
it crashes") asked about several machines acting as one instead of one
machine. That's why this repo deliberately stays **single-machine Docker
only** even with lesson 20 added: a cluster brings in its own machinery
(nodes joining, overlay networking, `kubectl`) that deserves its own
from-scratch numbered path the same way Docker got one — not a tacked-on
lesson in a repo titled "hello-docker". It also means that future repo
doesn't have to be public and generic the way this one is; it can talk
about real hosts and a real game.

Two things worth doing with what's already here before moving on:

- **Run lessons 11 and 13-14 for real**, end to end, with a current
  Minecraft server download — per `docs/session-notes.md` that was never
  actually verified, only built. Do this *before* trusting those Dockerfiles
  as the pattern for a containerized Minecraft service in a cluster.
- Fix the known bug in lessons 13-14: `server.jar` is stored inside the
  world volume, so rebuilding with a newer `MC_VERSION` silently keeps
  running the *old* jar. Move the jar outside `/data` first — the same
  "where does this save its data" question a PersistentVolumeClaim will
  ask again later, so it's worth getting right here first.
