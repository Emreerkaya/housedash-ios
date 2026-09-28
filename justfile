set shell := ["bash", "-uc"]

destination := "platform=iOS Simulator,name=iPhone 17"

default:
    @just --list

ios-generate:
    xcodegen generate

ios-build: ios-generate
    xcodebuild -scheme HouseDash -destination '{{destination}}' build

ios-test: ios-generate
    #!/usr/bin/env bash
    set -euo pipefail
    xcodebuild -scheme HouseDash -destination '{{destination}}' test
    for package in DesignSystem Networking Features; do
        ( cd "Packages/$package" && xcodebuild -scheme "$package" -destination '{{destination}}' test )
    done
