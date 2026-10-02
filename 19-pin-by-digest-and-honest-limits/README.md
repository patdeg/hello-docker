# 19: Pin by digest, and the honest limits

## Goal

Two last ideas for the security track:

1. **Make sure you run the image you think you're running.** An image
   *name* like `alpine:3.20` can be moved to point at something else. An
   image *digest* can't. You'll swap an impostor in under a name and watch
   the digest catch it.
2. **Be honest about what all of this can't do.** Every wall in lessons
   15-18 protects you from the *app*. None of them protects you from
   whoever controls Docker on the computer. That's why the copy that
   matters lives somewhere else.

## The story: the sticky note and the fingerprint

A **tag** (`hd-sec-greeter:1.0`, `alpine:3.20`) is a sticky note on a
box. It's handy, but anybody can peel the note off and stick it on a
different box. Tomorrow `alpine:3.20` might mean a slightly different image
than today (a security update, usually a good thing!), or, if someone
tampered with it, a bad one.

A **digest** (`sha256:d9e853e8…`) is a **fingerprint of what's inside the
box**, the same SHA-256 idea as lesson 18's logbook. Change one byte of the
image and the fingerprint changes. You can't peel it off and stick it on
something else.

## New concepts

- **Image ID**: the fingerprint of an image *on your computer*:
  `docker image inspect NAME --format '{{.Id}}'`. You can run an image by
  its ID instead of its name.
- **Digest**: the fingerprint of an image *in a registry* (like Docker
  Hub). It's the same everywhere in the world, so you can write it in a
  Dockerfile: `FROM alpine@sha256:…`. `docker images --digests` shows it.
- **`ARG` before `FROM`**: lets you choose the base image at build time
  with `--build-arg`.

## Try it: the impostor

```bash
cd 19-pin-by-digest-and-honest-limits

docker build -t hd-sec-greeter:1.0 greeter
docker run --rm hd-sec-greeter:1.0
# Hello! I am the REAL greeter.

# Write down the real image's fingerprint
docker image inspect hd-sec-greeter:1.0 --format '{{.Id}}' > real-id.txt
cat real-id.txt
# sha256:573e1616459e...    (yours will differ)
```

Now an attacker (or just a careless rebuild) puts a different image under
the **same name**:

```bash
docker build -t hd-sec-greeter:1.0 evil-greeter
```

## Attack it

Run it **by name**. The attack **works**: same name, different box.

```bash
docker run --rm hd-sec-greeter:1.0
# Hello! I am the real greeter... (not really: I'm the IMPOSTOR)
```

Run it **by fingerprint**. The attack **fails**: you get exactly the image
you wrote down.

```bash
docker run --rm "$(cat real-id.txt)"
# Hello! I am the REAL greeter.
```

Nobody deleted the real image; they only moved the sticky note. The
fingerprint still points at the real one.

## Pinning a base image by digest

The same trick protects the `FROM` line. Find the digest of the `alpine:3.20`
you already tested:

```bash
docker images --digests alpine
docker image inspect alpine:3.20 --format '{{index .RepoDigests 0}}'
# alpine@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
```

(Yours may be different if your `alpine:3.20` was downloaded on a different
day. Use the one *your* computer prints.)

`pinned/Dockerfile` reads its base image from a build argument. Build it
pinned to that exact fingerprint:

```bash
DIGEST=$(docker image inspect alpine:3.20 --format '{{index .RepoDigests 0}}')
docker build -t hd-sec-pinned --build-arg BASE="$DIGEST" pinned
docker run --rm hd-sec-pinned
# Built on Alpine 3.20.10
```

**Control:** change the last character of the digest, as if someone handed
you a slightly different image, and try again:

```bash
docker build -t hd-sec-pinned-bad --build-arg BASE="${DIGEST%?}0" pinned
# ERROR: ... alpine@sha256:d9e8...4b6b0: not found
```

(If your digest already ends in `0`, use `1` instead.) No image in the
world has that fingerprint, so the build refuses rather than using
"something close".

In a real Dockerfile you write the digest straight into the `FROM` line,
usually together with the tag so humans can still read it:

```dockerfile
FROM alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
```

The trade-off: a pinned image **never updates by itself**, including for
security fixes. Pinning means *you* decide when to move to a new digest,
after testing it. That's a job, not a one-time setting.

## The honest limits: the landlord

Everything in this track keeps the **app** in its place. Now let's be the
**computer's owner** for a minute. Put something precious in a volume:

```bash
docker run --rm -v hd-sec-vault:/vault alpine:3.20 sh -c \
  'echo "robot broke a vase" > /vault/diary.txt'

# The robot, behind glass (lesson 17), can't touch it:
docker run --rm -v hd-sec-vault:/vault:ro alpine:3.20 rm /vault/diary.txt
# rm: can't remove '/vault/diary.txt': Read-only file system
```

