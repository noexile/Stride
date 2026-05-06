# Stride — Architecture

**Date:** 2026-05-05 | **Author:** architect agent | **Status:** Locked (pending `/log-decision` entries)

---

## 1. Tech-Stack Decision: Native SwiftUI

### Comparison

| Dimension | Native SwiftUI | React Native | Flutter |
|---|---|---|---|
| HealthKit access | Full, first-class. Every `HKSampleType`, background delivery, `HKAnchoredObjectQuery` — all supported. | Partial. Community bridges (`react-native-health`) lag Apple's SDK by one or more WWDC cycles. Background delivery is fragile. | Minimal. Plugin ecosystem is thin; background delivery is unsupported or unsupported reliably. |
| Apple Watch | Native WatchKit / SwiftUI on watchOS. Shared business logic via Swift package. | Not viable. No official Watch support; community packages are abandoned or incomplete. | Not viable. Same situation as RN. |
| SwiftData | Native `@Model` / `@Query`; iCloud sync works out of the box. | No SwiftData support. Would require SQLite bridge or REST sync layer — both add complexity not budgeted for v1. | No SwiftData support. Same constraint. |
| Xcode toolchain | Required for deploy regardless of stack. No extra layer needed. | Xcode + Metro bundler + JS runtime. Two toolchains; debugging spans both. | Xcode + Dart VM + Flutter toolchain. Three toolchains. |
| Long-term maintenance | Apple changes break one layer: Swift/SwiftUI APIs. | Apple changes break two layers: the JS bridge and the native module. Community bridges often go unmaintained. | Apple changes break two layers: the platform channel and Dart bindings. Flutter team patches quickly, but it's still a lag. |
| Owner's skill set | 10 years of dev, Apple ecosystem, first iOS project. Reading Swift is natural. SwiftUI is the right on-ramp. | Transfers JS/TS skills, but the native bridge layer where HealthKit lives requires writing Swift or ObjC anyway. | Dart is a new language with no payoff beyond Flutter. |

### Recommendation: Native SwiftUI — locked

The deciding factors, in order:

1. **HealthKit is the product.** Every feature in v1 touches HealthKit. A bridge that lags Apple's SDK or doesn't support background delivery is not a trade-off — it's a missing feature. Native is the only path with full, reliable access.
2. **Apple Watch is a constraint, not a nice-to-have.** noexile tracks workouts on Watch. React Native and Flutter cannot target watchOS. Native SwiftUI can, using the same Swift codebase and shared logic.
3. **SwiftData is already decided.** Decision 1 in `DECISIONS.md` locks SwiftData. Cross-platform frameworks cannot use it. Adding an ORM or sync layer to compensate is unnecessary complexity for a solo project.
4. **Toolchain simplicity.** iOS-only + Xcode-required = one toolchain. Adding a second (Metro, Dart VM) for no architectural gain is pure overhead.
5. **Skill set fit.** Ten years of general dev experience with deep Apple ecosystem familiarity is the right foundation for SwiftUI. The learning curve is the Swift language and SwiftUI idioms — both are worth learning because this is explicitly an iOS project.

Cross-platform frameworks exist to share code across platforms. There are no other platforms here. Their trade-offs buy nothing.

---

## 2. Data Model

All models are SwiftData `@Model` classes stored in the default `ModelContainer`. Relationships are SwiftData `@Relationship` properties with cascade or nullify delete rules as noted.

### Shoe

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key, auto-generated |
| `name` | `String` | Required; user-entered (e.g., "Nike Pegasus 41") |
| `purchaseDate` | `Date` | Required |
| `mileageThreshold` | `Double` | Miles; default 400.0; user-editable per shoe |
| `status` | `ShoeStatus` (enum) | `active` or `retired`; default `active` |
| `notes` | `String?` | Optional free-text; no v1 UI required but schema-present |
| `assignments` | `[ShoeRunAssignment]` | Inverse of `ShoeRunAssignment.shoe`; cascade delete |

`ShoeStatus` enum cases: `active`, `retired`. Stored as raw `String` so future cases (`inRotation`, etc.) extend without a migration.

Computed at read time (not persisted):
- `totalMileage` — sum of `assignment.run.distanceMiles` for all assignments
- `warningState` — derived from `totalMileage` vs `mileageThreshold`; threshold at 90% for "approaching", 100% for "exceeded"

