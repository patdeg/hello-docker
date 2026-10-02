# 16: Lock every window

## Goal

Lesson 15 ended with a problem: **root ignores file permissions.** If
anything in the container runs as root, or finds a way to *become* root,
the latched windows pop open. This lesson adds four locks that work no
matter who is inside, and you'll test each one by attacking it with the lock
off (it should **work**) and on (it should be **blocked**).

## The story

A latched window stops a visitor. But what if the person inside is the
landlord's cousin with a master key (root)? Then you need different locks:

| Lock | House version | Docker flag |
|---|---|---|
| Read-only house | the walls are concrete: nobody can paint them, not even the landlord | `--read-only` |
| A whiteboard for notes | there's one board for scribbles, but you can't plug a machine into it | `--tmpfs /tmp` |
| Take the master keys away | root still lives there, but without the superpowers | `--cap-drop ALL` (then `--cap-add` only what's needed) |
| No magic elevators | a button that says "become the landlord" just doesn't work | `--security-opt no-new-privileges` |

## New concepts

- **`--read-only`** makes the container's own filesystem (everything that
  came from the image) read-only. This is enforced by the Linux kernel, so
  it stops root too.
- **`--tmpfs /tmp`** gives the app a scratch folder that lives in memory and
  vanishes when the container stops. Docker mounts it `noexec` by default,
  which means programs saved there **can't be run directly**.
- **Capabilities.** Linux splits root's power into about 40 separate
  superpowers called *capabilities*: `CHOWN` (change who owns a file),
  `DAC_OVERRIDE` (ignore file permissions), `NET_BIND_SERVICE` (use ports
  below 1024), and so on. Docker gives a container root about 14 of them by
  default. `--cap-drop ALL` takes them all away; `--cap-add NAME` gives back
  only the ones your app really needs.
- **setuid programs** (like `sudo` or `doas`) start with root's power no
  matter who runs them. **`--security-opt no-new-privileges`** tells the
  kernel: nothing in this container may ever gain *more* power than it
  started with, so setuid stops working.

## Try it

```bash
cd 16-lock-every-window
docker build -t hd-sec-house .
docker run --rm hd-sec-house
# Beep boop. I am the friendly robot. I run as: robot
```

The image is lesson 15's robot plus one realistic mistake: someone installed
`doas` "for debugging" and wrote a rule letting the robot use it. Mistakes
like this are common. Locks are for the mistakes you don't know about.

`attack.sh` makes four break-in attempts:

1. rewrite the robot's program in `/app`
2. save a new program in `/tmp` and run it
3. use a root superpower (`chown`, change who owns a file)
4. climb from `robot` to `root` using `doas`

## Attack it, one lock at a time

**No locks, as root.** Everything should work (the control):

```bash
docker run --rm -i -u root hd-sec-house sh < attack.sh
# Attacker running as: root
#   [WORKED ] 1 rewrite the robot's program
#   [WORKED ] 2 drop a program in /tmp and run it
#   [WORKED ] 3 use a root superpower (chown)
#   [ n/a   ] 4 become root with doas (already root)
```

**Lock 1: read-only house.** Even root is blocked from changing `/app`:

```bash
docker run --rm -i -u root --read-only hd-sec-house sh < attack.sh
#   [BLOCKED] 1 rewrite the robot's program
#   [BLOCKED] 2 drop a program in /tmp and run it
#   [BLOCKED] 3 use a root superpower (chown)
```

Attacks 2 and 3 are blocked too, but only because `/tmp` is read-only now
and the attacker can't even create a file there. Real apps usually need
*somewhere* to scribble, so let's give it a whiteboard.

**Lock 2: a whiteboard that can't run programs.**

```bash
docker run --rm -i -u root --read-only --tmpfs /tmp hd-sec-house sh < attack.sh
#   [BLOCKED] 1 rewrite the robot's program
#   [BLOCKED] 2 drop a program in /tmp and run it
#   [WORKED ] 3 use a root superpower (chown)
```

