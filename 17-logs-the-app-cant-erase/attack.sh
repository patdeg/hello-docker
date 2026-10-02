#!/bin/sh
# The robot did something embarrassing and wants to hide it. Run INSIDE the
# robot container:  docker run --rm -i ... sh < attack.sh

try() {
  what=$1; shift
  if sh -c "$*" 2>/dev/null; then
    echo "  [WORKED ] $what"
  else
    echo "  [BLOCKED] $what"
  fi
}

DIARY=/logs/robot-diary.txt
echo "Attacker running as: $(whoami 2>/dev/null || echo "user number $(id -u)")"
try "rewrite an old entry"  "sed -i 's/broke/fixed/' $DIARY"
try "erase the whole diary" "printf '' > $DIARY"
try "delete the diary file" "rm $DIARY"
echo "Diary now has $(cat $DIARY 2>/dev/null | wc -l) line(s)."
