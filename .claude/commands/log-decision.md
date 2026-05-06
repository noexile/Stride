Append a new decision to `DECISIONS.md` and update the decisions table in `CLAUDE.md`.

The user will pass the decision as arguments. If no arguments are provided, ask the user: "What's the decision and the rationale?"

Steps:
1. Read `DECISIONS.md` to find the current highest decision number.
2. Read `CLAUDE.md` to find the decisions table.
3. Format the new entry: `| N | YYYY-MM-DD | <decision> | <rationale> |` using today's date.
4. Append the new row to the table in `DECISIONS.md`.
5. If the decision is significant enough to appear in `CLAUDE.md` (i.e., it locks something that was previously open), add it to the decisions table there too and remove it from the Open Questions section if applicable.
6. Confirm what was written.

The argument format is: `<decision> — <rationale>`
Example: `/log-decision Tech stack: Native SwiftUI — HealthKit and SwiftData are first-class, no cross-platform overhead needed`
