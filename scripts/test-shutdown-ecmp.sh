#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <router> <interface>"
  echo "Example: $0 as114r2 eth1"
  exit 1
fi

ROUTER=$1
IFACE=$2

echo "=== Shutting down $ROUTER $IFACE ==="

# Shutdown the interface
kathara exec "$ROUTER" -- ip link set "$IFACE" down

# Wait a bit for OSPF to reconverge
sleep 5

echo "--- Checking ECMP after shutdown ---"
output=$(kathara exec "$ROUTER" -- vtysh <<EOF
show ip route ospf
EOF
)

# Detect ECMP
ecmp=$(echo "$output" | awk '/^O/ {count[$2]++} END {for (p in count) if (count[p]>1) print p}')

if [[ -n "$ecmp" ]]; then
  echo "❌ FAIL: ECMP detected for prefixes:"
  echo "$ecmp"
  exit 1
else
  echo "✅ PASS: No ECMP"
  exit 0
fi
