# 07 — Multi-stage builds

## Goal

Compile code inside Docker without shipping the entire compiler/toolchain in
your final image.

## New concepts

- A Dockerfile can have **multiple `FROM` lines**, each starting a new
  **stage**. Name a stage with `AS <name>`.
- **`COPY --from=<stage>`** copies files from an earlier stage into the
  current one — but *only* the files you explicitly copy come along.
  Everything else from that stage (compilers, package caches, source code)
  is left behind.
- **`FROM scratch`** is the literal empty image — zero files, not even a
  shell. Only works for fully static binaries (no dependencies at all).

## Try it

```bash
cd 07-multi-stage-builds
docker build -t hello-go .
docker run --rm hello-go
```

```bash
docker image ls hello-go
# compare the size to:
docker image ls golang:1.23-alpine
```

The `golang:1.23-alpine` builder image is several hundred MB (it contains an
entire compiler toolchain). `hello-go` should be just a few MB — it's
*only* the compiled binary.

## Why this matters

Smaller images:

- download and start faster,
- have a much smaller **attack surface** (no shell, no package manager, no
  compiler for an attacker to abuse if they ever get code execution inside
  your container),
- are cheaper to store and transfer.

This is a core hardening technique, and it's exactly what lesson 12
(hardened Minecraft server) uses: download/prepare the server in one stage,
copy only what's needed into a minimal final image.

## Try it yourself

1. Try `docker run --rm --entrypoint sh hello-go` — it should fail. There's
   no shell in `scratch`. Compare with `docker run --rm --entrypoint sh <the builder image>`.
2. Add a second function to `hello.go` that reads an environment variable
   and prints it (`os.Getenv("MY_VAR")`), rebuild, and run with
   `docker run --rm -e MY_VAR=hi hello-go`.
3. Change the final `FROM scratch` to `FROM alpine:3.20` instead, rebuild,
   and compare sizes again. `scratch` is more extreme than most real
   projects use — `alpine` is a common, more practical middle ground because
   it still gives you a shell and package manager for debugging.

Next: [08-non-root-user](../08-non-root-user/) — stop running your
containers as root.
