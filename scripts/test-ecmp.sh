#!/bin/bash

routers=(as114r1 as114r2 as114r3 as114r4)
failed=0

for r in "${routers[@]}"; do
  echo "=== Checking $r ==="

  # Run vtysh inside kathara with here-doc
  output=$(kathara exec "$r" -- vtysh <<EOF
show ip route ospf
EOF
)

  # Detect ECMP: same prefix with more than one 'via'
  ecmp=$(echo "$output" | awk '/^O/ {count[$2]++} END {for (p in count) if (count[p]>1) print p}')

  if [[ -n "$ecmp" ]]; then
    echo "❌ FAIL: ECMP detected for prefixes:"
    echo "$ecmp"
    failed=1
  else
    echo "✅ PASS: No ECMP"
  fi

  echo
done

exit $failed

