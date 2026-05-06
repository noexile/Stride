# Sneaker Life Tracker — CLAUDE.md

Always-on context for Claude Code. Keep this ruthlessly current — every committed decision lands here.

## Project

iOS app that tracks running-shoe mileage from HealthKit so the owner knows when to swap shoes before injury. Apple doesn't surface this natively, so we're building it.

**Owner:** Sasho — 10 years dev experience, Apple ecosystem, enthusiast runner.

## Constraints

- **iOS-only.** iPhone + Apple Watch. No Android, no web app (unless a sync server is added later).
- **Xcode required** for simulator and device deploys. Claude Code handles write / refactor / test; Xcode handles build and run.
- **HealthKit** is the primary data source — gated by user-granted entitlements.
- **SwiftData** for on-device persistence; iCloud-backed sync comes for free. Revisit only if a server-side sync story is needed.
- **Free Apple ID** for now. Re-sign to device every 7 days. Upgrade to paid ($99/yr Apple Developer Program) before TestFlight.
- **TestFlight / App Store Connect** is the deploy pipeline. "Cloud deploy" means TestFlight, not a server.
- **Fastlane** for signing, version bumps, and TestFlight uploads when CI/CD is wired.

## Decisions

| # | Decision | Outcome | Date |
|---|---|---|---|
| 1 | Persistence | SwiftData (on-device, iCloud sync) | 2026-05-04 |
| 2 | Tech stack (Native vs cross-platform) | **Open** — architect agent will write comparison in `/docs/architecture.md` before we commit | 2026-05-04 |
| 3 | Backend | On-device only for v1; revisit if sync or web access is needed | 2026-05-04 |
| 4 | Apple Developer account | Free for now; upgrade before TestFlight | 2026-05-04 |

See `DECISIONS.md` for the full log.

## MVP Scope (v1)

**In:**
- Shoe CRUD (name, purchase date, mileage threshold)
- Auto-import runs from HealthKit / Apple Watch
- Per-shoe mileage tracking with exhaustion warnings

**Out (v1 non-goals):**
- Shoe-rotation suggestions
- Multi-shoe assignment UX
- Social features
- GPS rendering
- Shoe database lookup

## Build Plan

Vertical slices — feature end-to-end (UI + logic + data + tests), not horizontal layers.

- **Slice 1:** Add a shoe, see it in a list
- **Slice 2:** Import this week's runs from HealthKit
- **Slice 3:** Assign runs to a shoe, show cumulative mileage + warning state

Each slice = its own branch + PR + review.

## Open Questions

- Native SwiftUI vs cross-platform — resolved by `/docs/architecture.md`
- Default mileage threshold — likely user-configurable, default ~400 mi
- Whether to model explicit shoe states (active / retired / in-rotation)
- Whether v1 needs an onboarding flow or opens directly into the shoe list
- Whether to track wear surface (road / trail / track) in v1 or v2

## Conventions

- Plan before code. For any non-trivial change, generate a plan with the `Plan` subagent, review it, then execute.
- Use `/log-decision` to record decisions. They land in `DECISIONS.md` and should be mirrored here.
- Tests: Swift Testing for units, XCUITest for 2–3 critical flows.
- Security: run `/security-review` on each PR. Threat surface — data leaving device, sensitive info in logs, broken entitlements, third-party SDK telemetry.
- CI: GitHub Actions on `macos-latest` — build + unit tests + SwiftLint.

## Agents

| Agent | File | Role |
|---|---|---|
| product | `.claude/agents/product.md` | PRD, requirements, scope decisions |
| architect | `.claude/agents/architect.md` | Tech-stack comparisons, data model, system design docs |
| ios-engineer | `.claude/agents/ios-engineer.md` | SwiftUI, SwiftData, HealthKit implementation |

## Glossary

- **SwiftData** — declarative persistence for SwiftUI; iCloud sync on by default
- **HealthKit** — Apple framework for health/fitness data; requires entitlements
- **Fastlane** — Ruby toolchain for iOS signing, version bumps, TestFlight uploads
- **Vertical slice** — feature delivered end-to-end rather than by layer
- **TestFlight** — Apple's beta distribution platform; requires paid developer account
