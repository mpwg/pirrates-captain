# Repository Structure

```text
PirratesCaptain/
  App/
  Features/
    Dashboard/
    Discover/
    Library/
    Activity/
    Servers/
    Settings/
  Shared/
  Packages/
    PirratesCore/
    PirratesIntegrations/
    PirratesDesignSystem/
  docs/
  .github/
  project.yml
  PirratesCaptain.xcworkspace/
  PirratesCaptainApp.xcodeproj/
```

## App

App startup, dependency composition, and the root shell.

## Features

Feature-first app code. Each feature uses:

- `Views/`
- `ViewModels/`
- `Models/`
- `Components/`

## Shared

App-local helpers that do not belong in a package.

## Packages

### PirratesCore

Shared domain, persistence, security, networking, logging, and testing helpers.

### PirratesIntegrations

Clients, DTOs, mappers, and repositories for Sonarr, Radarr, Lidarr, Prowlarr, and download clients.

### PirratesDesignSystem

Reusable UI tokens and components shared across app features.
