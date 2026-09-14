# 03 — Installing packages

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
cd 03-installing-packages
docker build -t installing-packages .
docker run --rm installing-packages
```

You should see "Docker!" rendered in big ASCII-art letters.

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

Next: [04-environment-and-args](../04-environment-and-args/) — make images
configurable instead of hardcoding values.
