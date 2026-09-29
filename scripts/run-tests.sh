#!/usr/bin/env bash
set -euo pipefail

scheme="${1:?a scheme is required}"
destination="${2:?a destination is required}"
log="$(mktemp -t "hd-${scheme}")"

status=0
xcodebuild -scheme "$scheme" -destination "$destination" ${HD_XCODEBUILD_EXTRA:-} test 2>&1 | tee "$log" || status=$?

executed=$(grep -cE "^Test Case '.*' (passed|failed) " "$log" || true)
if [ "$executed" -eq 0 ]; then
    printf '%s reported exit %s having executed 0 test cases on %s; a suite that succeeds at nothing is not a pass\n' \
        "$scheme" "$status" "$destination" >&2
    exit 2
fi
printf '%s executed %s test cases on %s and exited %s\n' "$scheme" "$executed" "$destination" "$status"
exit "$status"
