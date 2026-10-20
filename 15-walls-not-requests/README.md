# 15: Walls, not requests

*First lesson of the **security track** (15-19): building containers that
can't be quietly changed from the inside.*

## Goal

Learn the difference between a **rule** (asking a program to behave) and a
**permission** (making it physically unable to misbehave). Then build a
container where the app cannot rewrite its own program, and prove it by
attacking it.

## The story: the unlatched window

Imagine a house with a note on the fridge: *"Please don't climb in through
the windows."* That's a **rule**. It works on people who read the note and
choose to obey it. A burglar doesn't read your fridge.

Now imagine the windows are **latched**. Nobody has to read anything or
choose anything: the window just doesn't open. That's a **wall**.

Programs are the same. You can write *"never change your own code"* in a
program's instructions, or in the prompt of an AI agent. But a program can
have a bug, or get tricked by a sneaky input, or an AI agent can follow a
bad instruction it read on a web page. When that happens, the rule is gone.
**A rule is a request. A permission is a wall.** In this track we build walls.

## New concepts

- **File ownership as a wall.** A file owned by `root` with permissions
  `a=r` (everybody can read, nobody can write) can be *read* and *run* by an ordinary user,
  but not changed.
- **Don't give the app its own keys.** Lesson [10](../10-non-root-user/)
  did `chown -R app:app /www`, which made sense for web pages. For the
  app's **program**, giving it ownership means it can rewrite itself. The
  app only needs to *read* its code.
- **`docker run -i … sh < attack.sh`** runs a script from *your* computer
  inside the container, as whoever the container runs as. It's how we'll
  "attack" every container in this track.

## Try it

```bash
cd 15-walls-not-requests

# Two versions of the same robot
docker build -t hd-sec-robot-open -f Dockerfile.unlatched .
docker build -t hd-sec-robot .

docker run --rm hd-sec-robot-open
# Beep boop. I am the friendly robot. I run as: root

docker run --rm hd-sec-robot
# Beep boop. I am the friendly robot. I run as: robot
```

Every name in this track starts with `hd-sec-`, so it's easy to find and
clean up later.

## Attack it

`attack.sh` pretends the robot got tricked. It tries three things it was
told never to do. First the **unlatched** robot. Here the attack **should
work**:

```bash
docker run --rm -i hd-sec-robot-open sh < attack.sh
# Attacker running as: root
#   [WORKED ] rewrite the robot's own program
#   [WORKED ] add a secret admin account
#   [WORKED ] drop a new file next to the program
# Now the robot says:
# I am an EVIL robot now
```

Now the **latched** robot. The same attack **should be blocked**:

```bash
docker run --rm -i hd-sec-robot sh < attack.sh
# Attacker running as: robot
#   [BLOCKED] rewrite the robot's own program
#   [BLOCKED] add a secret admin account
#   [BLOCKED] drop a new file next to the program
# Now the robot says:
# Beep boop. I am the friendly robot. I run as: robot
```

Same script, same commands. The only difference is the walls. Running the
attack *both ways* matters: if you only tested the latched robot, you
couldn't tell "blocked by the wall" from "the attack script is broken".
Scientists call the open version a **control**.

One more thing to notice: run `docker run --rm hd-sec-robot-open` again.
The robot is friendly again! The attack changed only that one throwaway
container (`--rm`), never the **image**. But a server that runs for weeks
in one container would stay evil until someone restarted it, and nobody
might notice.

## What this does NOT protect against

> - **Root in the container.** Try
>   `docker run --rm -i -u root hd-sec-robot sh < attack.sh`. Everything
>   works again: root ignores file permissions. Lesson
>   [16](../16-lock-every-window/) adds a wall that even root can't climb.
> - **People who can run `docker`.** Anyone who can type `docker` commands
>   on a computer can do anything on it (lesson 10). These walls protect
>   you from the *app*, not from the computer's owner.
> - **Writable places the app does need.** If the app saves data in
>   `/data`, it can mess up `/data`. We'll deal with that for logs in
>   lesson [17](../17-logs-the-app-cant-erase/).

## Try it yourself

1. **Undo the wall and watch it fall.** In `Dockerfile`, replace the
   `chmod` line with `RUN chown -R robot:robot /app` (the lesson-10 style),
   rebuild, and attack again. Which attacks work now, and which one is still
   blocked? Why is that one different? (Hint: who owns `/etc/passwd`?)
2. Run `docker run --rm hd-sec-robot ls -l /app/robot.sh`. Read the
   permissions: who owns it, and what can everyone else do?
3. Write your own line for `attack.sh`, for example "delete the robot's
   program" (`rm /app/robot.sh`). Predict the result on both robots
   *before* you run it.
4. **Quiz:** your friend says "I told my AI helper in its instructions to
   never delete files, so it's safe." Rule or wall? What would you change?

## Clean up

```bash
docker image rm hd-sec-robot hd-sec-robot-open
```

Next: [16-lock-every-window](../16-lock-every-window/): a read-only house,
a scratch pad that can't run programs, and taking away root's superpowers.
