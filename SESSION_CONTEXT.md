# Sneaker Life Tracker — Session Context

> Generated 2026-05-04 from a planning session. Drop this into a new chat or Claude Code session to pick up where we left off. Use as the seed for `CLAUDE.md` once Claude Code is installed in this folder.

## Project at a glance

- **Name:** Sneaker Life Tracker (SLT)
- **Owner:** noexile — software developer (10 years), Apple ecosystem, enthusiast runner. First time using Claude as a tool beyond chat.
- **Workspace folder:** `E:\project_zero\SLT\Sneaker Life Tracker`
- **Job-to-be-done:** Track running-shoe mileage and lifespan so I notice when to swap shoes *before* injury — Apple doesn't surface this, so I'm building it.
- **Goal of the project (meta):** Use this small, real, personal app to learn the full Claude Code workflow — agents, slash commands, hooks, CI/CD, the deploy pipeline — before scaling to bigger projects.

## Constraints and ground truth

- iOS-only deployment target (iPhone + Apple Watch user).
- Free Apple ID for now; will upgrade to paid Apple Developer Program ($99/yr) closer to TestFlight.
- Free tier requires re-signing the app to a device every 7 days — fine for early dev.
- HealthKit + Apple Watch workout data is the core data source.
- iOS dev requires Xcode on macOS — Claude Code can write, refactor, run tests; simulator and device deploys still go through Xcode.
- For iOS, "artifactory" isn't JFrog/Nexus — it's TestFlight via fastlane → App Store Connect. The Apple pipeline is the registry.

## Decisions made

| Decision | Outcome |
|---|---|
| Tech stack | **Deferred** — architect agent will write a Native SwiftUI vs cross-platform comparison before we commit. |
| Apple Dev account | Free for now; upgrade to paid before TestFlight. |
| MVP scope (v1) | Shoe CRUD (model, purchase date, mileage threshold) · Auto-import runs from HealthKit/Apple Watch · Per-shoe mileage tracking + exhaustion warnings. |
| v1 non-goals | Shoe-rotation suggestions, multi-shoe assignment UX, social features, GPS rendering, shoe database lookup. |
| Backend | **Deferred** — start on-device (SwiftData), revisit if/when sync or web access is needed. iCloud-backed SwiftData gives free per-device sync. |

## Workflow plan (the full arc)

**Phase 0 — Tooling.** Install Claude Code, sign in, point at this folder. Connect GitHub MCP server. Create `CLAUDE.md` at repo root — the always-on context file.

**Phase 1 — Subagents.** Define in `.claude/agents/*.md`. Start with three (`product`, `architect`, `ios-engineer`). Add `security-reviewer`, `test-engineer`, `devops` later when friction calls for them. Resist the urge to define ten upfront.

**Phase 2 — Slash commands and hooks.** Start with one slash command: `/log-decision` (appends to `DECISIONS.md`). Lean light on hooks until you notice a recurring nag.

**Phase 3 — Ideation.** Product agent writes a one-page PRD at `/docs/PRD.md`: who, job-to-be-done, MVP, explicit non-goals, success metric.

**Phase 4 — System design.** Architect agent writes `/docs/architecture.md`: tech-stack comparison, data model (Shoe, Run, ShoeRunAssignment), HealthKit boundary, persistence choice (likely SwiftData), screen flow. Markdown only, no code yet.

**Phase 5 — Implementation in vertical slices.** Build feature-by-feature, not layer-by-layer.
- Slice 1: "Create a shoe and see it in a list."
- Slice 2: "Import this week's runs from HealthKit."
- Slice 3: "Assign runs to a shoe and show cumulative mileage with warning state."
- Each slice = its own branch + PR + review.

**Phase 6 — Testing.** Swift Testing for units, XCUITest for 2–3 critical flows. Test agent earns its keep reviewing PR coverage, not writing every test in isolation.

