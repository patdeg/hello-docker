# 20 — A real multiplayer game server (Nakama)

## Goal

[Nakama](https://github.com/heroiclabs/nakama) is a real, open-source game
server used by actual shipped games - matchmaking, chat, leaderboards,
storage, social features. It needs two containers instead of one (the
server, plus a database), which makes it a good second example of
everything lesson 12 taught about multi-container Compose projects, on top
of a service type (a game server) this repo hasn't covered yet.

This lesson has two parts, same weight as each other:

1. Get Nakama running at all.
2. **Harden it before anyone outside your own computer can connect** -
   this part is the main point of the lesson, not an afterthought.

## Part 1 — clone it, then update it

Nakama ships its own official Compose file at the root of its GitHub repo.
Go look at it before continuing:

```bash
curl -fsSL -o /tmp/nakama-upstream-compose.yml \
  https://raw.githubusercontent.com/heroiclabs/nakama/master/docker-compose.yml
cat /tmp/nakama-upstream-compose.yml
```

Two things you'll notice, both worth updating:

- **It uses CockroachDB, not Postgres.** Nakama's own README says the
  server "requires CockroachDB or another Postgres wire-compatible server
  as its database" - Postgres is explicitly supported, just not what the
  upstream example picked. This lesson's `docker-compose.yml` swaps in
  plain `postgres:16-alpine`, which is the more familiar database for
  anyone who's done lessons 12-14.
- **It points `nakama`'s image at `registry.heroiclabs.com`**, Heroic
  Labs' own registry. At the time this lesson was written that registry
  returned `401 Unauthorized` on an anonymous pull check - it looks geared
  at their paid/enterprise customers now. This lesson uses the public
  `heroiclabs/nakama` image on Docker Hub instead, which is still actively
  published and pulls fine anonymously.

That comparison - take the real upstream file, understand why each piece
is there, change what doesn't fit - is the actual skill. The
`docker-compose.yml` in this folder is the result, already hardened; don't
just use it without reading it.

## Setup

```bash
cd 20-nakama-game-server
cp .env.example .env
# edit .env: set POSTGRES_PASSWORD, NAKAMA_SERVER_KEY, and a console
# username/password. Don't leave any of them blank or at an example value.

mkdir -p data/modules
sudo chown -R 10000:10000 data
# why: the nakama container runs as a dedicated non-root UID (see the
# "Why UID 10000" box below), and that UID must own the folder it's
# writing into on your host - same "who owns this file" question as
# lessons 08 and 10.

docker compose up -d
docker compose ps
# both services should settle on "(healthy)" within ~30 seconds
```

> **Why UID 10000, and why you have to `chown` first.** The official
> Nakama image has no dedicated low-privilege user built in - run
> `docker run --rm --entrypoint sh heroiclabs/nakama:3.37.0 -c id` yourself
> and you'll see `uid=0(root)`. Lesson 10 already taught the fix: pick a
> UID yourself with `user:` in Compose. This lesson picked `10000:10000`,
> the same convention lesson 14 used for Minecraft. The catch, discovered
> by actually running this: with `cap_drop: [ALL]` in place, even root
> loses `CAP_DAC_OVERRIDE` - the capability that normally lets root ignore
> ordinary Unix file permissions - so skipping the `chown` step produces
> `mkdir /nakama/data/modules: permission denied` even though the process
> "is" root. Running as a real, deliberately-chosen non-root user avoids
> that trap entirely, which is itself the better lesson: don't lean on
> root's permission-bypassing power even when it's available, design so
> you don't need it.

## Verify it's actually working

```bash
# 1. Confirm it's not root
docker compose exec nakama id
# -> uid=10000 gid=10000

# 2. The HTTP/WebSocket API is up
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:7350/
# -> 200

# 3. The admin console is up (browser: http://127.0.0.1:7351)
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:7351/
# -> 200

# 4. Postgres has NO published host port - confirm nothing outside this
#    Compose project can reach it directly
docker compose ps postgres
# PORTS column should show "5432/tcp", never "0.0.0.0:5432->5432/tcp"
```

## Part 2 — Opening this to strangers on the internet

### The setup above is deliberately closed. Read this whole section before you change that.

Everything in `docker-compose.yml` right now is bound to `127.0.0.1` -
reachable only from the computer running it, exactly like lesson 06's
first warning about `-p 8080:8000` vs `-p 127.0.0.1:8080:8000`. A real
multiplayer game needs the two **game** ports reachable from other
people's devices. Getting from "works on my machine" to "strangers can
play" safely is a specific, ordered set of decisions - not just deleting
`127.0.0.1:` from the compose file.

| Port | What it is | Who should ever reach it |
|---|---|---|
| 7349 | gRPC API | players' game clients |
| 7350 | HTTP / WebSocket API | players' game clients (most client SDKs use this one) |
| 7351 | **Admin console** | **you, from your own network - never the public internet** |
| 5432 (Postgres) | the database | nothing outside this Compose project, ever - not even you from outside |

**Step-by-step, in order:**

1. **Change every secret in `.env` away from any example/default value**
   first. `NAKAMA_SERVER_KEY` is embedded in every game client that talks
   to your server - treat leaking it like leaking an API key, and rotate
   it (edit `.env`, `docker compose up -d --force-recreate nakama`) if you
   ever suspect it has.
2. **Bind the two game ports to your machine's real LAN address, not
   `0.0.0.0`.** This repo's docs can't use your real IP (it's not public,
   generic content) - this lesson's instructions use `192.168.1.23` as a
   **placeholder** for whatever `ip addr` shows as your own machine's
   address. Edit `docker-compose.yml`:
   ```yaml
   ports:
     - "192.168.1.23:7349:7349"
     - "192.168.1.23:7350:7350"
     # 7351 (console) is NOT in this list - see step 4
   ```
   If you paste `192.168.1.23` literally without owning that address on
   your own machine, `docker compose up` fails loudly with something like
   `failed to bind host port 192.168.1.23:7350/tcp: cannot assign
   requested address` - that error is Docker correctly refusing to guess,
   not a bug.
3. **Decide the real "who from the internet can reach this" question on
   your router**, exactly as lesson 14 said for Minecraft: port-forward
   7349 and 7350 to this machine's LAN IP only once you actually mean to.
   Docker's own published-port rule runs *before* a host firewall like
   `ufw` sees the packet, so a `ufw deny` rule does **not** reliably block
   a port Docker has published - the router is the real gate here, not a
   host firewall rule.
4. **Never publish 7351 (the console) beyond `127.0.0.1`, under any
   circumstance.** It's a full admin panel - user accounts, server
   config, in-app purchase records if you wire any up. The moment it's
   reachable from anywhere but localhost, "strangers can play" has quietly
   become "strangers can administer." If you need console access from
   another device on your own LAN, reach it over SSH port-forwarding or a
   VPN into this machine - never by widening the `ports:` binding itself.
5. **Put real transport security in front of anything crossing the public
   internet.** Both game ports speak plaintext by default. The standard
   fix is the same one you'd use for any other web service: a reverse
   proxy (e.g. Caddy or nginx) terminating TLS in front of 7350, rather
   than trying to make Nakama itself handle certificates.
6. **The resource limits already in `docker-compose.yml`
   (`mem_limit`, `cpus`, `pids_limit`) are your protection against one
   compromised or simply overloaded game session taking down the whole
   host** - the exact reasoning lesson 14 used for Minecraft. Don't widen
   them "to be safe"; if the server is legitimately outgrowing them,
   that's a sizing decision to make deliberately, not a limit to quietly
   remove.

None of this replaces keeping the Nakama image itself updated, or
reviewing whatever server-side game logic you eventually load into it - it
limits the *blast radius*, same framing as lesson 14. "Harden a server so
strangers on the internet can connect to it safely" is the actual job
here, not a box to check once.

## Try it yourself

1. Confirm the lockout for yourself: with the console still bound to
   `127.0.0.1:7351`, try reaching it from a *different* device on your
   LAN (not the machine running Docker). It should fail to connect at
   all - that's the setting working, not a bug to "fix."
2. Rotate `NAKAMA_SERVER_KEY`: change it in `.env`, run
   `docker compose up -d --force-recreate nakama`, then confirm with
   `docker compose logs nakama` that it came up using the new value.
3. Run `docker history heroiclabs/nakama:3.37.0` and confirm none of your
   `.env` secrets appear anywhere in it - same check lesson 14 asked you
   to do for the RCON password.
4. Stop the stack (`docker compose stop`) and back up the `pg-data`
   volume using the same throwaway-container pattern lesson 14 used for
   the Minecraft world (`docker run --rm -v
   hello-docker-nakama_pg-data:/data:ro -v "$(pwd)":/backup alpine:3.20
   tar czf ...`).
5. Like lesson 19 taught: once you've picked a real Nakama version, pin
   `heroiclabs/nakama:3.37.0` by digest
   (`heroiclabs/nakama@sha256:...`) instead of just the tag, so a rebuild
   months from now can't silently pull a different image than the one you
   tested and opened to the internet.

## Where to go from here

- Load actual server-side game logic (Nakama calls these "runtime
  modules") into the `./data/modules` folder this lesson already mounts -
  that's the `count: 0` in the startup logs you can watch become nonzero.
- Compare this lesson's two-service pattern against lesson 12's
  `web`/`counter` example - same Compose ideas, a database instead of a
  second web service.
- If you outgrow one machine for this, see the top-level README's
  "Where this goes next" section on Kubernetes/k3s - running a game
  server and its database across *multiple* machines is exactly the kind
  of project that belongs there instead of here.
