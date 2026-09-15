# 04 — Installing packages

## Goal

Install software inside an image that the base image doesn't already have.

## New concepts

- Base images are minimal on purpose. Alpine ships with almost nothing —
  you install what you need with its package manager, `apk`.
- **Layers and the build cache**: each `RUN`/`COPY`/`ADD` instruction
  creates a new layer. Docker caches layers and reuses them on the next
  build if nothing that affects them changed — this is why `docker build`
  is fast the second time. Order your Dockerfile so things that change
  rarely (like installing packages) come *before* things that change often
  (like your own source code) — this way editing your code doesn't force a
  slow package reinstall on every build.

## Try it

```bash
cd 04-installing-packages
docker build -t installing-packages .
docker run --rm installing-packages
```

You should see "Docker!" rendered in big ASCII-art letters.

## See the layers

```bash
docker history installing-packages
```

```
IMAGE          CREATED         CREATED BY                                      SIZE
5b653bb8bc81   2 minutes ago   CMD ["figlet" "Docker!"]                        0B
<missing>      2 minutes ago   RUN /bin/sh -c apk add --no-cache figlet # b…   742kB
<missing>      5 months ago    CMD ["/bin/sh"]                                 0B
<missing>      5 months ago    ADD alpine-minirootfs-3.20.10-aarch64.tar.gz…   8.82MB
```

Read it bottom to top: the bottom two lines are the `alpine:3.20` base
image, then one line per instruction in *your* Dockerfile. `RUN apk add`
added 742 kB; `CMD` only changed settings, so it's 0 B. (`<missing>` just
means that layer doesn't have its own image ID — nothing is broken.)

`docker history` works on any image, including ones you downloaded — it's a
quick way to see how someone else built theirs.

## Where did my old image go?

Every time you change the Dockerfile and rebuild with the same `-t` name,
the *name* moves to the new image. The old image doesn't get deleted — it
just loses its name and becomes **dangling**:

```bash
docker image ls --filter dangling=true
# IMAGE      ID             DISK USAGE
# <none>     033b9895a8e3   9.56MB       (newer Docker versions say <untagged>)
```

Remove one you know is yours by its ID, e.g. `docker image rm 033b9895a8e3`.
(`docker image prune` removes *all* dangling images on the computer at once —
see the warning in lesson [03](../03-managing-containers-and-images/) before
using it on a shared machine.)

## Try it yourself

1. Run the same `docker build` command again. Notice it finishes almost
   instantly the second time — Docker reused the cached layers.
2. Touch/edit the Dockerfile's `CMD` line only (not the `RUN` line), rebuild,
   and watch the build log: the `apk add` step says `CACHED`, only the last
   layer rebuilds.
3. Look up what package manager other base images use:
   `apt-get`/`apt` (Debian/Ubuntu), `apk` (Alpine), `dnf`/`yum` (Fedora/RHEL).
   Try rewriting this Dockerfile with `FROM debian:12-slim` and
   `RUN apt-get update && apt-get install -y figlet && rm -rf /var/lib/apt/lists/*`
   — compare the final image size with `docker image ls`.
4. Why do we clean up `/var/lib/apt/lists/*` for Debian but not for Alpine's
   `apk add --no-cache`? (Hint: they solve the same problem — not leaving a
   stale package index baked into a layer — differently.)

Next: [05-environment-and-args](../05-environment-and-args/) — make images
configurable instead of hardcoding values.
