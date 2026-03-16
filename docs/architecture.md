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
