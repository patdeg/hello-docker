# 03 — Looking around: managing containers and images

## Goal

So far every `docker run` used `--rm`, so each container vanished the moment
it finished. Real containers — web servers, Minecraft servers — keep running
for days. Before building anything bigger, learn the everyday commands to:

- **see** what images and containers are on your machine,
- **get inside** a running container with a shell,
- **stop, start, and restart** a container,
- **remove** containers and images, and **clean up** safely.

There are no new Dockerfile instructions in this lesson. It's all about the
`docker` command itself — the part you'll type most often for the rest of
your life with Docker.

## The mental model

```
             docker build                 docker run
Dockerfile ───────────────►  IMAGE  ───────────────────►  CONTAINER
                               │                              │
                     docker image ls                   docker ps -a
                     docker image rm                   docker rm
```

A container moves through these states:

```
  docker run ──► running ──(stop / kill / program ends)──► exited ──docker rm──► gone
                    ▲                                        │
                    └────────────── docker start ────────────┘
```

The important part: **an exited container is not gone**. It still has its
filesystem and its logs, and it still uses disk space, until you `docker rm`
it. `--rm` just does that `docker rm` for you automatically.

## Build this lesson's image

```bash
cd 03-managing-containers-and-images
docker build -t ticker .
```

`ticker` prints a numbered line every 2 seconds, forever — a stand-in for any
long-running program.

## 1. What's on my machine?

```bash
docker image ls     # images            (older spelling: docker images)
docker ps           # RUNNING containers only
docker ps -a        # ALL containers, including stopped ones
```

Now run lesson 02's image twice, *without* `--rm`:

```bash
docker run custom-image
docker run custom-image
docker ps -a
```

```
CONTAINER ID   IMAGE          STATUS                     NAMES
b835cb04fbd2   custom-image   Exited (0) 3 seconds ago   nervous_joliot
5e1ca6d1d1c4   custom-image   Exited (0) 5 seconds ago   quirky_wozniak
```

Two leftover containers, with random names. Each `docker run` created a
*new* container (notice the hostname it printed was different each time).
Nothing removes them until you do — this is how people end up with hundreds.

Give a container a name so you don't have to copy IDs around:

```bash
docker run --name first-try custom-image
```

(A name can only be used by one container at a time — run that line twice
and read the error.)

> **Shared computer?** `docker ps -a` and `docker image ls` show *everything*
> on this machine, including containers and images that belong to other
> people or other projects. Look, but only remove things you know are yours.
> Section 8 shows how to clean up just your own stuff.

## 2. Run something in the background

```bash
docker run -d --name tick1 ticker
```

`-d` means **detached**: start the container and give me my terminal back.
Docker prints the new container's full ID and returns immediately.

```bash
docker ps                     # tick1 shows "Up 5 seconds"
docker logs tick1             # everything it has printed so far
docker logs --tail 3 tick1    # just the last 3 lines
docker logs -f tick1          # follow live output...
                              # ...Ctrl+C stops *following*, not the container
```

The container name (`tick1`) and the image name (`ticker`) are different
things. One image, many containers — you could start `tick2` and `tick3`
from the same image right now.

## 3. Get a shell inside a running container

This is the "sh into it" command — the one you'll use constantly to
investigate what's going on inside a container:

```bash
docker exec -it tick1 sh
```

Your prompt changes. You're now *inside* the container. Try:

```sh
hostname              # the container's ID, not your computer's name
ps                    # only a few processes: ticker.sh, sleep, your sh, ps
ls /
cat /etc/os-release   # Alpine Linux, even if your computer runs something else
exit
```

After `exit`, check `docker ps` — `tick1` is **still running**. `docker exec`
started a *second* process inside an already-running container; ending that
process doesn't touch the main one.

- `-i` keeps input open (so you can type), `-t` gives you a terminal (so you
  get a prompt). Without `-it`, `sh` has nothing to read and exits instantly.
- Alpine images have `sh`, not `bash`. Try `docker exec -it tick1 bash` and
  read the error: `exec: "bash": executable file not found in $PATH`.
  Debian/Ubuntu-based images usually do have `bash`.

You don't need a shell for a single command:

```bash
docker exec tick1 cat /ticker.sh
docker exec tick1 ls /
```

**`exec` vs `run`** — easy to mix up:

| | `docker exec` | `docker run` |
|---|---|---|
| Works on | an existing, *running* container | an image |
| Does | runs one more command inside it | creates a brand-new container |

So if you want a *fresh, throwaway* shell instead of entering an existing
container, use `run`:

```bash
docker run -it --rm ticker sh      # "sh" replaces the image's CMD
```

## 4. Stop, start, restart, kill

```bash
docker stop tick1       # polite: send SIGTERM, wait up to 10s, then force
docker ps -a            # tick1: "Exited (0)"
docker logs tick1       # last line: "ticker: got a stop signal, shutting down cleanly"

docker start tick1      # the SAME container runs again
docker logs tick1       # old lines are still there; the count restarts at 1

docker restart tick1    # stop + start in one command

docker kill tick1       # not polite: SIGKILL immediately, no cleanup
docker ps -a            # "Exited (137)"  (137 = 128 + 9, and 9 = SIGKILL)
```

Prefer `stop` over `kill`. A program that gets a chance to shut down cleanly
can save its work first — for a Minecraft server, that's the world.

**A stopped container keeps its filesystem:**

```bash
docker start tick1
docker exec tick1 sh -c 'echo "I was here" > /note.txt'
docker restart tick1
docker exec tick1 cat /note.txt     # -> I was here
```

The file survived a restart. But `docker rm` the container and start a new
one from the same image, and it's gone — the new container starts fresh
from the image. Making data survive *that* is lesson
[07](../07-volumes-and-persistence/).