### Run

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key, auto-generated |
| `healthKitWorkoutId` | `UUID` | HealthKit `HKWorkout.uuid`; unique index; used for dedup on re-sync |
| `startDate` | `Date` | From HealthKit |
| `endDate` | `Date` | From HealthKit |
| `distanceMiles` | `Double` | Converted from HealthKit's `HKUnit` at import time; stored in miles |
| `sourceName` | `String?` | HealthKit source (e.g., "Apple Watch"); informational |
| `wearSurface` | `WearSurface?` (enum) | Optional; schema-present, no v1 UI. Cases: `road`, `trail`, `track` |
| `assignment` | `ShoeRunAssignment?` | Inverse of `ShoeRunAssignment.run`; nullify on delete |

`WearSurface` enum stored as raw `String` for forward-compatibility.

### ShoeRunAssignment

Join model between `Shoe` and `Run`. A Run is assigned to at most one Shoe at a time (v1 constraint; relax in v2 if multi-shoe-per-run is needed).

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key |
| `shoe` | `Shoe` | Required; nullify delete on Shoe (assignment deleted when Shoe deleted) |
| `run` | `Run` | Required; unique — a Run appears in at most one assignment |
| `assignedAt` | `Date` | Timestamp of assignment action; default `Date.now` |

Uniqueness of `run` is enforced at the application layer before insert (query for existing assignment before creating a new one). SwiftData does not have a native unique-constraint annotation in the current SDK; enforce in the repository/service layer.

---

## 3. HealthKit Boundary

### Data types read

| Type | HKIdentifier | Why |
|---|---|---|
| Running workouts | `HKWorkoutType` filtered to `HKWorkoutActivityType.running` | Primary data source |
| Running distance | `HKQuantityTypeIdentifier.distanceWalkingRunning` associated with each workout | Mileage calculation |

Nothing else is read. No heart rate, no route data, no sleep. The privacy surface is minimal by design.

### Permissions

One `HKHealthStore` authorization request at first launch, requesting read access to:
- `HKObjectType.workoutType()`
- `HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)`

Write access is never requested. The app is read-only from HealthKit's perspective.

If the user denies permission, the app degrades gracefully: show the shoe list with a banner explaining that HealthKit access is needed to import runs. Do not block the shoe CRUD flow.

### Sync strategy

Use `HKAnchoredObjectQuery` to fetch workouts incrementally:

- On first sync: query all running workouts with no anchor; persist the returned anchor.
- On subsequent syncs: query using the stored anchor to fetch only new or deleted workouts since last sync.
- Trigger sync on app foreground (`scenePhase == .active`) and optionally on a background refresh (if Background App Refresh entitlement is added later).
- Deduplicate by `HKWorkout.uuid` matched against `Run.healthKitWorkoutId`. If a UUID already exists, skip. If HealthKit reports a deletion, mark the corresponding `Run` with a soft-delete flag or remove it (TBD by ios-engineer; recommend removal for v1 since deleted workouts are rare and orphaned assignments are confusing).
- The HealthKit anchor is stored in `UserDefaults` (not SwiftData) — it is a sync cursor, not app data.

### Privacy

- All HealthKit data stays on-device. Nothing is sent to a server (no server exists for v1).
- No HealthKit data appears in logs. The `sourceName` field is informational only and never transmitted.
- iCloud sync (via SwiftData / CloudKit) does sync `Run` records to the user's private CloudKit container. This is the user's own data in their own container — acceptable. The HealthKit data itself is not re-uploaded; only the derived `distanceMiles` and metadata are synced.

---

## 4. Persistence Strategy

### SwiftData schema

Single `ModelContainer` configured at app entry point with all three model types: `Shoe`, `Run`, `ShoeRunAssignment`. No manual schema version needed at launch; SwiftData infers the initial schema.

iCloud sync is enabled by default when the app's bundle includes a CloudKit container entitlement. Add `com.apple.developer.icloud-containers` pointing to `iCloud.com.noexile.Stride` (or equivalent) in the entitlements file. SwiftData handles CloudKit schema push automatically on first run.

### iCloud sync behavior and gotchas