But whoever runs `docker` decides which walls exist in the first place:

```bash
docker run --rm -v hd-sec-vault:/vault alpine:3.20 sh -c \
  'echo "robot was perfect" > /vault/diary.txt; cat /vault/diary.txt'
# robot was perfect

docker volume rm hd-sec-vault      # ...and now it's gone completely
```

That's not a bug in Docker. **Being able to run `docker` is being the
landlord** (lesson [10](../10-non-root-user/) said it first). The landlord
can mount anything read-write, use `docker exec -u root`, turn off every
lock with `--privileged`, or delete Docker's own logs.

You can even see how close container-root is to the real root. This file
shows how user numbers inside the container map to the computer's:

```bash
docker run --rm alpine:3.20 cat /proc/self/uid_map
#          0          0 4294967295
```

Read it as "container user 0 *is* computer user 0". On a normal Docker
setup, root in the container is the same user number as root on the
computer, held back only by the locks from lesson 16. Two Docker features
change that, and both need an adult with admin rights on the computer:

- **User-namespace remapping** (`"userns-remap": "default"` in Docker's
  `daemon.json`): container root becomes an unimportant user number on the
  computer. That `uid_map` line would then start with `0  100000` or
  similar.
- **Rootless Docker**: the whole Docker engine runs as an ordinary user, so
  even a full escape lands as that user, not root.

They make an escape from the *app* much less dangerous. They still don't
stop the landlord.

### So where does the real copy live?

**Somewhere the landlord of *this* computer doesn't control.** That's the
thread running through the whole track:

| Lesson | Wall | Who it stops | What still gets through |
|---|---|---|---|
| 15 | non-root user, code owned by root | the app rewriting itself | root inside the container |
| 16 | read-only, `noexec` tmpfs, cap-drop, no-new-privileges | root and setuid tricks inside the container | the computer's owner, kernel bugs |
| 17 | log keeper + `:ro` mount, `docker logs` | the app erasing its own diary | the keeper, the owner |
| 18 | hash chain + checkpoint kept elsewhere | quiet edits by anyone, even the owner | anything newer than your last checkpoint |
| 19 | pin by digest | swapped images under the same name | a bad image you pinned yourself |

The only thing on that list that survives the landlord is lesson 18's
checkpoint, and only because it's **not on this computer**. Real systems
do the same: logs are shipped to a different machine as they're written
(Docker's `--log-driver`, lesson 17), and checkpoints are kept where the
people being audited can't reach them.

## What this does NOT protect against

> - **A bad image you pinned on purpose.** A digest proves "same as
>   before", not "safe". Pin images you've checked (and scanned, like the
>   Trivy exercise in lesson 14).
> - **Missing updates.** Pinned images don't get security fixes until you
>   move the pin.
> - **Image IDs are local.** `real-id.txt` only means something on *your*
>   computer. To share a pin with someone else, use the registry digest.
> - **The landlord.** See above. Nothing inside one computer can fully
>   protect against the person who controls it.

## Try it yourself

1. Run `docker image ls`. Where did the real greeter go? Now run
   `docker image inspect "$(cat real-id.txt)" --format '{{.Id}} {{.RepoTags}}'`.
   It lost its sticky note (`[]` = no tags), but it's still there.
2. Pull by digest directly:
   `docker pull alpine@sha256:<your digest>`. Then try pulling with one
   wrong character. What's the error?
3. Put lesson 16's locks and this lesson's pin together: write a
   Dockerfile `FROM alpine:3.20@sha256:<your digest>` for lesson 15's
   robot, and run it with all four locks.
4. **Quiz:** for each of these, which lesson's wall helps, if any?
   (a) a tricked AI agent tries to delete its own log; (b) someone
   replaces `alpine:3.20` on your computer with a bad image; (c) the
   computer's owner wants to rewrite last week's log; (d) a program drops
   a virus in `/tmp` and runs it.

## Clean up

```bash
docker image rm hd-sec-greeter:1.0 "$(cat real-id.txt)" hd-sec-pinned
docker volume rm hd-sec-vault 2>/dev/null
rm -f real-id.txt

# Everything from the whole security track, in one go:
docker ps -aq --filter name=hd-sec-              # containers left over?
docker image ls --filter reference='hd-sec-*'    # images left over?
```

## You finished the security track

Look back at what you built: a robot that can't rewrite itself, a house
where even root can't change the walls, a diary the robot can't erase, a
logbook that shows any edit, and images you can prove are the ones you
tested. Plus an honest list of what each one can't do.

The big idea fits on a sticky note (keep this one, though):
**a rule is a request; a permission is a wall; and the copy that matters
lives somewhere else.**
