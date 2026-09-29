set shell := ["bash", "-uc"]

default:
    @just --list

ios-generate:
    scripts/one-project.sh

ios-build: ios-generate
    xcodebuild -scheme HouseDash -destination 'generic/platform=iOS Simulator' build

ios-test: ios-generate
    #!/usr/bin/env bash
    set -euo pipefail
    destination="platform=iOS Simulator,id=$(scripts/simulator.sh)"
    echo "testing on ${destination}"
    scripts/run-tests.sh HouseDash "$destination"
    for package in DesignSystem Networking Features; do
        ( cd "Packages/$package" && ../../scripts/run-tests.sh "$package" "$destination" )
    done

ios-test-ui: ios-generate
    #!/usr/bin/env bash
    set -euo pipefail
    destination="platform=iOS Simulator,id=$(scripts/simulator.sh)"
    echo "testing the UI suite on ${destination}"
    scripts/run-tests.sh HouseDashUITests "$destination"

commits base="origin/main":
    scripts/check-commits.sh {{base}}

gate-test:
    scripts/agent-review-test.sh
