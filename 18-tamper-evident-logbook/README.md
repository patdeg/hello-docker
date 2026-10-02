# 18: The tamper-evident logbook

## Goal

Lesson 17 kept the robot away from its diary. But what if someone breaks
into the **keeper** itself? We can't always stop that, but we can make sure
that **any change to an old line gets noticed**. You'll build a logbook
where every line is chained to the one before it, change one word, and
watch the chain snap. Then you'll meet a smarter burglar who re-forges the
whole chain, and the one trick that catches him too.

## The story: the paper chain

Imagine a paper chain where each new loop is glued *through* the loop
before it. You can add a loop at the end easily. But to swap out a loop in
the middle, you'd have to cut it open, and the cut shows.

Our logbook does the same thing with a **fingerprint**. A SHA-256
fingerprint is a 64-character code computed from some text. The same text
always gives the same fingerprint; change even one letter and you get a
completely different one:

```bash
docker run --rm alpine:3.20 sh -c '
  printf "robot broke a vase" | sha256sum
  printf "robot broke a vasE" | sha256sum'
# c79ac7c1767e7f0b6d59a35aea148c4e025becada7cbbdc7f3f0100ae830e99c  -
# 0d9dac81f7074c3a8a23b173084f7d19db71c00108e6c9276f33db4a47665997  -
```

Each row of the logbook stores a fingerprint of **the previous row's
fingerprint + this row's text**. So row 3's fingerprint depends on row 2,
which depends on row 1. Change row 2, and row 2's fingerprint no longer
matches, and the chain is broken from there on.

## New concepts

- **Hash (fingerprint):** `sha256sum` turns any text into a 64-character
  code. It's practically impossible to find two different texts with the
  same code.
- **Hash chain:** each row's fingerprint includes the fingerprint before
  it. The first row chains to a row of zeros.
- **Tamper-*evident*, not tamper-*proof*:** a chain can't stop an edit. It
  makes the edit **visible** to anyone who checks.
- **Checkpoint:** a copy of the latest fingerprint, kept **somewhere else**.

## Try it

```bash
cd 18-tamper-evident-logbook
docker build -t hd-sec-chainkeeper keeper
docker network create hd-sec-net

docker run -d --name hd-sec-chainkeeper --network hd-sec-net \
  -v hd-sec-logbook:/logs \
  --read-only --cap-drop ALL --security-opt no-new-privileges \
  hd-sec-chainkeeper

# The robot's day, read out loud to the keeper, one line at a time
docker run --rm --network hd-sec-net alpine:3.20 sh -c '
  for msg in "robot woke up" "robot broke a vase" "robot hid the pieces" "robot went to sleep"; do
    echo "$msg" | nc -w1 hd-sec-chainkeeper 5140
  done'

docker run --rm -v hd-sec-logbook:/logs:ro alpine:3.20 cat /logs/logbook.txt
# 88c76e41dd72...  2026-10-02T17:16:25Z robot woke up
# 2aca780c9ff8...  2026-10-02T17:16:25Z robot broke a vase
# ...
```

