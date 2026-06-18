#!/usr/bin/env bash
cd "$(dirname "$0")"
./scripts/deploy/update.sh
echo
read -r -p "Press Enter to close…"