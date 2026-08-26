#!/usr/bin/env bash
# Add a swapfile to the trieoh host (incident postmortem 2026-08-26).
#
# Why: 2-core / 7.8Gi box with NO swap. During the univents v0.10.12 publish
# build the host pegged 100% CPU for 18 min and memory pressure had zero
# buffer (no swap to fall back on, kernel constantly reclaiming page cache).
#
# Usage (run as root on the server):
#   sudo scripts/add-swap.sh [swapfile] [sizeGiB]
#   default: /swapfile, 4GiB
set -euo pipefail

SWAPFILE="${1:-/swapfile}"
SIZE_G="${2:-4}"

if [ "$(id -u)" -ne 0 ]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

if swapon --show | grep -q "$SWAPFILE"; then
  echo "$SWAPFILE already active"
  swapon --show
  exit 0
fi

if [ -f "$SWAPFILE" ]; then
  echo "$SWAPFILE exists but is not active — refusing to overwrite" >&2
  exit 1
fi

fallocate -l "${SIZE_G}G" "$SWAPFILE"
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"

if ! grep -q "^${SWAPFILE} " /etc/fstab; then
  echo "${SWAPFILE} none swap sw 0 0" >> /etc/fstab
  echo "persisted in /etc/fstab"
fi

swapon --show
echo "done: ${SIZE_G}GiB swap at ${SWAPFILE}"
