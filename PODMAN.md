# The Podman Rosetta Stone

**If you know the Docker command, here's the Podman one, and where they
differ.**

> **How this page was checked:** the Docker commands were run for real while
> writing the lessons. The Podman commands were then **run for real** with
> **Podman 4.9.3, rootless**, on Ubuntu 24.04, on both an Intel/AMD
> (`amd64`) computer and an ARM (`arm64`) computer, and both gave the same
> results. That includes the whole security track (lessons 15-19). A few
> things could not be tried there; they are marked **(docs only, not run)**
> and come from the official documentation. Other Podman versions can
> differ a little. If something behaves differently on your machine, trust
> your machine, and tell us so we can fix the page.

## The 60-second version

- **Same images.** Docker and Podman both build and run standard **OCI**
  container images. An image built with one runs with the other, and on
  Google Cloud Run.
- **Same commands, mostly.** For almost everything in this repo you can type
  `podman` where a lesson says `docker`, and keep the rest of the line.
- **No daemon.** Docker has a background service (the *daemon*) that runs
  your containers. Podman doesn't: each `podman` command does the work
  itself, and your containers are ordinary processes that belong to you.
- **Rootless by default.** Podman normally runs as *you*, not as root.
  That's the big one, and it explains most of the differences below.

## The Rosetta table

| Docker | Podman | Notes |
|---|---|---|
| `docker run …` | `podman run …` | Same flags for everything in these lessons. |
| `docker ps` / `ps -a` | `podman ps` / `ps -a` | Same. |
| `docker images` / `image ls` | `podman images` / `image ls` | Same. |
| `docker build -t NAME .` | `podman build -t NAME .` | Same, incl. `-f`, `--build-arg`, `--target`. Podman also looks for a file called `Containerfile`. **See "HEALTHCHECK" below.** |
| `docker pull alpine:3.20` | `podman pull docker.io/library/alpine:3.20` | Use the **full name**. See "Short image names" below. |
| `docker push NAME` | `podman push NAME` | Same. (Pushing to a real registry: docs only, not run.) |
| `docker exec -it x sh` | `podman exec -it x sh` | Same, incl. `-u root`. |
| `docker logs -f x` | `podman logs -f x` | Same. |
| `docker stop x` / `start x` | `podman stop x` / `start x` | Same. |
| `docker rm x` / `rm -f x` | `podman rm x` / `rm -f x` | Same. |
| `docker rmi NAME` / `image rm` | `podman rmi NAME` / `image rm` | Same. |
| `docker volume create/ls/inspect/rm` | `podman volume create/ls/inspect/rm` | Same commands; volumes live in a different place (see below). |
| `docker network create/ls/rm` | `podman network create/ls/rm` | Same. Containers on a network **you created** find each other by name; the default network doesn't do names (same as Docker). |
| `docker inspect --format …` | `podman inspect --format …` | Same idea; a few fields differ (for example `.NetworkSettings.IPAddress` is empty in rootless Podman). |
| `docker tag A B` | `podman tag A B` | Same. |
| `docker login` | `podman login docker.io` | Same idea; name the registry. (Docs only, not run.) |
| `docker system prune` / `system df` | `podman system prune` / `system df` | Same. |
| `docker cp`, `port`, `top`, `stats`, `history` | `podman cp`, `port`, `top`, `stats`, `history` | Same. |
| `docker images --digests` | `podman images --digests` | Lesson 19. Podman's inspect also has a `.Digest` field. |
| `docker compose up -d` | `podman compose up -d` | **A separate tool does the work.** `podman compose` (Podman 4.7 and newer) is a thin wrapper that runs an installed compose program: `docker-compose` if you have it, otherwise `podman-compose` (a separate Python project). Install one of them first. |

### The `alias docker=podman` trick

```bash
alias docker=podman
```

Now the lessons' commands work as typed. Some Linux distributions also ship
a `podman-docker` package that installs a `docker` command which simply runs
`podman`. Limits:

- It only changes **what you type**. Programs that talk to the Docker
  *daemon* directly (some editors, some tools) need Podman's
  Docker-compatible socket turned on (`podman system service`, or the
  `podman.socket` systemd unit). (`podman-docker` and the socket: docs only,
  not run.)
