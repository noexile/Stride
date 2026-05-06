# Stride — Product Requirements (v1)

**Date:** 2026-05-05 | **Owner:** noexile | **Status:** Draft

---

## Job-to-be-Done

A dedicated runner wears a shoe past its safe mileage because he has no reliable way to track it. HealthKit records every run — the data is there — but it's not connected to the shoes. The job: **surface the right warning at the right time so the runner retires a shoe before it contributes to injury**, not after.

This is a tracking and alerting job, not a logging job. noexile does not want to manually enter mileage. The app earns its keep by doing the math automatically.

---

## Who It's For

**noexile.** One user. Enthusiast runner, 10 years of dev experience, fully in the Apple ecosystem (iPhone + Apple Watch). He uses HealthKit for all workout tracking. He is also the builder, tester, and sole customer for v1.

No other personas. Build for noexile first; generalize later if there's a reason to.

---

## MVP Scope

**In (v1):**
- Shoe CRUD — name, purchase date, user-set mileage threshold (default: 400 mi)
- Auto-import of running workouts from HealthKit
- Manual assignment of runs to a shoe
- Cumulative mileage per shoe, surfaced clearly
- Warning state when a shoe approaches or exceeds its threshold

**Out (v1 non-goals):**
- Shoe-rotation suggestions or smart assignment
- Multi-shoe-per-run UX
- Social, sharing, or export features
- GPS map rendering
- Shoe database / brand lookup
- Wear surface tracking (road / trail / track) — defer to v2
- Onboarding flow — open directly to the shoe list; add onboarding only if user testing shows confusion

---

## Success Metric

**noexile logs zero new shoes to a spreadsheet or Notes app in the 30 days after v1 ships to his device.** The app is the single source of truth for shoe mileage.

Secondary signal: at least one shoe reaches its threshold and triggers a warning that noexile acts on (retires or adjusts).

---

## Open Questions

| # | Question | Recommendation |
|---|---|---|
| OQ-1 | Default mileage threshold | **400 mi.** Standard guidance for road trainers. Make it user-editable per shoe at creation time. No global default setting needed for v1. |
| OQ-2 | Onboarding flow | **Skip it for v1.** Open directly to the empty shoe list with a clear "Add Shoe" CTA. If a first-run experience is needed, a single tooltip or coach mark is enough — not a multi-screen flow. |
| OQ-3 | Explicit shoe states | **Two states only: Active / Retired.** "In-rotation" adds complexity without a clear v1 job. Active shoes accumulate mileage; Retired shoes are read-only. Model the enum now so v2 can add states without a migration. |
| OQ-4 | Wear surface tracking | **Out for v1.** It's useful data, but noexile doesn't have a job that requires it yet. Add the field as an optional enum on the Run model so it's schema-ready, but don't build UI for it until v2. |
| OQ-5 | Tech stack (Native vs cross-platform) | **Blocked.** Architect agent will resolve this in `/docs/architecture.md` before Slice 1 begins. Do not start implementation until that decision is logged. |

---

*Decisions locked here are the source of truth. Changes require a `/log-decision` entry in `DECISIONS.md`.*
