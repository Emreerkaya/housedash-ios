set shell := ["bash", "-uc"]

default:
    @just --list

ios-generate:
    xcodegen generate

ios-build: ios-generate
    xcodebuild -scheme HouseDash -destination 'generic/platform=iOS Simulator' build

ios-test: ios-generate
    #!/usr/bin/env bash
    set -euo pipefail
    destination="platform=iOS Simulator,name=$(scripts/simulator.sh)"
    echo "testing on ${destination}"
    xcodebuild -scheme HouseDash -destination "$destination" test
    for package in DesignSystem Networking Features; do
        ( cd "Packages/$package" && xcodebuild -scheme "$package" -destination "$destination" test )
    done

commits base="origin/main":
    scripts/check-commits.sh {{base}}
