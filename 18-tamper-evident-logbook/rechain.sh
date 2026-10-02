#!/bin/sh
# THE BURGLAR'S TOOL. After editing the logbook, a clever burglar recomputes
# every fingerprint from the top so the chain looks perfect again.
#   sh rechain.sh LOGBOOK
BOOK=$1
prev=0000000000000000000000000000000000000000000000000000000000000000
tmp=/tmp/rechained.txt

while IFS= read -r row; do
  entry=${row#* }
  prev=$(printf '%s %s' "$prev" "$entry" | sha256sum | cut -d' ' -f1)
  printf '%s %s\n' "$prev" "$entry"
done < "$BOOK" > "$tmp"
cat "$tmp" > "$BOOK"   # write over the old book in place
echo "Re-chained $BOOK. The chain will look perfect now..."
