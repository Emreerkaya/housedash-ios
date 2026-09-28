# housedash-ios

HouseDash iOS app. SwiftUI, iOS 18+, Swift 6 language mode.

## Layout

```
project.yml              xcodegen source of truth (HouseDash.xcodeproj is generated, not committed)
App/HouseDash/           thin app target: entry point, asset catalog
Packages/DesignSystem/   generated color tokens, type scale, layout primitives (R2/R3/R4)
Packages/Networking/     typed HTTP client, DTO layer
Packages/Features/       tab scaffold and per-tab placeholder screens
HouseDashTests/          app-level XCTest target
```

## Build

Requires `xcodegen` (2.45.4 used here). The `.xcodeproj` is not committed; generate it first.

```
xcodegen generate
xcodebuild -scheme HouseDash -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme HouseDash -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Or, once `just` is installed:

```
just ios-build
just ios-test
```

## Tokens

Every color in `Packages/DesignSystem` is copied from `python3 build/tools/palette.py` in the design vault, never hand-typed. Re-run the generator and diff before changing a color.