- `docker compose` becomes `podman compose`, which still needs a compose
  program installed (see the table). We tested it with `docker-compose`
  installed; the `podman-compose` route is docs only, not run.
- Output looks slightly different, so a script that reads `docker`'s output
  word by word may need fixing.

## Differences that bite beginners

**Ports below 1024.** Rootless Podman can't publish ports under 1024 (like
80) unless an admin changes the `net.ipv4.ip_unprivileged_port_start`
setting. We tried `-p 80:80` and got
`rootlessport cannot expose privileged port 80`. The lessons use 8080 and
25565, so they're fine.

**File ownership on bind mounts (lesson 08).** In rootless Podman, *root in
the container is you* on the computer. Other user numbers in the container
are mapped to a private range of spare numbers (from `/etc/subuid`), so
files a non-root container user writes into a bind mount show up owned
by a strange number on your computer. We tried it: a file made by root in
the container belonged to us, and a file made by container user 1000
belonged to a big number like `100999`. Fixes:

- `--userns=keep-id` makes your own user number appear inside the
  container as itself (tested: the file came out owned by you).
- `podman unshare ls -ln DIR` shows the files the way the container sees them.

**SELinux labels (Fedora, RHEL and friends).** If a bind mount gives
"Permission denied" even though permissions look right, add `:z` (shared
between containers) or `:Z` (private to this container):
`-v "$(pwd)/www:/www:ro,Z"`. Docker understands the same suffixes. We only
had computers without SELinux: there Podman accepts `:z` and `:Z` and they
change nothing. The SELinux part is docs only, not run.

**No daemon, so restarts work differently (lesson 11).** `--restart` works
while things are running (tested: a container with `--restart
unless-stopped` kept coming back). Nothing brings containers back after the
computer reboots unless you enable `podman-restart.service`. In Podman 4.9
that service only restarts containers with `--restart always`, **not**
`unless-stopped`, so use `always` if you rely on it. For a real
long-running service, Podman recommends **Quadlet**: a small `.container`
file in `~/.config/containers/systemd/` that turns the container into a
systemd service. (`podman generate systemd` is the old way; it prints
"DEPRECATED".) Rebooting and Quadlet itself: docs only, not run.

**HEALTHCHECK (lesson 11).** `podman build` makes OCI-format images by
default, and the OCI format has no place to store a `HEALTHCHECK`, so it's
**ignored with a warning**. Tested: the warning says
`HEALTHCHECK is not supported for OCI image format and will be ignored`.
Build with `podman build --format docker …` to keep it; then
`podman ps` shows `(healthy)` like Docker does. `ONBUILD` and `SHELL` get
the same warning.

**Where volumes live (lesson 07).** Docker: `/var/lib/docker/volumes/`.
Rootless Podman: `~/.local/share/containers/storage/volumes/`. As always,
use `volume inspect` rather than poking at the folder.

**Short image names.** Docker always means Docker Hub when you write
`alpine:3.20`. Podman checks a list of registries from
`registries.conf`, and depending on your system's settings it may ask you
which one you meant, or refuse. On our Ubuntu computers a built-in list of
nicknames made `alpine` and `python` work, but `eclipse-temurin:21-jre`
was refused with `short-name ... did not resolve to an alias`. (The
"asks you which one" case: docs only, not run.) Writing the full name
avoids all of that:

```text
alpine:3.20                ->  docker.io/library/alpine:3.20
python:3.12-alpine         ->  docker.io/library/python:3.12-alpine
eclipse-temurin:21-jre     ->  docker.io/library/eclipse-temurin:21-jre
```

That works in `FROM` lines and in Docker too.

**Mac and Windows.** Containers need Linux, so both tools use a small Linux
virtual machine there. Docker Desktop hides it; with Podman you create it
once: `podman machine init`, then `podman machine start`. (Docs only, not
run.)

