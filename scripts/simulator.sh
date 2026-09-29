#!/usr/bin/env bash
set -euo pipefail

if [ -n "${HD_SIMULATOR_ID:-}" ]; then
    printf '%s\n' "$HD_SIMULATOR_ID"
    exit 0
fi

sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"

xcrun simctl list devices available --json | python3 -c '
import json
import sys

sdk = tuple(int(part) for part in sys.argv[1].split("."))
wanted = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None

def version(identifier):
    tail = identifier.rsplit(".", 1)[-1]
    if not tail.startswith("iOS-"):
        return None
    try:
        return tuple(int(part) for part in tail[len("iOS-"):].split("-"))
    except ValueError:
        return None

runtimes = {}
for identifier, devices in json.load(sys.stdin)["devices"].items():
    iphones = [device for device in devices if device["name"].startswith("iPhone")]
    if not iphones:
        continue
    parsed = version(identifier)
    if parsed is None:
        continue
    runtimes[identifier] = (parsed, iphones)

if not runtimes:
    sys.exit("no available iPhone simulator on any iOS runtime; a destination cannot be resolved")

if wanted:
    if wanted not in runtimes:
        sys.exit(
            "HD_SIMULATOR_RUNTIME names %s, which holds no available iPhone; the runtimes that do are %s"
            % (wanted, ", ".join(sorted(runtimes)))
        )
    chosen = wanted
else:
    within = {name: value for name, value in runtimes.items() if value[0] <= sdk}
    if not within:
        sys.exit(
            "every available iPhone runtime (%s) is newer than the iphonesimulator SDK %s this Xcode builds against; "
            "name one with HD_SIMULATOR_RUNTIME to run against it anyway"
            % (", ".join(sorted(runtimes)), ".".join(str(part) for part in sdk))
        )
    chosen = max(within, key=lambda name: within[name][0])

devices = sorted(runtimes[chosen][1], key=lambda device: (device["name"], device["udid"]))
device = devices[-1]
print(
    "resolved %s on %s (%s), chosen from %d available iPhone(s) on %d runtime(s)"
    % (device["name"], chosen, device["udid"], len(devices), len(runtimes)),
    file=sys.stderr,
)
print(device["udid"])
' "$sdk_version" "${HD_SIMULATOR_RUNTIME:-}"
