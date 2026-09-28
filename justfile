default:
    just --list

ios-generate:
    xcodegen generate

ios-build: ios-generate
    xcodebuild -scheme HouseDash -destination 'platform=iOS Simulator,name=iPhone 17' build

ios-test: ios-generate
    xcodebuild -scheme HouseDash -destination 'platform=iOS Simulator,name=iPhone 17' test
