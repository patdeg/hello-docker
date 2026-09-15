# 07 — Volumes and persistence

## Goal

Understand why a container's filesystem is normally *thrown away* when the
container is removed, and how to make specific data survive.

## New concepts

- A container's filesystem is a throwaway layer on top of its image. Delete
  the container (`docker rm`), and anything it wrote is gone.
- **`VOLUME /data`** in a Dockerfile marks `/data` as a directory that's
  meant to hold data outside the container's own lifecycle.
- **Named volumes** (`docker volume create`, or just `-v myvolume:/data`) —
  Docker manages the storage for you, on the host, independent of any one
  container.
- `-v NAME:/path` on `docker run` — plug the volume called `NAME` into the
  container at `/path`. If the volume doesn't exist yet, Docker creates it,
  and fills it with whatever the image already had at `/path`.
- (There's a second kind of mount, the **bind mount**, which uses a folder
  on your own computer instead. That's the whole of lesson
  [08](../08-bind-mounts/).)

## Try it

```bash
cd 07-volumes-and-persistence
docker build -t logger .

# WITHOUT a volume: each run starts from a clean slate
docker run --rm logger
docker run --rm logger
# both runs print only ONE line — nothing persisted between them

# WITH a named volume: data survives across separate `docker run`s
docker run --rm -v hello-docker-log:/data logger
docker run --rm -v hello-docker-log:/data logger
docker run --rm -v hello-docker-log:/data logger
# now you should see the log growing to 3 lines
```

## Managing volumes

Volumes have their own set of commands, just like images and containers
(lesson [03](../03-managing-containers-and-images/)):

```bash
docker volume ls                        # list all volumes
docker volume inspect hello-docker-log  # details, including where it lives
docker volume create my-new-volume      # create one ahead of time (optional)
docker volume rm my-new-volume          # delete one — and all its data
```

**Peek inside a volume** without the app that uses it — borrow any small
image and mount the volume into it:

```bash
docker run --rm -v hello-docker-log:/data alpine:3.20 ls -l /data
docker run --rm -v hello-docker-log:/data alpine:3.20 cat /data/log.txt
docker run -it --rm -v hello-docker-log:/data alpine:3.20 sh    # look around, then exit
```

This trick is how you back up, inspect, or fix the data of a server that
isn't running — lesson 14 uses it to back up a Minecraft world.

**A volume in use can't be removed:**

```bash
docker run -d --name holder -v hello-docker-log:/data alpine:3.20 sleep 600
docker volume rm hello-docker-log
# Error response from daemon: remove hello-docker-log: volume is in use - [3db0dd10adb8...]
docker rm -f holder
```

**Read-only:** add `:ro` when a container only needs to read the data:

```bash
docker run --rm -v hello-docker-log:/data:ro alpine:3.20 sh -c 'echo hi >> /data/log.txt'
# sh: can't create /data/log.txt: Read-only file system
```

### The volumes you didn't ask for

This lesson's Dockerfile has `VOLUME /data`. If you run the image **without**
`-v`, Docker still creates a volume for `/data` — an *anonymous* one, with a
long random name instead of a real one:

```bash
docker run logger          # note: no --rm, no -v
docker volume ls           # a new volume with a name like 51ce9d6fa5b8...
```

`--rm` cleans up anonymous volumes along with the container. Without
`--rm`, they pile up quietly. To remove a container *and* its anonymous
volumes, use `docker rm -v`:

```bash
docker rm -v $(docker ps -aq --filter ancestor=logger)
```

(Named volumes are never deleted by `docker rm`, `-v` or not. That's on
purpose — they're the data you care about.)

> ⚠️ `docker volume prune` deletes volumes no container is using. Stop your
> Minecraft server, run a prune, and your world is gone. Remove volumes by
> name, and only when you mean it.

## Try it yourself

1. `docker volume ls` — find `hello-docker-log` in the list.
2. `docker volume inspect hello-docker-log` — find the actual path on your
   host machine where Docker is storing this data (on Linux, usually under
   `/var/lib/docker/volumes/...`). Try to `ls` that folder as your normal
   user — why doesn't it work? (Hint: who owns `/var/lib/docker`?)
3. Share one volume between two containers at the same time: start
   `docker run -d --name writer -v shared:/data alpine:3.20 sh -c 'while true; do date >> /data/clock.txt; sleep 1; done'`,
   then from a *second* container read it:
   `docker run --rm -v shared:/data alpine:3.20 tail -3 /data/clock.txt`.
   Clean up with `docker rm -f writer && docker volume rm shared`.
4. `docker volume rm hello-docker-log` deletes the named volume — the data
   is really gone this time. This is the real-world equivalent of deleting
   your Minecraft world save. Be careful with it.

This directly matters for the Minecraft lessons: the world save, player
data, and configs all live under `/data` in the container, backed by a
volume — so you can recreate, update, or rebuild the *server* container
without losing your *world*.

Next: [08-bind-mounts](../08-bind-mounts/) — share a folder from your own
computer with a container.
