#!/bin/sh
# Four break-in attempts. Run it INSIDE a container:
#   docker run --rm -i [LOCKS...] hd-sec-house sh < attack.sh
# and compare the results with and without each lock.

try() {
  what=$1; shift
  if sh -c "$*" 2>/dev/null; then
    echo "  [WORKED ] $what"
  else
    echo "  [BLOCKED] $what"
  fi
}

echo "Attacker running as: $(whoami 2>/dev/null || echo "user number $(id -u)")"

# 1. Change the robot's program (needs a writable /app)
try "1 rewrite the robot's program" 'echo "echo EVIL" > /app/robot.sh'

# 2. Save a brand-new program in the scratch folder and run it
try "2 drop a program in /tmp and run it" \
    'printf "#!/bin/sh\necho evil\n" > /tmp/evil && chmod +x /tmp/evil && /tmp/evil >/dev/null'

# 3. A root superpower: change who owns a file (Linux calls it CAP_CHOWN)
try "3 use a root superpower (chown)" 'touch /tmp/mine && chown nobody /tmp/mine'

# 4. Climb from robot to root using the leftover setuid helper
if [ "$(id -u)" = 0 ]; then
  echo "  [ n/a   ] 4 become root with doas (already root)"
else
  try "4 become root with doas" 'test "$(doas id -u)" = 0'
fi
