# 01 — Hello, Docker

## Goal

Build your very first image and run it.

## What's in the Dockerfile

- `FROM alpine:3.20` — start from Alpine Linux, a tiny (~5 MB) Linux
  distribution. Every image is built on top of some base image; you rarely
  start from nothing.
- `CMD ["echo", "Hello, Docker world!"]` — the command that runs when a
  container starts. `CMD` sets the *default* command — you can still override
  it on the command line if you want.

## Try it

```bash
cd 01-hello-world

# Build the image and tag it "hello-world"
docker build -t hello-world .

# Run a container from it
docker run --rm hello-world
```

You should see:

```
Hello, Docker world!
```

`--rm` tells Docker to delete the container as soon as it exits, so you
don't pile up stopped containers while you're experimenting.

## What just happened?

1. `docker build` read the `Dockerfile`, downloaded the `alpine:3.20`
   **image** from Docker Hub (a public registry), and produced a new image
   called `hello-world`.
2. `docker run` created a **container** — a running instance of that image —
   executed `echo "Hello, Docker world!"` inside it, and exited.

An **image** is a read-only template (like a class). A **container** is a
running (or stopped) instance of it (like an object).

## Try it yourself

1. Run `docker images` — you should see both `hello-world` and `alpine`
   listed.
2. Override the default command: `docker run --rm hello-world echo "I did it myself"`.
   Notice the `CMD` in the Dockerfile was only a *default*.
3. Change the message in the Dockerfile, rebuild, and run it again.
4. Run `docker run --rm alpine echo "raw base image"` — you don't even need
   your own image to use `alpine` directly.

Next: [02-custom-image](../02-custom-image/) — package your own script
into an image instead of just running one command.
