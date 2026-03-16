# Project Setup

This repository is scaffolded as a hybrid modular Apple app.

## Source of truth

- `project.yml` defines the Xcode project through `xcodegen`.
- `PirratesCaptainApp.xcodeproj` is generated locally from `project.yml` and is not the checked-in source of truth.
- `PirratesCaptain.xcworkspace` is the top-level workspace that groups the app target and local packages.
- `Packages/` contains the reusable Swift packages:
  - `PirratesCore`
  - `PirratesIntegrations`
  - `PirratesDesignSystem`

## App shape

- `App/` contains startup, dependency composition, and root navigation.
- `Features/` contains feature-first UI code:
  - `Dashboard`
  - `Discover`
  - `Library`
  - `Activity`
  - `Servers`
  - `Settings`
- `Shared/` contains app-local types that do not belong in a reusable package.

## Build workflow

1. Generate the project with `xcodegen generate`.
2. Open `PirratesCaptain.xcworkspace`.
3. Build the `PirratesCaptainApp` scheme.

## Convenience script

You can generate the project and open the workspace with:

```bash
./scripts/open-workspace.sh
```

## Initial implementation scope

- Direct client to arr services, no custom backend
- SwiftUI app target with Observation-based view models
- SwiftData for local server profile persistence
- Keychain-backed secret storage
- Package tests for shared contracts and repository aggregation
- GitHub Actions CI for package tests and app builds
