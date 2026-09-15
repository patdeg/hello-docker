# 06 — Exposing ports

## Goal

Run a real network service (a web server) inside a container and reach it
from your host machine's browser. Then learn port mapping properly: reading
it, choosing *who* can connect, and debugging the classic "it's running but I
can't reach it" problem.

## New concepts

- **`WORKDIR`** — sets the working directory for subsequent instructions
  (and the default directory when the container starts), like `cd`.
- **`EXPOSE`** — documents which port the app inside the container listens
  on. It's metadata, not a firewall rule — it doesn't publish anything by
  itself.
- **`-p host_port:container_port`** on `docker run` — this is what actually
  maps a port on your machine to a port inside the container. Without it,
  the server is running but nothing on your host can reach it.

## Try it

```bash
cd 06-exposing-ports
docker build -t webserver .

# Map host port 8080 -> container port 8000
docker run --rm -d --name web -p 8080:8000 webserver

curl http://localhost:8080/
# or open http://localhost:8080/ in a browser
```

Every request shows up in the server's log:

```bash
docker logs web
# 172.17.0.1 - - [15/Sep/2026 14:42:31] "GET / HTTP/1.1" 200 -
```

When you're done:

```bash
docker stop web
```

Notice that `docker stop` takes about **10 seconds** here. That's the PID 1
rule from lesson [03](../03-managing-containers-and-images/): the Python web
server doesn't handle SIGTERM, so Docker waits, then kills it. Exercise 5
fixes it.

## Port mapping in depth

### How to picture it

```
 your computer                          container "web"
 ─────────────────                      ─────────────────
 port 8080  ───────── -p 8080:8000 ───►  port 8000  (python http.server)
 (host side, LEFT)                       (container side, RIGHT)
```

- The **right** number must be the port the app *actually listens on inside
  the container*. You don't get to choose it on the command line — it's
  decided by the program (here, the `8000` in the Dockerfile's `CMD`).
- The **left** number is yours to pick. Any free port on your computer works.

### Reading the mapping

```bash
docker run --rm -d --name web -p 8080:8000 webserver
docker ps
# ... PORTS                      NAMES
# ... 0.0.0.0:8080->8000/tcp     web

docker port web
# 8000/tcp -> 0.0.0.0:8080
```

`0.0.0.0:8080->8000/tcp` reads as: *every network address of this computer,
port 8080, forwards to port 8000/tcp in the container.*

### `0.0.0.0` means *everyone who can reach your computer*

By default, `-p 8080:8000` listens on **all** of your computer's network
connections — so other devices on your Wi-Fi can open
`http://<your-computer's-IP>:8080/` too. Sometimes that's what you want
(friends joining your Minecraft server). Often it isn't.

To allow **only your own computer**, put an address in front:

```bash
docker stop web
docker run --rm -d --name web -p 127.0.0.1:8080:8000 webserver
docker ps        # PORTS: 127.0.0.1:8080->8000/tcp
```

Now `curl http://localhost:8080/` works, but another device on your network
gets nothing. `127.0.0.1` (a.k.a. `localhost`) is your computer talking to
itself.

> ⚠️ **Docker can punch through your firewall.** On Linux, Docker writes its
> own network rules when it publishes a port, and those rules are checked
> *before* firewalls like `ufw`. A port published on `0.0.0.0` can be
> reachable even if `ufw` says it's blocked. Binding to `127.0.0.1` is the
> reliable way to keep something private. Lesson 14 comes back to this.

### When the host port is already taken

Only one program can use a host port at a time:

```bash
docker run --rm -d --name web2 -p 8080:8000 webserver
# docker: Error response from daemon: ... Bind for 0.0.0.0:8080 failed:
# port is already allocated
```

(If something *outside* Docker owns the port, the message says
`address already in use` instead.) Pick another host port — the container
side can stay the same:

```bash
docker run --rm -d --name web2 -p 8081:8000 webserver
```

Two containers, same image, both listening on 8000 *inside*, reachable on
8080 and 8081 *outside*. Every container has its own private set of ports.

### Let Docker pick: `-P`

```bash
docker run --rm -d --name web3 -P webserver
docker port web3
# 8000/tcp -> 0.0.0.0:32769
```

Capital `-P` publishes every port the image `EXPOSE`s, each on a random free
high port. This is the one place `EXPOSE` does more than document.

### TCP and UDP

Ports are TCP unless you say otherwise. Some programs use UDP — for example,
Minecraft **Bedrock** Edition servers listen on UDP 19132:

```bash
-p 19132:19132/udp
```

(Java Edition, which lessons 13-14 use, is plain TCP 25565.)

## Debugging "it's running, but I can't connect"

Work through these in order:

1. **Is it running?** `docker ps` — if it's not listed, `docker ps -a` and
   `docker logs NAME` will tell you why it exited.
2. **Is the port published?** Look at the `PORTS` column. Empty means you
   forgot `-p`.
3. **Is the right side correct?** `-p 8080:80` for an app listening on 8000
   gives `curl: (7) Failed to connect`. Check what the app really listens
   on.
4. **Does it work from inside?** Test *inside* the container, bypassing port
   mapping completely:
   ```bash
   docker exec web wget -qO- http://127.0.0.1:8000/
   ```
   If that works but `curl localhost:8080` doesn't, the problem is the
   mapping (steps 2-3) or step 5.
5. **Is the app listening only on its own `127.0.0.1`?** A program that binds
   to `127.0.0.1` *inside* the container accepts connections only from
   inside the container — port mapping can't reach it. It must listen on
   `0.0.0.0`. Try it:
   ```bash
   docker run --rm -d --name broken -p 8082:8000 webserver \
     python3 -m http.server 8000 --bind 127.0.0.1
   curl http://localhost:8082/                            # fails
   docker exec broken wget -qO- http://127.0.0.1:8000/    # works from inside!
   docker stop broken
   ```
   This one fools experienced people. Many dev servers default to
   `127.0.0.1`, so they need a `--host 0.0.0.0` or similar option in a
   container.

## Clean up

```bash
docker stop web web2 web3
```

(They were started with `--rm`, so stopping also removes them.)

## Try it yourself

1. Run the container *without* `-p 8080:8000` and try `curl localhost:8080` —
   it should fail. This is the single most common "why can't I reach my
   container" mistake.
2. Edit `www/index.html`, rebuild, and confirm you need to rebuild (and
   restart the container) to see the change — a running container doesn't
   see changes to the files that were `COPY`'d into its image. (Lesson
   [08](../08-bind-mounts/) shows how to skip the rebuild.)
3. Find your computer's LAN IP (`hostname -I` on Linux, or your network
   settings) and open `http://<that-IP>:8080/` from a phone on the same
   Wi-Fi. Then restart the container with `-p 127.0.0.1:8080:8000` and try
   the phone again.
4. Map the same container to two host ports at once:
   `docker run --rm -d --name multi -p 8080:8000 -p 9090:8000 webserver`,
   then `docker port multi`.
5. **Fix the slow stop.** Time it first: `time docker stop web`. Now two
   different fixes — try both:
   - Start it with `docker run --init ...` and time `docker stop` again.
   - Or add the line `STOPSIGNAL SIGINT` to the Dockerfile, rebuild, and
     time it. Python *does* handle SIGINT (it's what Ctrl+C sends), so
     Docker now asks in a language the server understands.

This is the exact pattern the Minecraft server lessons use later, just with
port `25565` instead of `8000`.

Next: [07-volumes-and-persistence](../07-volumes-and-persistence/) — keep
data around after a container is removed.
