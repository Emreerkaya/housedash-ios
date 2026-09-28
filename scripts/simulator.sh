#!/usr/bin/env bash
set -euo pipefail

xcrun simctl list devices available --json | python3 -c '
import json
import sys

runtimes = json.load(sys.stdin)["devices"]
names = [
    device["name"]
    for devices in runtimes.values()
    for device in devices
    if device["name"].startswith("iPhone")
]
if not names:
    sys.exit("no available iPhone simulator; a destination cannot be resolved")
print(sorted(names)[-1])
'
