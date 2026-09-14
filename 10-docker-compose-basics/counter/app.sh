#!/bin/sh
# Demonstrates that Compose gives each service a DNS name equal to its
# service name — we can reach the "web" service just by calling it "web",
# with no IP addresses or manual networking involved.
while true; do
  echo "$(date '+%H:%M:%S') pinging http://web:8000/ ..."
  wget -qO- http://web:8000/ | head -n 1
  sleep 3
done
