# Pirrates Captain 🏴‍☠️

**Command your media automation fleet.**

Pirrates Captain is a native iOS control center for the arr ecosystem:

- Sonarr
- Radarr
- Lidarr
- Prowlarr
- SABnzbd / download clients

Inspired by Zagreus but designed to be more modern, native, and powerful.

## Vision

One unified interface to manage your entire media automation stack.

### Core Ideas

- Unified dashboard for all services
- Global search across movies, shows and music
- Download monitoring
- Automation rules
- Native SwiftUI experience

## Platforms

- iPhone
- iPad
- Mac Catalyst

## Tech Stack

- SwiftUI
- Observation
- Async/Await networking
- Hybrid modular architecture

## Project Status

The repository now contains:

- A generated Xcode app target driven by `xcodegen`
- Local Swift packages for `PirratesCore`, `PirratesIntegrations`, and `PirratesDesignSystem`
- Feature-first app source structure for `Dashboard`, `Discover`, `Library`, `Activity`, `Servers`, and `Settings`
- GitHub Actions CI for package tests and app builds

## Project Structure

See `/docs/repository-structure.md` for details.

## Technical Concept

See `/docs/technical-concept.md` for the recommended stack and target architecture.

## Project Setup

See `/docs/project-setup.md` for the generated scaffold, package split, and build workflow.

## License

GNU GPL v3 or later

Copyright (C) 2026 Matthias Wallner-Géhri

See `/LICENSE`.
