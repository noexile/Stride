# Decision Log

Append-only. Use `/log-decision` to add entries.

| # | Date | Decision | Rationale |
|---|---|---|---|
| 1 | 2026-05-04 | Persistence: SwiftData | On-device, iCloud sync for free, first-class SwiftUI integration |
| 2 | 2026-05-04 | Backend: on-device only for v1 | Avoid infrastructure complexity; revisit if server sync is needed |
| 3 | 2026-05-04 | Apple Developer account: free for now | Paid account ($99/yr) required before TestFlight; upgrade when ready |
| 4 | 2026-05-04 | Tech stack: deferred | Architect agent will compare Native SwiftUI vs cross-platform in `/docs/architecture.md` |
