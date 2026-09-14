# 02 — Your own script in an image

## Goal

Put your own code inside an image, instead of just calling a command that's
already there.

## New concepts

- **`COPY <src> <dst>`** — copies files from your machine (the *build
  context*, i.e. this folder) into the image at build time.
- **`RUN <command>`** — runs a command *while building the image* and bakes
  the result into a new layer (here, marking the script executable).
- **`ENTRYPOINT`** vs **`CMD`** — both define what runs when the container
  starts. `ENTRYPOINT` is meant to be the fixed "main program"; anything you
  add after `docker run <image> ...` gets appended as arguments to it,
  instead of replacing it outright the way it would with `CMD`.

## Try it

```bash
cd 02-custom-image
docker build -t custom-image .
docker run --rm custom-image
```

Notice the hostname printed is a random-looking string — that's the
container's own hostname, a random ID, not your computer's.

## Try it yourself

1. Edit `hello.sh` to also print `$(uname -a)`, rebuild, and run it again.
2. Because we used `ENTRYPOINT` (not `CMD`), try:
   `docker run --rm custom-image extra args here` — what happens to those
   extra words? (Hint: `hello.sh` ignores its arguments, but they were
   still passed to it — check with `docker run --rm custom-image; echo $?`
   vs adding `echo "$@"` to the script.)
3. Remove the `RUN chmod +x` line, rebuild, and run it. You should get a
   "permission denied" error — this is a common real-world Docker mistake.
   Put the line back and confirm it works again.
4. Run `docker run --rm --entrypoint sh custom-image` to get an interactive
   shell instead of running the script — useful for poking around inside
   any image.

Next: [03-installing-packages](../03-installing-packages/) — pull in
software that isn't part of the base image.
