#!/bin/sh
# Runs once per visitor. Reads each line the visitor sends and adds it to the
# end of the diary, with the time in front. It only ever ADDS (>>); there is
# no code here that deletes or changes old lines.
while IFS= read -r line; do
  printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$line" >> /logs/robot-diary.txt
done