Now `/tmp` is writable, but the attacker's program is refused with
`Permission denied` (that's the `noexec`). Attack 3 is back: root still has
its superpowers.

**Lock 3: take the master keys away.**

```bash
docker run --rm -i -u root --read-only --tmpfs /tmp --cap-drop ALL hd-sec-house sh < attack.sh
#   [BLOCKED] 1 rewrite the robot's program
#   [BLOCKED] 2 drop a program in /tmp and run it
#   [BLOCKED] 3 use a root superpower (chown)
```

You can see the superpowers as a number. `CapEff` means "effective
capabilities"; zero means none at all:

```bash
docker run --rm -u root hd-sec-house grep CapEff /proc/self/status
# CapEff:	00000000a80425fb      <- root's default superpowers
docker run --rm -u root --cap-drop ALL hd-sec-house grep CapEff /proc/self/status
# CapEff:	0000000000000000      <- none
```

If your app genuinely needs one power, give back just that one:

```bash
docker run --rm -i -u root --cap-drop ALL --cap-add CHOWN hd-sec-house sh < attack.sh
#   [WORKED ] 3 use a root superpower (chown)     <- only CHOWN came back
```

**Lock 4: no magic elevators.** Now run as the normal `robot` user, with no
locks. Watch attack 4:

```bash
docker run --rm -i hd-sec-house sh < attack.sh
# Attacker running as: robot
#   [BLOCKED] 1 rewrite the robot's program
#   [WORKED ] 2 drop a program in /tmp and run it
#   [BLOCKED] 3 use a root superpower (chown)
#   [WORKED ] 4 become root with doas              <- robot became root!
```

The robot was not root, but the leftover `doas` turned it into root. Now
add the lock:

```bash
docker run --rm -i --security-opt no-new-privileges hd-sec-house sh < attack.sh
#   [BLOCKED] 4 become root with doas
docker run --rm --security-opt no-new-privileges hd-sec-house doas id
# doas: not installed setuid      <- the kernel ignored doas's "start as root" bit
```

## All four locks together

This is the line to remember. The robot still works perfectly, and every
attack fails:

```bash
docker run --rm -i \
  --read-only --tmpfs /tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  hd-sec-house sh < attack.sh
# Attacker running as: robot
#   [BLOCKED] 1 rewrite the robot's program
#   [BLOCKED] 2 drop a program in /tmp and run it
#   [BLOCKED] 3 use a root superpower (chown)
#   [BLOCKED] 4 become root with doas

docker run --rm --read-only --tmpfs /tmp --cap-drop ALL \
  --security-opt no-new-privileges hd-sec-house
# Beep boop. I am the friendly robot. I run as: robot
```

> **Using Podman?** This line does *not* fully lock the house there:
> Podman's `--tmpfs /tmp` has no `noexec`, so attack 2 still works, and its
> `--read-only` leaves other scratch folders writable. Write
> `--tmpfs /tmp:rw,noexec,nosuid,nodev` (and add `--read-only-tmpfs=false`
> if you want those other folders locked too). Details in
> [PODMAN.md](../PODMAN.md#the-security-track-in-podman-lessons-15-19).

In a `docker-compose.yml` the same locks are written as `read_only: true`,
`tmpfs: [/tmp]`, `cap_drop: [ALL]` and
`security_opt: [no-new-privileges:true]`. That's exactly what the hardened
Minecraft server in lesson [14](../14-minecraft-server-hardened/) uses. Now
you know what each line does, and you've watched it work.

## What this does NOT protect against

> - **`noexec` is not a force field.** It stops `/tmp/evil` from running
>   *directly*, but `sh /tmp/evil` still works, because then the program
>   being run is `sh` (which lives in the read-only image) and the file is
>   just text it reads. Try it. `noexec` makes attacks harder, not impossible.
> - **Places you made writable on purpose.** A volume mounted at `/data` is
>   still writable, and the app can still scribble over its own data there.
>   That's next lesson's problem.
> - **Bugs in the Linux kernel itself.** All these locks are enforced by the
>   kernel. A kernel bug could break them, which is why you still keep your
>   computer updated.
> - **The computer's owner.** Whoever runs `docker` can simply start the
>   container again without the locks, or with `--privileged`. Locks protect
>   against the app, not against whoever controls Docker.

## Try it yourself

1. Run the four-lock command again but with `--cap-drop ALL` alone and
   `-u robot` (the default). Does `doas` still work? Why might dropping
   capabilities *also* break it? (Hint: what does doas need to do to turn
   you into root?)
2. Run `docker run --rm -u root --cap-drop ALL hd-sec-house sh -c 'echo x > /app/robot.sh'`
   **without** `--read-only`. It's blocked! Root normally ignores file
   permissions, but that power is itself a capability (`DAC_OVERRIDE`).
   Add `--cap-add DAC_OVERRIDE` and try again.
3. Try `sh /tmp/evil` under all four locks (see the box above). Then think:
   what else could you lock so that a tricked robot can't even run `sh`?
   (Hint: lesson [09](../09-multi-stage-builds/)'s `FROM scratch` image has
   no shell at all.)
4. **Quiz:** match each attack to the lock that stopped it: read-only,
   tmpfs `noexec`, cap-drop, no-new-privileges.

## Clean up

```bash
docker image rm hd-sec-house
```

Next: [17-logs-the-app-cant-erase](../17-logs-the-app-cant-erase/): the
robot's diary, kept by somebody else.
