# Development Plan

Status: Active  
Focus: MVP first  
Planning model: Milestones

This document is the detailed internal execution plan for Pirrates Captain.
`docs/roadmap.md` remains the short public-facing roadmap.

## Delivery Sequence

1. Stabilize the repository and delivery pipeline
2. Finish MVP product surfaces for Sonarr and Radarr
3. Raise quality, diagnostics, and test coverage to release level
4. Start post-MVP expansion only after the MVP is release-ready

## Milestone 0: Repo Stability and Planning Baseline

Status: In progress

Outcome:
- The repository is consistently buildable
- Security tooling is green
- This document is the source of truth for detailed execution planning

Tasks:
- [x] Add a detailed development plan document
- [x] Keep `docs/roadmap.md` short and point it at this file
- [x] Confirm GitHub CodeQL default setup is disabled
- [ ] Keep CI and CodeQL aligned to Xcode 26.3 and the intended runner image
- [ ] Confirm Dependabot is opening updates as expected
- [ ] Standardize milestone labels/conventions: `mvp`, `infra`, `quality`, `post-mvp`

Acceptance criteria:
- `docs/development-plan.md` exists and matches current priorities
- `docs/roadmap.md` is high-level only
- CI and CodeQL use the same intended Xcode selection strategy
- CodeQL runs through the custom workflow only

## Milestone 1: Complete the MVP Feature Set

Status: Planned

Outcome:
- Sonarr and Radarr flows feel complete for day-to-day use
- Core screens distinguish clearly between empty, partial-failure, and full-failure states

Tasks:

### Dashboard
- [ ] Add clearer per-server error states and partial-failure messaging
- [ ] Surface richer queue summary and release context
- [ ] Distinguish “no servers”, “no data”, and “server failed” in UI states

### Discover
- [ ] Improve add-flow validation and user-facing error handling
- [ ] Prevent duplicate or invalid add flows when the remote server already manages the item
- [ ] Show more result metadata that affects add decisions

### Library
- [ ] Add filtering for service, server, and item type
- [ ] Add sorting controls for title, newest, and service grouping
- [ ] Add lightweight detail presentation or expandable rows
- [ ] Define explicit refresh behavior

### Activity
- [ ] Strengthen queue/history visual distinction
- [ ] Refine failure, empty, loading, and refresh states
- [ ] Lock activity scope to a recent-only remote window unless pagination becomes necessary

### Servers
- [ ] Improve malformed URL, missing API key, offline, and authentication feedback
- [ ] Add manual re-check/revalidate for saved servers
- [ ] Improve multi-server enabled/disabled UX

Acceptance criteria:
- Dashboard, Discover, Library, Activity, and Servers have no placeholder UX in the MVP path
- Sonarr and Radarr are the only required integrations for MVP completion
- All user-visible failures map through `AppError`

## Milestone 2: Settings, Diagnostics, and Operational UX

Status: Planned

Outcome:
- The app is supportable without Xcode
- Diagnostics are useful but redact secrets

Tasks:
- [ ] Replace the placeholder Settings screen with persisted app settings
- [ ] Persist the diagnostics toggle
- [ ] Show app/build/version details
- [ ] Add links or sections for architecture, license, and about
- [ ] Surface per-server last validation result
- [ ] Surface last successful load timestamps for Dashboard, Library, and Activity
- [ ] Add redacted request/response error summaries for troubleshooting
- [ ] Define and document diagnostics logging defaults and redaction rules
- [ ] Add a lightweight support snapshot with non-secret environment data

Acceptance criteria:
- Diagnostics state survives app relaunch
- No API keys or equivalent secrets are shown in logs or support views
- A user can inspect app/version/server-state information inside the app

## Milestone 3: Release-Quality Engineering

Status: Planned

Outcome:
- The MVP is trustworthy to ship

Tasks:
- [ ] Expand repository tests for success, auth failure, unreachable server, and malformed payload paths
- [ ] Add view model tests for Dashboard, Discover, Library, Activity, and Servers
- [ ] Add UI tests for add/edit/delete server, dashboard load, search/add, activity, library filtering, and settings persistence
- [ ] Eliminate raw backend wording from UI-facing error messages
- [ ] Add caching policy documentation and tests for locally persisted UI data
- [ ] Verify Mac Catalyst behavior and fix obvious layout regressions
- [ ] Write an MVP release checklist

Acceptance criteria:
- Package tests pass
- App build passes
- Key UI tests pass
- No placeholder screens remain in core MVP flows
- CI, CodeQL, and dependency automation are green

## Milestone 4: Post-MVP Expansion

Status: Planned

Outcome:
- Service breadth expands only after the MVP is stable

Tasks:
- [ ] Add Lidarr support using the existing Sonarr/Radarr integration pattern
- [ ] Add Prowlarr only where it improves discovery or indexer visibility
- [ ] Evaluate notifications as the first post-MVP user-facing feature
- [ ] Keep automation rules, widgets, and advanced offline sync out of scope until after stabilization

Acceptance criteria:
- MVP release work is complete before new service breadth becomes the main focus
- Post-MVP work reuses the same repository and diagnostics patterns established for Sonarr/Radarr

## Cross-Cutting Decisions

- `AppError` remains the normalized surface for user-visible failures
- Feature view models remain Observation-based and repository-driven
- Diagnostics and settings persistence live in Core persistence/security layers, not feature-local storage
- No custom backend is introduced in this phase

## Tracking Conventions

- Use `mvp`, `infra`, `quality`, and `post-mvp` as work labels or task prefixes
- Every implementation task should define:
  - user-facing outcome
  - affected feature or subsystem
  - verification steps
  - follow-up risks or dependencies