**Logs (lesson 17).** `podman logs` works, but Podman's log drivers are
`journald`, `k8s-file` (`json-file` is accepted as a name for it), `none`
and `passthrough`. Tested: all of those work, and the default on our
computers was `journald`. Docker's ship-it-to-another-computer drivers like
`syslog`, `gelf` and `fluentd` don't exist in Podman (tested: `invalid log
driver`); you'd ship the journal instead.

## The security track in Podman (lessons 15-19)

We ran all five lessons with `podman` in place of `docker`. The flags are
the same: `--user`/`-u`, `--read-only`, `--tmpfs`, `--cap-drop`,
`--cap-add`, `--security-opt no-new-privileges`, `:ro` mounts,
`FROM …@sha256:…`. Lessons 15, 17, 18 and 19 gave the same results as
Docker. Lesson 16 did not, and it's worth knowing why:

| Topic | Docker | Rootless Podman (tested) |
|---|---|---|
| Root in the container | the computer's root user, held back by locks | **you**, an ordinary user, on the computer |
| Default superpowers (capabilities) | 14 (`CapEff: 00000000a80425fb`) | 11: Docker's list minus `AUDIT_WRITE`, `MKNOD`, `NET_RAW` (`CapEff: 00000000800405fb`) |
| `--read-only` alone | everything read-only, including `/tmp` | also adds writable tmpfs on `/tmp`, `/var/tmp`, `/run`, `/dev`, `/dev/shm` (turn off with `--read-only-tmpfs=false`) |
| `--tmpfs /tmp` options | `noexec,nosuid,nodev` (seen in lesson 16) | `nosuid,nodev` only: **no `noexec`**, so programs saved in `/tmp` can run |
| Lesson 19's `uid_map` | `0 0 4294967295` (root is root) | for example `0 1000 1` then `1 100000 65536`: container 0 is your own user number |

What that means for lesson 16 in Podman:

- The "read-only only" step: attacks **2 and 3** both work, because `/tmp`
  stays writable. (Add `--read-only-tmpfs=false` and all three are blocked,
  like Docker.)
- The "line to remember" still lets **attack 2 work**, because Podman's
  `--tmpfs /tmp` doesn't add `noexec`. Ask for it yourself and every attack
  is blocked again (tested):

```bash
podman run --rm -i \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,nodev \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  hd-sec-house sh < attack.sh
```

  Docker's documentation uses the same longer `--tmpfs` spelling, so it's
  a good habit for both tools.
- The `CapEff` numbers are smaller (see the table). `--cap-drop ALL` still
  gives `0000000000000000`.

Rootless Podman already does what lesson 19 calls "user-namespace
remapping" and "rootless mode", without any setup. It still doesn't stop
the landlord: we could still rewrite the vault from lesson 19. Whoever owns
the user account owns those containers.

## Which one should I pick?

Honestly: **Docker is what most tutorials, books, and Google Cloud's own
docs use**, so when you're learning or following a guide, Docker means
fewer surprises. **Podman is a fine alternative and a great second tool**:
it's daemonless and rootless out of the box. Because both use the same images, nothing you
build is locked to either one. Learn the ideas in this repo once, and both
tools are yours.

## Google Cloud note

Google Cloud Run and Artifact Registry take standard images built by either
tool. Image names look like:

```text
REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE:TAG
```

Replace `REGION`, `PROJECT_ID` and `REPOSITORY` with your own (for example
`us-central1`). Log in and push:

```bash
# Docker
gcloud auth configure-docker REGION-docker.pkg.dev
docker tag my-app REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/my-app:v1
docker push REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/my-app:v1

# Podman (the login token lasts 60 minutes)
gcloud auth print-access-token | \
  podman login -u oauth2accesstoken --password-stdin REGION-docker.pkg.dev
podman tag my-app REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/my-app:v1
podman push REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/my-app:v1
```

(Podman can also reuse the `gcloud auth configure-docker` login.) Logging
in and pushing to Google Cloud: docs only, not run.

**One trap:** Cloud Run runs **`linux/amd64`** (Intel/AMD-style) images. If
your computer has an ARM chip (Apple Silicon Macs, Raspberry Pi and other
ARM boards), build for the right platform:

```bash
docker buildx build --platform linux/amd64 -t my-app .
podman build --platform linux/amd64 -t my-app .
```

Building for a different chip is slower, because it's emulated (with a
tool called QEMU). Docker Desktop on Mac and Windows sets that up for you; on
Linux, with either tool, the emulator may need to be installed first. We
saw this with Podman: building for another chip worked while the
Containerfile had no `RUN` line, but a `RUN` line failed with
`exec format error` because no emulator was installed.
