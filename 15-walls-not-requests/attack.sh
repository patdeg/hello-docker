#!/bin/sh
# Pretend the robot got TRICKED: someone sent it a sneaky message, or an AI
# agent read a bad instruction, and now it runs these commands. Nothing here
# is real hacking; it's just ordinary commands the robot was told not to run.
#
# Run it INSIDE a container, as whoever that container runs as:
#   docker run --rm -i IMAGE sh < attack.sh

try() {
  what=$1; shift
  if sh -c "$*" 2>/dev/null; then
    echo "  [WORKED ] $what"
  else
    echo "  [BLOCKED] $what"
  fi
}

echo "Attacker running as: $(whoami 2>/dev/null || echo "user number $(id -u)")"
try "rewrite the robot's own program"    'echo "echo I am an EVIL robot now" > /app/robot.sh'
try "add a secret admin account"         'echo "sneaky::0:0:root:/root:/bin/sh" >> /etc/passwd'
try "drop a new file next to the program" 'echo hello > /app/surprise.txt'
echo "Now the robot says:"
sh /app/robot.sh