- **CloudKit sync is async and eventual.** Writes appear locally immediately; propagation to other devices can take seconds to minutes. For a solo, single-device app this is a non-issue in v1 but worth knowing.
- **Required fields must be optional in CloudKit.** CloudKit does not support truly non-optional attributes in its schema for new records synced from a second device that may be on an older schema version. SwiftData abstracts this, but if a migration adds a new non-optional field, it must have a default value. Enforce this discipline from the start.
- **`HKWorkout.uuid` is device-scoped, not iCloud-scoped.** If the user ever runs this app on a second device (not a v1 scenario), HealthKit on that device will have different UUIDs for the same workouts. The dedup key would fail. Note this for v2 if multi-device becomes a requirement.
- **CloudKit schema is additive-only.** Once a field is pushed to CloudKit production, it cannot be removed without creating a new container. For v1, keep the schema lean — the optional `wearSurface` and `notes` fields are already schema-present, so they don't need to be added later.

### Migration plan

SwiftData supports `VersionedSchema` and `SchemaMigration` for handling model changes between app versions.

- **v1 → v2 (anticipated changes):** Adding `WearSurface` UI, adding `inRotation` to `ShoeStatus`. Both are already schema-present as optional/extensible types, so no migration is needed for data — only for UI.
- **If a structural migration is required** (e.g., splitting a field, changing a relationship cardinality): define a `VersionedSchema` enum with `SchemaV1` and `SchemaV2` types, write a `MigrationStage` (lightweight if only adding optional fields, custom if data transformation is needed), and register the migration plan with the `ModelContainer`.
- **Golden rule:** never remove a field or change a field type in-place. Always add new fields with defaults and migrate data in a custom stage if needed.

---

## 5. Screen Flow

### Screens

| Screen | Description |
|---|---|
| Shoe List | Root screen. All shoes, each showing name, current mileage, threshold, and warning state. "Add Shoe" button. |
| Add Shoe | Sheet or modal form. Name, purchase date, mileage threshold (default 400 mi). Save creates a `Shoe` in Active state. |
| Shoe Detail | Tapped from Shoe List. Shows full shoe stats and the list of runs assigned to this shoe. Entry point to assign/unassign runs. Retire action available here. |
| Run List | Full list of imported runs not yet assigned to any shoe, or all runs (tab filter TBD). Each row shows date, distance, source. Tap to assign. |
| Assign Run (sheet) | Triggered from Run List or Shoe Detail. Picker to choose which shoe to assign a run to. Creates a `ShoeRunAssignment`. |
| Settings | Minimal for v1. HealthKit permission status and a "Re-sync HealthKit" action. No global preferences needed. |

### Navigation structure

- **Tab bar with two tabs:**
  - Tab 1 — Shoes (`Shoe List` → `Shoe Detail`, with `Add Shoe` as a sheet from `Shoe List`)
  - Tab 2 — Runs (`Run List`, with `Assign Run` as a sheet from a run row)
- **Settings** is reachable from a toolbar button (top-right of either tab's root), not a separate tab — it doesn't warrant primary navigation real estate in v1.
- All drill-down navigation within a tab uses `NavigationStack` with `.navigationDestination`.
- Sheets are used for create/edit actions (`Add Shoe`, `Assign Run`) to preserve the user's place in the nav stack.

---

## New Decisions to Log

The following decisions were made in this document and must be recorded via `/log-decision`:

| # | Decision | Outcome | Rationale summary |
|---|---|---|---|
| 5 | Tech stack | **Native SwiftUI** | HealthKit depth, Watch support, SwiftData integration, toolchain simplicity; cross-platform frameworks offer no benefit for an iOS-only app |
| 6 | Join model | **`ShoeRunAssignment`** explicit join model | Makes assignment timestamps queryable; allows v2 to relax the one-shoe-per-run constraint without schema surgery |
| 7 | Mileage storage unit | **Miles, stored as `Double`** | PRD uses miles; convert at HealthKit import boundary; no runtime conversion needed |
| 8 | HealthKit anchor storage | **`UserDefaults`** (not SwiftData) | Anchor is a sync cursor, not app data; does not need iCloud sync or model lifecycle |
| 9 | Shoe warning thresholds | **90% = approaching, 100% = exceeded** | Gives the runner a warning lap before the shoe is definitively over threshold; computed at read time, not persisted |
| 10 | Settings access | **Toolbar button**, not a tab | Settings content is thin for v1; a tab wastes primary navigation space |

---

*This document is the source of truth for system design. Implementation begins only after the decisions above are logged in `DECISIONS.md`.*
