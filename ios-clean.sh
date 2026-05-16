#!/bin/bash
# cleanup script for iOS-QEMU — kills stale containers, frees ports, removes leftovers

set -euo pipefail

NAME="${1:-ios-qemu}"

echo "[*] Cleaning up iOS QEMU ($NAME)..."

docker rm -f "$NAME" 2>/dev/null && echo "  [+] Removed container $NAME" || echo "  [-] No container $NAME"

for port in 2222 5555 1234; do
    pid=$(lsof -ti :"$port" 2>/dev/null || true)
    if [ -n "$pid" ]; then
        kill -9 "$pid" 2>/dev/null
        echo "  [+] Killed PID $pid on port $port"
    else
        echo "  [-] Port $port free"
    fi
done

pkill -f "qemu-system-aarch64.*iPhone6splus" 2>/dev/null && \
    echo "  [+] Killed stray QEMU processes" || \
    echo "  [-] No stray QEMU processes"

echo "[*] Done — ready to run: ./ios.sh normal"
