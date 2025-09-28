#!/bin/bash

# List of IPs to ping
ips=(
  "1.0.1.3"
  "2.0.1.3"
  "3.0.1.3"
  "1.12.1.2"
  "2.21.1.2"
  "2.22.1.2"
  "1.114.1.2"
)

echo "=== Ping Test Results ==="
for ip in "${ips[@]}"; do
  echo "Pinging $ip..."

  if ping -c 2 -W 1 "$ip" &>/dev/null; then
    echo "  ✅ Reachable"
  else
    echo "  ❌ ERROR: IP unreachable from a client"
  fi
done