**Phase 7 — Security review.** Use the built-in `/security-review` skill on each PR. Threat surface for a HealthKit app: data leaving the device, sensitive info in logs, broken entitlements, third-party SDK telemetry.

**Phase 8 — CI/CD.** GitHub Actions on `macos-latest`: build + unit tests + SwiftLint. Fastlane for signing, version bumps, TestFlight upload.

**Phase 9 — Local deploy.** Xcode → plug in iPhone → Run. Re-sign weekly until paid account upgrade.

**Phase 10 — "Cloud" deploy.** TestFlight (internal/external testers) → App Store Connect. Distinct from web cloud deploy — Apple's pipeline IS the artifact path. A backend cloud deploy only enters the picture if we add a sync server (Supabase / Firebase / custom).

## Three Claude Code habits to internalize

1. **Keep `CLAUDE.md` ruthlessly current.** Every committed decision lands there. It's the highest-leverage file in the repo.
2. **Plan before code.** For any non-trivial change, generate a plan, push back on it, then execute. The `Plan` subagent type is built for this.
3. **Use subagents for context isolation, not cleverness.** Their main superpower is keeping the main thread's context window clean — let them do long-context grunt work and report back.

## Next concrete steps (resume here)

1. Scaffold the repo — `CLAUDE.md`, `README.md`, `.gitignore` (Xcode), `/docs/`, `git init`. No code.
2. Define three subagents in `.claude/agents/`: `product.md`, `architect.md`, `ios-engineer.md`.
3. Create `/log-decision` slash command in `.claude/commands/log-decision.md`.
4. Product agent writes `/docs/PRD.md`.
5. Architect agent writes `/docs/architecture.md` (tech-stack comparison + design). After this, the deferred tech-stack decision gets locked.
6. Build first vertical slice: "Add a shoe, see it in a list."

After that: add CI (a tiny GitHub Actions workflow) and bring on the `security-reviewer` and `test-engineer` agents before slice 2.

## Open questions still to answer

- Native SwiftUI vs cross-platform — answered by Phase 4 architecture doc.
- Default mileage threshold — likely user-configurable, default ~400 mi.
- Whether to model explicit shoe states (active, retired, in-rotation).
- Whether v1 needs an onboarding flow or just opens directly into the shoe list.
- Whether to track per-shoe wear surface (road / trail / track) in v1 or v2.

## Notes for resuming in a new session

- This file is a handoff brief, not the canonical `CLAUDE.md`. Once Claude Code is installed, distill **Constraints** and **Decisions made** into `CLAUDE.md`, split **Open questions** and **Next concrete steps** into `/docs/roadmap.md` or a `DECISIONS.md` log.
- The original session was in the Cowork desktop app, not Claude Code itself. Project files written in that session land in this workspace folder and persist — they'll be here when Claude Code starts in this directory.
- Owner has 10 years of dev experience. Don't over-explain basics. Lean technical, lean direct.
- Owner is on Apple hardware (so dev machine is macOS — Xcode is local).

## Quick glossary (for the next session's agent)

- **CLAUDE.md** — repo-root markdown file Claude Code reads on every turn. Project context, conventions, current decisions.
- **Subagent** — a specialized agent defined in `.claude/agents/<name>.md` with its own system prompt, tool allowlist, and optional model.
- **Slash command** — reusable workflow defined in `.claude/commands/<name>.md`, invoked as `/<name>`.
- **Hooks** — deterministic actions in `.claude/settings.json` triggered on lifecycle events (save, stop, pre-commit, etc.).
- **MCP server** — external tool integration (GitHub, Linear, etc.) that exposes tools to Claude.
- **Vertical slice** — a feature delivered end-to-end (UI + logic + data + tests) rather than a horizontal layer.
- **HealthKit** — Apple's framework for reading/writing health and fitness data; gated by user-granted entitlements.
- **SwiftData** — modern declarative persistence framework for SwiftUI apps; iCloud-syncing on by default.
- **Fastlane** — Ruby toolchain that automates iOS signing, build, version bumps, TestFlight uploads.
