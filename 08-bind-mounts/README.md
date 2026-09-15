# 08 — Bind mounts: sharing a folder with your computer

## Goal

Let a container use a folder that lives **on your computer** — so you can
edit files with your normal editor and the container sees the change
instantly, with no rebuild. Then learn the traps that come with it:
root-owned files, typos that silently create the wrong thing, and giving a
container more access than it should have.

## Volume or bind mount?

Lesson 07 used a **named volume**: Docker decides where the data lives, and
you mostly don't look at it directly. A **bind mount** is the opposite: *you*
choose an exact folder on your computer, and it appears inside the container.

| | Named volume (lesson 07) | Bind mount (this lesson) |
|---|---|---|
| Syntax | `-v mydata:/data` | `-v "$(pwd)/my-site:/www"` |
| Where the files live | somewhere Docker manages | the exact folder you name |
| Best for | data the *app* owns: databases, world saves | files *you* work on: source code, web pages, configs |
| Starts out | empty (or copied from the image) | whatever is already in your folder |
| Portable to another computer | yes | only if that folder exists there too |

Both are "mounts": a folder from *outside* the container, plugged in at a
path *inside* it.

## Try it

```bash
cd 08-bind-mounts
docker build -t site .
```

**First, no mount** — the page baked into the image:

```bash
docker run -d --rm --name site1 -p 8080:8000 site
curl http://localhost:8080/        # "I was baked into the image"
docker stop site1
```

**Now with a bind mount** — same image, but your `my-site/` folder is
plugged in over `/www`:

```bash
docker run -d --name site2 -p 8080:8000 -v "$(pwd)/my-site:/www" site
curl http://localhost:8080/        # "I live on YOUR computer"
```

Open `my-site/index.html` in your editor, change the heading, save, and run
`curl` again (or refresh your browser). The change is live. No
`docker build`, no restart. Compare that with lesson 06, where every edit
meant a rebuild.

`-v HOST_PATH:CONTAINER_PATH` — left side is your computer, right side is
inside the container. Same order as `-p HOST:CONTAINER` in lesson 06.

## What just happened to the baked-in page?

It's still inside the image — but the mount sits *on top of* `/www`, hiding
it completely. A bind mount doesn't merge folders; it covers whatever was at
that path. (That's also why mounting an empty folder over a path full of
important files breaks things.)

## It goes both ways

A bind mount isn't a copy. The container and your computer are looking at
the *same* folder:

```bash
docker exec site2 sh -c 'echo "written by the container" > /www/from-container.txt'
ls -l my-site/
```

```
-rw-rw-r-- 1 you  you  326 Sep 15 07:32 index.html
-rw-r--r-- 1 root root  24 Sep 15 07:32 from-container.txt
```

The file appeared on your computer — **owned by `root`**. The process in the
container runs as root (lesson [10](../10-non-root-user/) fixes that), so
anything it creates belongs to root on your computer too. On Linux, you
can't edit or even delete that file as yourself.

Delete it the same way it was made — from a container:

```bash
docker exec site2 rm /www/from-container.txt
```

And avoid the problem by running the command as *your* user ID instead:

```bash
docker exec -u "$(id -u):$(id -g)" site2 sh -c 'echo "mine" > /www/mine.txt'
ls -l my-site/mine.txt     # owned by you this time
rm my-site/mine.txt        # and you can delete it normally
```

`docker run --user "$(id -u):$(id -g)" ...` does the same for a whole
container.

(On Docker Desktop for Mac/Windows, file ownership is translated for you, so
you may not see the root problem there. You will on Linux servers — which is
where most containers actually run.)

## Read-only mounts: `:ro`

A web server only needs to *read* the pages. So don't let it write:

```bash
docker rm -f site2
docker run -d --name site3 -p 8080:8000 -v "$(pwd)/my-site:/www:ro" site

curl http://localhost:8080/                              # still works
docker exec site3 sh -c 'echo hacked > /www/index.html'
# sh: can't create /www/index.html: Read-only file system
```

If someone ever broke into that web server, they couldn't deface your pages
or plant files in your folder. **Default to `:ro`** and only drop it when the
container genuinely needs to write. This is the same idea as the read-only
filesystem in the hardened Minecraft server (lesson 14).

## Gotchas that bite everyone

