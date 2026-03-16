# Architecture

The project uses a hybrid modular SwiftUI architecture.

## App shape

- One app target: `PirratesCaptainApp`
- Three local Swift packages:
  - `PirratesCore`
  - `PirratesIntegrations`
  - `PirratesDesignSystem`

## Layers

- Presentation: SwiftUI views and Observation-based view models
- Domain: shared entities, protocols, and use-case oriented contracts
- Data: local persistence, Keychain storage, and arr service clients

## Dependency flow

- Features depend on Core, Integrations, and DesignSystem
- Integrations depend on Core
- DesignSystem may depend on Core
- Features do not import each other

## Networking

The app communicates directly with configured arr services using async/await and service-specific clients.
Discover search and add flows also talk directly to Sonarr and Radarr for lookup, root-folder loading, quality-profile loading, and add requests.

## Dashboard data flow

- Dashboard health is tracked per configured server, not just per service type.
- Sonarr and Radarr dashboard content is sourced from live `queue` and `calendar` endpoints.
- Partial service failures degrade only the affected server cards; the dashboard still renders remaining data.
