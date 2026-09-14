# 04 — ARG vs ENV: making images configurable

## Goal

Stop hardcoding values. Learn the two ways to parameterize a Dockerfile, and
when to use each.

## New concepts

- **`ARG`** — a build-time-only variable. Set with `--build-arg` when
  running `docker build`. It does not exist inside the running container
  unless you also copy it into an `ENV`.
- **`ENV`** — a variable that's baked into the image and exists in every
  container started from it. Can still be overridden per-container with
  `docker run -e VAR=value`.
- The common pattern you see in this Dockerfile — `ARG X=default` then
  `ENV X=${X}` — gives you a value that has a sensible default, can be
  changed at build time (baking a different default into the image), *and*
  can still be overridden at run time without rebuilding anything.

## Try it

```bash
cd 04-environment-and-args

# 1. Build and run with the default
docker build -t greeter .
docker run --rm greeter
# -> Hello, World! (from inside a container)

# 2. Override at RUN time (no rebuild needed)
docker run --rm -e GREETING_NAME=Victor greeter
# -> Hello, Victor! (from inside a container)

# 3. Override at BUILD time (bakes a new default into the image)
docker build -t greeter-victor --build-arg GREETING_NAME=Victor .
docker run --rm greeter-victor
# -> Hello, Victor! (from inside a container)
```

## Try it yourself

1. Run `docker run --rm -e GREETING_NAME=Anthony greeter-victor` — does the
   run-time `-e` win over the build-time default? Why do you think that is?
2. Add a second `ARG`/`ENV` pair, e.g. `FAVORITE_MOB=Creeper`, and print it
   too. This is exactly the pattern the Minecraft lessons later use for
   things like server version and memory limits.
3. What happens if you reference an `ENV` variable in a `RUN` line, versus
   only inside the script that runs later? (Try `RUN echo "building for ${GREETING_NAME}"`
   right after the `ENV` line and watch the build output.)

Next: [05-exposing-ports](../05-exposing-ports/) — run something that
listens on the network.
