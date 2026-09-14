# 06 — Volumes and persistence

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
- **Bind mounts** (`-v /host/path:/data`) — you point directly at a folder
  on your machine. Useful when you want to see/edit the files yourself.

## Try it

```bash
cd 06-volumes-and-persistence
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

## Try it yourself

1. `docker volume ls` — find `hello-docker-log` in the list.
2. `docker volume inspect hello-docker-log` — find the actual path on your
   host machine where Docker is storing this data (on Linux, usually under
   `/var/lib/docker/volumes/...`).
3. Try a **bind mount** instead of a named volume:
   `docker run --rm -v "$(pwd)/mydata:/data" logger` — then look at
   `./mydata/log.txt` directly with a text editor on your host.
4. `docker volume rm hello-docker-log` deletes the named volume — the data
   is really gone this time. This is the real-world equivalent of deleting
   your Minecraft world save. Be careful with it.

This directly matters for the Minecraft lessons: the world save, player
data, and configs all live under `/data` in the container, backed by a
volume — so you can recreate, update, or rebuild the *server* container
without losing your *world*.

Next: [07-multi-stage-builds](../07-multi-stage-builds/) — build compiled
code without shipping the compiler.
