# 17: Logs the app can't erase

## Goal

A **log** is a program's diary: what it did, and when. Logs are how you find
out what went wrong, and they're the first thing a misbehaving program (or a
tricked AI agent) would want to rewrite. In this lesson the robot writes its
diary through a channel it **cannot edit afterwards**, and you'll prove it by
trying to erase it.

## The story: the diary and the librarian

If you keep your diary in your own backpack, you can tear out a page and
nobody will ever know. A diary you can edit is not proof of anything.

So instead, every evening you **read your entry out loud to the librarian**,
who writes it into a book that stays in the library. You can come and *read*
the book any time, through the glass of a locked display case. But you
can't take it out, and you can't tear out pages, because the case is
locked and the librarian won't do it.

In Docker:

- the **librarian** is a separate container, the *keeper*, which is the only
  one with write access to the diary;
- **reading out loud** is sending lines over the network;
- the **glass case** is mounting the diary's volume into the robot
  **read-only** (`:ro`, lesson [08](../08-bind-mounts/)).

## New concepts

- **`docker network create`** makes a private network. Containers on it can
  reach each other by name, just like Compose services did in lesson
  [12](../12-docker-compose-basics/).
- **`nc` (netcat)** is a tiny tool that sends or receives lines over the
  network. The keeper uses `nc -lk -p 5140 -e append.sh` to listen; the
  robot uses `nc keeper 5140` to talk.
- **`-v VOLUME:/logs:ro`** mounts a volume read-only. The kernel enforces
  it, so even **root** inside the robot can't change anything there.
- **`docker logs`** is a second "librarian" you already have for free:
  anything a container prints is saved by Docker, *outside* the container.

## Try it

```bash
cd 17-logs-the-app-cant-erase
docker build -t hd-sec-keeper keeper
docker network create hd-sec-net

# Start the keeper FIRST, so it creates the diary volume with itself as the
# owner. And lock its windows with everything from lesson 16.
docker run -d --name hd-sec-keeper --network hd-sec-net \
  -v hd-sec-diary:/logs \
  --read-only --cap-drop ALL --security-opt no-new-privileges \
  hd-sec-keeper
```

Now the robot has a day. Each `nc` line is the robot reading one entry out
loud to the keeper:

```bash
docker run --rm --network hd-sec-net alpine:3.20 sh -c '
  echo "robot woke up"        | nc -w1 hd-sec-keeper 5140
  echo "robot broke a vase"   | nc -w1 hd-sec-keeper 5140
  echo "robot hid the pieces" | nc -w1 hd-sec-keeper 5140'
```

Read the diary through the glass case (a read-only mount):

```bash
docker run --rm -v hd-sec-diary:/logs:ro alpine:3.20 cat /logs/robot-diary.txt
# 2026-10-02T17:14:41Z robot woke up
# 2026-10-02T17:14:41Z robot broke a vase
# 2026-10-02T17:14:41Z robot hid the pieces
```

The keeper added the time itself. The robot didn't get to choose it.

## Attack it

`attack.sh` is the robot trying to hide the vase. It runs as **root** (the
default for `alpine`), with the diary behind glass. It **should be blocked**:

```bash
docker run --rm -i -v hd-sec-diary:/logs:ro alpine:3.20 sh < attack.sh
# Attacker running as: root
#   [BLOCKED] rewrite an old entry
#   [BLOCKED] erase the whole diary
#   [BLOCKED] delete the diary file
# Diary now has 3 line(s).
```

Now the control: the same robot with the diary in its backpack (mounted
read-write, no `:ro`). This **should work**, and it really destroys the
diary:

```bash
docker run --rm -i -v hd-sec-diary:/logs alpine:3.20 sh < attack.sh
# Attacker running as: root
#   [WORKED ] rewrite an old entry
#   [WORKED ] erase the whole diary
#   [WORKED ] delete the diary file
# Diary now has 0 line(s).
```

Three characters, `:ro`, are the whole difference. The keeper is still
running, so new entries keep arriving:

```bash
docker run --rm --network hd-sec-net alpine:3.20 sh -c \
  'echo "robot is sorry" | nc -w1 hd-sec-keeper 5140'
docker run --rm -v hd-sec-diary:/logs:ro alpine:3.20 cat /logs/robot-diary.txt
```

## The free librarian: `docker logs`

Anything a container **prints** goes to Docker, which stores it outside the
container. Start a chatty container:

```bash
docker run -d --name hd-sec-chatty alpine:3.20 sh -c \
  'i=1; while true; do echo "chatty says hello #$i"; i=$((i+1)); sleep 1; done'
docker logs hd-sec-chatty | head -3
```

Now go inside and look for the log file to delete:

```bash
docker exec hd-sec-chatty sh -c 'find / -name "*-json.log" 2>/dev/null | wc -l'
# 0       <- it isn't in here at all
docker logs hd-sec-chatty | head -3     # still all there
```

Control: a program that keeps its diary in its own folder can wipe it in one
line:

```bash
docker run --rm alpine:3.20 sh -c '
  echo "I broke a vase" >> /var/log/my-diary.txt
  printf "" > /var/log/my-diary.txt
  echo "lines left: $(wc -l < /var/log/my-diary.txt)"'
# lines left: 0
```

That's why the usual advice for containers is: **print your log, don't save
it to a file.** Docker's *logging driver* decides where printed lines go.
The default, `json-file`, keeps them on the same computer
(`docker inspect hd-sec-chatty --format '{{.HostConfig.LogConfig.Type}}'`).
Other drivers such as `syslog`, `gelf` or `fluentd` send every line
**to a different computer** as it's printed (`docker run --log-driver …`).
That's the librarian in another building.

## What this does NOT protect against

> - **Lies.** The robot can't erase the diary, but it can still *add* to it:
>   `echo "robot never broke anything" | nc -w1 hd-sec-keeper 5140` works
>   fine. The keeper proves *what the robot said and when*, not that it's
>   true.
> - **The keeper itself.** If someone breaks into the keeper container (or
>   mounts the volume read-write, like our control did), the diary can be
>   edited. Lesson [18](../18-tamper-evident-logbook/) makes that kind of edit
>   **detectable**.
> - **The computer's owner.** Anyone who can run `docker` can mount the
>   volume read-write or delete Docker's own log files. Only a copy on
>   **another computer** survives that (lesson
>   [19](../19-pin-by-digest-and-honest-limits/)).
> - **Floods.** A robot can send a million junk lines to bury the
>   important one. Real log systems limit how fast one sender can write.

## Try it yourself

1. Run the robot as a normal user with the diary read-write:
   `docker run --rm -i -u 1234 -v hd-sec-diary:/logs alpine:3.20 sh < attack.sh`.
   Which wall stopped it this time? (Hint: `ls -ln /logs`, and compare with
   lesson 15.) Why is `:ro` still the better wall?
2. Look at `keeper/append.sh`. It only ever uses `>>` (add to the end).
   Why is it important that the keeper's own code has no "delete" command?
3. Send a line with a fake time at the front, like
   `echo "1999-01-01T00:00:00Z robot was good" | nc -w1 hd-sec-keeper 5140`.
   Look at the diary. Can you still tell the real time it arrived?
4. **Quiz:** your app writes `/app/debug.log` inside its own container.
   Name two ways from this lesson to make that log un-erasable by the app.

## Clean up

```bash
docker rm -f hd-sec-keeper hd-sec-chatty
docker volume rm hd-sec-diary
docker network rm hd-sec-net
docker image rm hd-sec-keeper
```

Next: [18-tamper-evident-logbook](../18-tamper-evident-logbook/): a diary
where changing one old word breaks a chain you can check.