(Your fingerprints will be different from these, because your times are
different. That's the point: the fingerprint covers *everything* in the row.)

Check the chain with `verify.sh`. It runs in a throwaway container that can
only *read* the logbook, and reads the script from this folder (lesson 08):

```bash
docker run --rm -v hd-sec-logbook:/logs:ro -v "$(pwd)":/lesson:ro \
  alpine:3.20 sh /lesson/verify.sh /logs/logbook.txt
# Chain OK: 4 rows. Latest fingerprint: f815a3fd...
```

Now save a **checkpoint**: copy the latest fingerprint *out* of Docker, onto
your own computer:

```bash
docker run --rm -v hd-sec-logbook:/logs:ro alpine:3.20 \
  tail -n 1 /logs/logbook.txt | cut -d' ' -f1 > my-checkpoint.txt
cat my-checkpoint.txt
```

## Attack 1: change one word

Pretend a burglar got into the keeper. He runs as the keeper's own user
(number 10002), so he can write the logbook. He changes the embarrassing row:

```bash
docker run --rm -u 10002 -v hd-sec-logbook:/logs alpine:3.20 \
  sed -i 's/broke a vase/watered the plants/' /logs/logbook.txt
```

The text looks innocent now. But check the chain:

```bash
docker run --rm -v hd-sec-logbook:/logs:ro -v "$(pwd)":/lesson:ro \
  alpine:3.20 sh /lesson/verify.sh /logs/logbook.txt
# BROKEN at row 2: 2026-10-02T17:16:25Z robot watered the plants
#   (this row, or one before it, was changed)
```

Caught, and it even points at the row. **Control:** run `verify.sh` on a
logbook nobody touched (start over with a fresh volume) and it says
`Chain OK`. So "BROKEN" really means "changed", not "the checker is broken".

## Attack 2: the smart burglar

The burglar reads this lesson too. He knows how the fingerprints are made,
so after editing he simply **recomputes every fingerprint from the top**.
That's `rechain.sh`:

```bash
docker run --rm -u 10002 -v hd-sec-logbook:/logs -v "$(pwd)":/lesson:ro \
  alpine:3.20 sh /lesson/rechain.sh /logs/logbook.txt

docker run --rm -v hd-sec-logbook:/logs:ro -v "$(pwd)":/lesson:ro \
  alpine:3.20 sh /lesson/verify.sh /logs/logbook.txt
# Chain OK: 4 rows. ...        <- the attack WORKED. The chain looks perfect.
```

This is the honest part: **a hash chain on its own can be re-forged by
anyone who can rewrite the whole file.** The chain needs one thing the
burglar can't reach: your checkpoint, on another computer.

```bash
docker run --rm -v hd-sec-logbook:/logs:ro -v "$(pwd)":/lesson:ro \
  alpine:3.20 sh /lesson/verify.sh /logs/logbook.txt "$(cat my-checkpoint.txt)"
# Chain OK: 4 rows. ...
# TAMPERED: your saved fingerprint is not in this logbook any more!
```

The burglar can recompute the logbook, but he can't recompute the
fingerprint written in *your* file, on *your* computer. Because every
fingerprint depends on everything before it, there's no way to change old
rows and still end up with your checkpoint in the chain.

New rows keep arriving after a checkpoint, and that's fine: `verify.sh`
just looks for your saved fingerprint somewhere in the chain. Try saving a
checkpoint, sending another line, and verifying again: `Checkpoint OK`.

## What this does NOT protect against

> - **Prevention.** The chain doesn't stop anybody from editing or deleting
>   the logbook. It makes edits *visible*. Deleting the whole volume is very
>   visible too, but the rows are gone.
> - **Anything after your last checkpoint.** A burglar can rewrite rows
>   newer than your checkpoint without being caught by it. Real systems
>   send checkpoints off the computer often (every minute, or every row).
> - **A checkpoint kept next to the logbook.** If the burglar can reach
>   your checkpoint too, he just updates it. *Somewhere else* is the whole
>   trick: another computer, an email to yourself, a printed page.
> - **Lies told at the start.** As in lesson 17, the chain proves a row
>   wasn't *changed*, not that it was *true* when it was written.
> - **Lost messages.** This keeper is a toy that serves one visitor at a
>   time. If many robots talk at once, some get a "busy" error and their
>   line is never written (`nc` exits with an error, so the sender can tell).
>   Real log shippers retry.

## Try it yourself

1. Delete row 1 instead of changing it:
   `sed -i '1d' /logs/logbook.txt` (as the burglar, `-u 10002`). What
   does `verify.sh` say, and why?
2. Open `keeper/chain-append.sh` and `verify.sh` side by side. Find the one
   line in each that computes the fingerprint. They must match exactly;
   what would happen if they didn't?
3. Make your own checkpoint "off-box": email the fingerprint to yourself,
   or write the first 8 characters on paper. Is 8 characters enough to
   catch the smart burglar? (Hint: how many different 8-character codes
   are there?)
4. **Quiz:** a company says "our logs are safe, they're hash-chained."
   What's the first question you'd ask them? (Hint: where is the
   checkpoint?)

## Clean up

```bash
docker rm -f hd-sec-chainkeeper
docker volume rm hd-sec-logbook
docker network rm hd-sec-net
docker image rm hd-sec-chainkeeper
rm -f my-checkpoint.txt
```

Next: [19-pin-by-digest-and-honest-limits](../19-pin-by-digest-and-honest-limits/):
the same fingerprint idea, used to make sure you're running the image you
think you're running.
