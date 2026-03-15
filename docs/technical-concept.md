# Technical Concept

Status: March 15, 2026

## Target Product

Pirrates Captain is a native Apple app that controls Sonarr, Radarr, Lidarr, Prowlarr, and download clients from one interface. The product is not its own backend platform. It is a secure local client for existing arr services.

This leads to three technical principles:

1. Native Apple experience instead of cross-platform UI.
2. Direct API integration with existing services instead of a custom middleware backend.
3. A modular monolith for fast MVP delivery that can later be split into cleaner packages if needed.

## Recommended Tech Stack

### Platforms

- iPhone
- iPad
- Mac Catalyst

### Language and Frameworks

- Swift 6
- SwiftUI
- Observation for state management in new views and view models
- URLSession with async/await for API communication
- SwiftData for local, non-critical persistence and caching
- Keychain for API keys, host credentials, and tokens
- os.Logger for logging and diagnostics

### Architecture

- Feature-first modular monolith
- MVVM as the UI pattern
- Clear separation between Presentation, Domain, and Data
- Protocol-based dependencies instead of a heavy DI framework
- Dedicated API clients per service: `SonarrClient`, `RadarrClient`, `LidarrClient`, `ProwlarrClient`, `DownloadClient`

### Testing and Delivery

- Swift Testing for new unit and integration tests
- XCUITest/XCTest for UI tests
- GitHub Actions for CI
- Xcode Cloud as an optional later step for Apple-specific delivery pipelines

## Stack Decision

The project should use a straightforward native Apple stack:

- Frontend: SwiftUI
- App architecture: MVVM with feature-first modules
- Concurrency: Swift Concurrency with async/await and actors
- Networking: URLSession + Codable + dedicated service API clients
- Local data: SwiftData for local app data, Keychain for secrets
- Tests: Swift Testing + XCUITest
- CI/CD: GitHub Actions, later optionally Xcode Cloud

## Why This Stack

### Why not a cross-platform stack

React Native, Flutter, or Kotlin Multiplatform provide little benefit here. The product is clearly Apple-focused and depends on native navigation, widgets, notifications, system integration, and polished layouts across iPhone, iPad, and Mac Catalyst. A native stack lowers integration risk and keeps the UI closer to platform behavior.

### Why not a custom backend for the MVP

The arr services already expose HTTP APIs. Adding a dedicated Pirrates backend would introduce hosting, authentication, sync, privacy, and operational cost without making the MVP materially stronger. For the MVP, the app should talk directly to the target services.

### Why SwiftData should only handle local data

The source of truth belongs to Sonarr, Radarr, and the other integrated services, not to the app. SwiftData should therefore store server profiles, recent filters, local favorites, offline caches, and UI-adjacent state, but not become the primary sync layer for operational data such as queues, calendars, or history.

## Target Architecture

## Layers

### Presentation

- SwiftUI views
- Feature-specific view models / observable types
- Navigation, screen state, and user intents

### Domain

- Use cases
- Domain models and mapping rules
- Cross-service logic, for example global search or a unified queue

### Data

- API clients per external platform
- Repositories as the facade for Presentation and Domain
- Local persistence with SwiftData
- Secure storage with Keychain

## Module Structure

```text
PirratesCaptain/
  App/
  Core/
    Foundation/
    DesignSystem/
    Networking/
    Persistence/
    Security/
    Logging/
    Testing/
  Features/
    Dashboard/
    Discover/
    Library/
    Activity/
    Servers/
    Settings/
  Integrations/
    Sonarr/
    Radarr/
    Lidarr/
    Prowlarr/
    DownloadClients/
```

## Communication Model

The app talks directly to configured servers over HTTPS. Each integration client should encapsulate:

- Base URL and API key handling
- Endpoint definitions
- DTOs and mapping into app models
- Error handling
- Retry and rate-limit behavior

Repositories then aggregate responses into app-facing models. Examples:

- `DashboardRepository` collects health, queue, recent additions, and upcoming items from multiple services.
- `DiscoverRepository` encapsulates global search across Sonarr, Radarr, and Lidarr.

## Data Strategy

### Store locally

- Server profiles
- API configuration without secrets
- Recent filters and searches
- Favorites / pins
- Short-lived cached data for faster startup

### Store only in Keychain

- API keys
- Credentials
- Tokens or session data

### Do not treat as local source of truth

- Live queue data
- External job history
- Calendar data
- Full library contents

## Offline and Sync Strategy

The MVP should be cache-assisted online:

- The app works primarily online.
- Last successful responses may be cached for faster rendering.
- Mutations are executed only while online.
- No complex offline write-back in the MVP.

This keeps sync conflicts and failure modes manageable.

## Security

- Allow HTTPS by default; support exceptions only deliberately per server profile
- Store secrets only in Keychain
- Redact sensitive values in logs
- Isolate certificate and trust handling in case self-hosted setups require exceptions
- No proxy forwarding through third-party infrastructure

## Internal API Shape

Each integration should follow the same flow:

```text
Feature ViewModel
  -> Use Case / Repository
    -> Service Client
      -> Endpoint
        -> URLSession
```

Example contracts:

- `MovieManaging`
- `SeriesManaging`
- `QueueMonitoring`
- `ServerHealthChecking`

This keeps the UI decoupled from backend-specific dialects.

## Design System

Even in the MVP, the project should have a small design system:

- Typography tokens
- Spacing tokens
- Status and health colors
- Reusable cards, lists, status badges, and empty states

This reduces churn when iPad and Mac Catalyst layouts expand later.

## Testing Strategy

### Unit Tests

- Mapping from DTOs to domain models
- View model state transitions
- Repository aggregation across multiple services

### Integration Tests

- API client parsing with stubbed responses
- Failure cases such as timeouts, 401, 404, and 500 responses

### UI Tests

- Creating a server
- Searching and adding media
- Loading the queue and dashboard

## CI/CD

Recommended starting point:

- GitHub Actions
- Build for iPhone Simulator
- Run unit tests
- Add linting and formatting once rules are defined

Optional later:

- Xcode Cloud for Apple-focused release workflows
- A test matrix for iPhone, iPad, and Mac Catalyst

## MVP Scope

The MVP should stay intentionally small:

1. Multi-server configuration for at least Sonarr and Radarr
2. Dashboard with health, queue, and recent items
3. Search and add media
4. Basic queue / activity view
5. Solid error handling and server status indicators

Not in the MVP:

- Custom cloud sync
- A complex automation engine
- Full offline mode
- A plugin system

## Clear Recommendation

The project should be built as a native SwiftUI app using Swift 6, Observation, async/await, URLSession, SwiftData, and Keychain. From an architecture perspective, a feature-first modular monolith with MVVM, repositories, and separate API clients per arr service is the best fit for this product.

This stack is fast for the MVP, well matched to Apple platforms, and extensible later for widgets, notifications, multi-server management, and additional integrations without a major rewrite.
