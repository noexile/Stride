# Decision Log

Append-only. Use `/log-decision` to add entries.

| # | Date | Decision | Rationale |
|---|---|---|---|
| 1 | 2026-05-04 | Persistence: SwiftData | On-device, iCloud sync for free, first-class SwiftUI integration |
| 2 | 2026-05-04 | Backend: on-device only for v1 | Avoid infrastructure complexity; revisit if server sync is needed |
| 3 | 2026-05-04 | Apple Developer account: free for now | Paid account ($99/yr) required before TestFlight; upgrade when ready |
| 4 | 2026-05-04 | Tech stack: deferred | Architect agent will compare Native SwiftUI vs cross-platform in `/docs/architecture.md` |
| 5 | 2026-05-05 | Tech stack: **Native SwiftUI** | HealthKit depth, Apple Watch support, SwiftData integration, single toolchain; cross-platform offers no benefit for an iOS-only app |
| 6 | 2026-05-05 | Join model: `ShoeRunAssignment` explicit join model | Makes assignment timestamps queryable; allows v2 to relax one-shoe-per-run without schema surgery |
| 7 | 2026-05-05 | Mileage storage unit: miles as `Double` | PRD uses miles; convert at HealthKit import boundary; no runtime conversion needed |
| 8 | 2026-05-05 | HealthKit anchor storage: `UserDefaults` | Anchor is a sync cursor, not app data; does not need iCloud sync or model lifecycle |
| 9 | 2026-05-05 | Shoe warning thresholds: 90% approaching / 100% exceeded | Gives a warning lap before the shoe is definitively over threshold; computed at read time, not persisted |
| 10 | 2026-05-05 | Settings: toolbar button, not a tab | Settings content is thin for v1; a tab wastes primary navigation space |
