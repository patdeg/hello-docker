#!/bin/sh
# Checks a chained logbook, row by row.
#   sh verify.sh LOGBOOK               check the chain
#   sh verify.sh LOGBOOK CHECKPOINT    also check a fingerprint you saved earlier
BOOK=$1
SAVED=$2
prev=0000000000000000000000000000000000000000000000000000000000000000
n=0
found=""

while IFS= read -r row; do
  n=$((n + 1))
  hash=${row%% *}     # first word = the fingerprint written in the book
  entry=${row#* }     # the rest   = time + message
  expect=$(printf '%s %s' "$prev" "$entry" | sha256sum | cut -d' ' -f1)
  if [ "$hash" != "$expect" ]; then
    echo "BROKEN at row $n: $entry"
    echo "  (this row, or one before it, was changed)"
    exit 1
  fi
  [ "$hash" = "$SAVED" ] && found=$n
  prev=$hash
done < "$BOOK"

echo "Chain OK: $n rows. Latest fingerprint: $prev"
if [ -n "$SAVED" ]; then
  if [ -n "$found" ]; then
    echo "Checkpoint OK: your saved fingerprint is still row $found."
  else
    echo "TAMPERED: your saved fingerprint is not in this logbook any more!"
    exit 1
  fi
fi
