#!/bin/sh
# Prints a numbered line every 2 seconds, forever — a stand-in for any
# long-running program (a web server, a Minecraft server, ...).

# When Docker stops a container it sends the main process a SIGTERM
# ("please shut down"). Ctrl+C sends SIGINT. The main process of a container
# (PID 1) IGNORES both unless it explicitly handles them — so we do.
# See "Why did docker stop only take a second?" in the README.
trap 'echo "ticker: got a stop signal, shutting down cleanly"; exit 0' TERM INT

n=0
while true; do
  n=$((n + 1))
  echo "tick $n (container $(hostname))"
  sleep 2
done