### 1. Forgetting the path part creates a *volume*, not a bind mount

```bash
docker run --rm -v my-site:/www alpine:3.20 ls /www     # prints nothing!
docker volume ls                                       # ...there's a new volume called "my-site"
docker volume rm my-site
```

`my-site` without a `/` or `./` in front looks like a *volume name*, so
Docker quietly created an empty named volume. Always write a path:
`"$(pwd)/my-site"` or `./my-site`.

### 2. A typo in the host path silently creates an empty folder

```bash
docker run --rm -v "$(pwd)/my-stie:/www" alpine:3.20 ls /www     # typo: "stie"
ls -ld my-stie     # a new, empty, root-owned folder appeared
docker run --rm -v "$(pwd):/work" alpine:3.20 rmdir /work/my-stie   # clean it up
```

The longer `--mount` syntax refuses instead of guessing:

```bash
docker run --rm --mount type=bind,src="$(pwd)/my-stie",dst=/www alpine:3.20 ls /www
# docker: Error response from daemon: invalid mount config for type "bind":
# bind source path does not exist: .../my-stie
```

`--mount` is wordier but says exactly what it means — good for scripts:

```bash
docker run --rm --mount type=bind,src="$(pwd)/my-site",dst=/www,readonly alpine:3.20 ls /www
```

### 3. Quote `"$(pwd)"`

If any folder in your path has a space in it, an unquoted `$(pwd)` breaks
into two words and the command fails in confusing ways. Always quote it.
(In Windows PowerShell, use `"${PWD}/my-site:/www"` instead.)

## Using a container as a tool on your files

Bind mounts aren't only for servers. You can borrow a program from an image
and point it at your files without installing anything. Lesson 04's image
has `figlet`:

```bash
mkdir -p output
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd)/output:/output" \
  installing-packages \
  sh -c 'figlet "Bind mounts!" > /output/banner.txt'
cat output/banner.txt
```

The container existed for one second, did one job on your folder, and
cleaned up after itself. This is how a lot of people run compilers,
formatters, and converters.

## ⚠️ Be careful what you mount

A container with a bind mount has **full access to that folder** — as root,
unless you say otherwise. So:

- **Never** mount `/` (your whole computer) or your entire home folder into a
  container you don't completely trust.
- **Never** mount `/var/run/docker.sock` casually. That socket controls
  Docker itself; a container that has it can start new containers with your
  whole disk mounted — it's effectively root on your computer.
- Mount the **smallest** folder that does the job, and use `:ro` whenever
  you can.

## Clean up

```bash
docker rm -f site3
```

## Try it yourself

1. **Mount a single file.** Run
   `docker run --rm -v "$(pwd)/my-site/index.html:/tmp/page.html:ro" alpine:3.20 cat /tmp/page.html`.
   You can mount one file instead of a whole folder — useful for a single
   config file.
2. **Where did my edit go?** Start
   `docker run -d --name one -v "$(pwd)/my-site/index.html:/page.html" alpine:3.20 sleep 600`.
   Append a line with `echo "<!-- edit 1 -->" >> my-site/index.html` and check
   with `docker exec one tail -1 /page.html` — the container sees it. Now edit
   with `sed -i 's/YOUR/MY/' my-site/index.html` and check again: the
   container still shows the *old* text. `sed -i` (and many editors) save by
   writing a brand-new file and swapping it in, and a single-file mount stays
   attached to the old one. Mount the *folder* instead and this can't happen.
   Clean up with `docker rm -f one`.
3. **Compare with `docker cp`.** Copy `my-site/index.html` into a running
   container with `docker cp` (lesson 03), then edit the file on your
   computer. Does the container see the change? Why is this different from a
   bind mount?
4. **Who's inside?** Start a container with `-v "$(pwd)/my-site:/www"` and
   run `docker exec CONTAINER id`, then `ls -ln my-site/`. Compare the numbers.
   Try again with `--user "$(id -u):$(id -g)"` on `docker run`.
5. **Inspect the mounts.**
   `docker inspect -f '{{json .Mounts}}' site3` (while it's running) shows
   the type (`bind` or `volume`), source, destination, and whether it's
   read-write (`"RW": false` means `:ro` worked).

Next: [09-multi-stage-builds](../09-multi-stage-builds/) — build compiled
code without shipping the compiler.
