#!/bin/sh
# Adds each line a visitor sends to the logbook, chained to the line before.
#
# Every row of the logbook looks like:   FINGERPRINT  TIME  MESSAGE
# and   FINGERPRINT = sha256( previous row's FINGERPRINT + " " + TIME MESSAGE )
#
# So each row "remembers" the row before it, which remembers the one before
# that, all the way back to the start (a row of zeros).
BOOK=/logs/logbook.txt
START=0000000000000000000000000000000000000000000000000000000000000000

while IFS= read -r line; do
  entry="$(date -u '+%Y-%m-%dT%H:%M:%SZ') $line"
  (
    flock 9   # one visitor at a time, so two rows never grab the same "previous"
    prev=$(tail -n 1 "$BOOK" 2>/dev/null | cut -d' ' -f1)
    [ -n "$prev" ] || prev=$START
    hash=$(printf '%s %s' "$prev" "$entry" | sha256sum | cut -d' ' -f1)
    printf '%s %s\n' "$hash" "$entry" >> "$BOOK"
  ) 9>> /logs/.lock
done
