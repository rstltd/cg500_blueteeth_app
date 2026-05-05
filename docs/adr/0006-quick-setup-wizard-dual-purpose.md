# 0006 — Quick Setup Wizard is dual-purpose: commissioning AND maintenance review

**Status**: accepted (2026-05)

**Context**: The "Quick Setup Wizard" (`QuickSetupViewModel` +
`QuickSetupWizardView`) presents a 4-step form for APN → TCP address
→ FTP address → reboot hour. Read at face value — and judging only
from its name — it appears to be a first-time-deployment helper:
"open it for a fresh CG500, fill in 4 values, done."

That reading misses the actual design. Today's grilling session
(captured in CONTEXT.md) split commissioning and maintenance into
two distinct activities:

- **Commissioning** is a task: take a device from out-of-the-box to
  ready-to-deploy. Needs all 4 values entered from scratch.
- **Maintenance visit** is a recurring engagement: monthly at deployed
  stations, ~5–10 minutes per station, often just confirming the
  configuration is unchanged or correcting a single drifted value
  (commonly the TCP server address when the backend moves).

The wizard is intentionally engineered to serve **both**:

1. `QuickSetupViewModel.initializeWithInfo(DeviceInfo info)` seeds the
   form with current `$INFO` values (commissioning sees defaults or
   empties; maintenance sees current production values).
2. `_pendingCommandsFromState()` diffs the user's edits against the
   originals and **only includes commands for fields that actually
   changed**. A maintenance run that confirms everything is correct
   issues zero commands. A run that fixes one drifted IP issues one
   command, not four.
3. The summary page shows the diff (old → new) per pending command,
   so engineers verify what they're about to change.

This is not emergent. The name is "Quick Setup" but the implementation
is closer to "review-and-selectively-update".

**Decision**: The Quick Setup Wizard intentionally serves both
commissioning and maintenance. The pre-fill behavior, the
diff-and-send-only-changes pipeline, and the summary review page are
load-bearing for the maintenance use case. They are NOT bugs to "fix"
when looking at the wizard from a first-time-setup lens.

**The naming is a separable concern**: "Quick Setup" emphasises
commission-style use; future renaming (e.g. "Station Configuration"
or "Review & Update") could clarify the dual-purpose intent without
changing any of the load-bearing behavior. That rename is a UX-cleanup
task, not an architectural one — keep them separate.

**Why this matters operationally**: A CG500 is commissioned once but
maintained monthly for years. A typical station's lifetime sees one
commissioning event and dozens to hundreds of maintenance touches.
Optimising the wizard for the rare event (commissioning) at the
expense of the frequent one (maintenance) would be a UX regression
even if it makes the first-time experience marginally cleaner.

**Considered alternatives**:
- *Make the wizard commission-only (clear pre-filled values, always
  send all 4 commands)*: rejected. Breaks maintenance: every monthly
  visit would re-send 4 commands per station, briefly disrupting
  configuration, and forcing engineers to re-type values they have
  no intent to change.
- *Build a separate "Maintenance Review" UI alongside the wizard*:
  rejected. Two parallel UIs for nearly-identical workflows multiply
  the surface to test, the bugs to fix, and the engineer's mental
  model to maintain. The diff-send pipeline already adapts to both
  intents transparently.
- *Remove the diff and always send all 4 commands when the user
  clicks "Apply"*: rejected for the same operational reason as the
  first alternative — sends unnecessary commands and removes the
  visible-change-set the summary page provides.

**Don't reverse this without**: a concrete operational complaint that
the dual-purpose design confuses commissioning users. As of 2026-05
there is no such complaint on file; commissioning users see empty /
default values pre-filled (still safe to enter from scratch),
maintenance users see live values pre-filled (saving time).
