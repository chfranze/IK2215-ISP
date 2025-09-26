#!/bin/bash

# List of "IP DOMAIN"
entries=(
  "1.114.0.0 eth1r1.isp114.lab"
  "1.114.0.2 eth2r1.isp114.lab"
  "1.114.0.4 eth3r1.isp114.lab"
  "1.114.2.1 dummy0r1.isp114.lab"
  "1.114.0.1 eth1r2.isp114.lab"
  "1.114.0.8 eth2r2.isp114.lab"
  "1.114.2.2 dummy0r2.isp114.lab"
  "1.114.1.1 eth0r3.isp114.lab"
  "1.114.0.7 eth1r3.isp114.lab"
  "1.114.0.3 eth2r3.isp114.lab"
  "1.114.0.9 eth3r3.isp114.lab"
  "1.114.2.3 dummy0r3.isp114.lab"
  "1.114.10.1 eth0r4.isp114.lab"
  "1.114.0.5 eth1r4.isp114.lab"
  "1.114.0.6 eth2r4.isp114.lab"
  "1.114.2.4 dummy0r4.isp114.lab"
  "1.114.1.2 ns.isp114.lab"
  "1.114.1.3 www.isp114.lab"
  "1.114.1.4 dhcpd.isp114.lab"
  "1.114.10.10 c1.isp114.lab"
  "1.114.10.11 c2.isp114.lab"
  "1.0.1.2 root DNS"
  "2.0.1.2 .lab DNS"
)

echo "=== Ping Test Results ==="
for entry in "${entries[@]}"; do
  ip=$(echo $entry | awk '{print $1}')
  name=$(echo $entry | awk '{print $2}')

  echo "Pinging $ip ($name)..."

  if ping -c 2 -W 1 "$ip" &>/dev/null; then
    echo "  ✅ Reachable"
  else
    echo "  ❌ Unreachable"
  fi
done