### Why did `docker stop` only take a second, not 10?

Inside a container, your main program is **PID 1** (process number 1). Linux
treats PID 1 specially: it **ignores** stop signals like SIGTERM and SIGINT
unless the program explicitly says how to handle them. Plenty of programs
don't — so `docker stop` waits the full 10 seconds, gives up, and kills it.

`ticker.sh` has a `trap ... TERM INT` line that handles those signals, so it
exits right away. You'll prove this yourself in exercise 1 below. Remember
this — lesson 13 hits exactly this problem with the Minecraft server.

## 5. Copy files in and out

```bash
docker cp tick1:/note.txt ./note.txt           # container -> your computer
docker cp ./note.txt tick1:/copied-back.txt    # your computer -> container
docker exec tick1 ls /
```

Handy for grabbing a log or config file once. For files you want shared all
the time, lesson [08](../08-bind-mounts/) has a better tool.

## 6. Inspect: ask Docker for details

```bash
docker inspect tick1                          # everything, as a big JSON document
docker inspect -f '{{.State.Status}}' tick1   # just one field: running / exited
docker inspect -f '{{.Config.Cmd}}' ticker    # works on images too -> [/ticker.sh]
docker top tick1                              # its processes, as seen from your computer
docker stats --no-stream                      # CPU / memory used by each running container
```

## 7. Removing containers and images

**Containers:**

```bash
docker rm tick1
# Error response from daemon: cannot remove container "tick1": container is
# running: stop the container before removing or force remove

docker stop tick1 && docker rm tick1   # the normal way
docker rm -f tick1                     # stop + remove in one go
```

**Images:**

```bash
docker image rm ticker         # (short form: docker rmi ticker)
```

If *any* container still uses the image — even a stopped one — Docker
refuses:

```
Error response from daemon: conflict: unable to remove repository reference
"ticker" (must force) - container 22733363eb14 is using its referenced image
```

Find it with `docker ps -a`, remove that container first, then the image.
(`docker image rm -f` exists, but don't make forcing a habit — the error is
there to protect you.)

**Tags are just labels.** One image can have several:

```bash
docker tag ticker ticker:v1
docker image ls ticker       # two lines, SAME image ID
docker image rm ticker:v1    # prints "Untagged: ticker:v1" — only the label is gone
```

The image itself is only deleted when its last tag is removed.

## 8. Cleaning up — carefully

```bash
docker system df    # how much disk images, containers, volumes, build cache use
```

Docker has "prune" commands that delete in bulk:

```bash
docker container prune   # delete ALL stopped containers
docker image prune       # delete ALL untagged ("dangling") images
docker system prune -a   # delete almost everything not currently running
```

> ⚠️ **Prune commands act on the whole computer**, not just the lessons in
> this repo. On a machine shared with other people or other projects — or one
> that runs real services — `docker system prune -a` can wipe images that
> something else depends on. On your own laptop it's fine; anywhere else,
> clean up *by name* instead.

Cleaning up only your own things, using filters:

```bash
docker ps -a --filter ancestor=custom-image                # containers made from that image
docker rm $(docker ps -aq --filter ancestor=custom-image)  # remove exactly those
docker ps -a --filter name=tick                            # containers whose name contains "tick"
```

`-q` ("quiet") prints only the IDs, which is exactly what `docker rm` wants.

## Cheat sheet

| I want to... | Command |
|---|---|
| list images | `docker image ls` |
| list running containers | `docker ps` |
| list all containers | `docker ps -a` |
| run in the background | `docker run -d --name NAME IMAGE` |
| see output | `docker logs -f NAME` |
| open a shell inside | `docker exec -it NAME sh` |
| run a throwaway shell | `docker run -it --rm IMAGE sh` |
| stop / start / restart | `docker stop NAME` / `docker start NAME` / `docker restart NAME` |
| copy a file out | `docker cp NAME:/path ./here` |
| details | `docker inspect NAME` |
| remove a container | `docker rm NAME` (`-f` if running) |
| remove an image | `docker image rm IMAGE` |
| disk usage | `docker system df` |

## Try it yourself

1. **The 10-second mystery.** Delete the `trap` line from `ticker.sh`,
   rebuild, and run `docker run -d --name slow ticker`. Now
   `time docker stop slow` — about 10 seconds, and `docker ps -a` shows
   `Exited (137)`: it was killed, not stopped. Now try
   `docker run -d --init --name fast ticker` and `time docker stop fast`.
   `--init` puts a tiny helper in front of your program as PID 1, and it
   passes signals along properly. Put the `trap` line back when you're done.
2. **Ctrl+C.** Run `docker run -it --rm ticker` in the foreground and press
   Ctrl+C. It stops, thanks to the `trap`. (Without the trap, Ctrl+C would
   be ignored — same PID 1 rule.)
3. **Three at once.** Start three tickers:
   `for i in 1 2 3; do docker run -d --name tick-$i ticker; done`.
   List just them with `docker ps --filter name=tick-`, then remove all
   three with one command: `docker rm -f $(docker ps -aq --filter name=tick-)`.
4. **Rename** a running container: `docker rename tick1 clock`.
5. **Freeze time.** `docker pause tick1`, watch `docker logs -f tick1` stop
   moving, then `docker unpause tick1`. What does `docker ps` say while it's
   paused?
6. **Leave no trace.** When you're done with this lesson, get back to a
   clean state using only commands from this page: no `tick` containers
   left, no `custom-image` containers left. Check with `docker ps -a`.

Next: [04-installing-packages](../04-installing-packages/) — pull in
software that isn't part of the base image.
