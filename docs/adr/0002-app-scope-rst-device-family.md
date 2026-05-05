# 0002 — App scope: one app for the whole RST device family

**Status**: accepted (2026-05)

**Context**: The repository, app name (`cg500_blueteeth_app`), and most
in-code identifiers are CG500-specific. CG500 is, however, only one
class within RST's BLE device family (GNSS receivers, accelerometers,
inclinometers; CG501 next-gen GNSS receiver in design). Accelerometers
and inclinometers already use this same app today as a temporary
measure — they happen to work because the command surface is mostly
shared, but no device-profile abstraction exists in the code.

A reasonable reviewer reading the codebase will assume "this app is
for CG500" and either propose narrowing it (don't break CG500 by
adding generality) or splitting accelerometer / inclinometer support
into separate apps. Both reactions miss the strategic intent.

**Decision**: One unified app serves the entire RST device family.
The single-app stance is chosen for unified user experience (engineers
learn one tool) and engineering economics (avoid maintaining N parallel
codebases, N release pipelines, N sets of tests). The current
CG500-shaped code is acknowledged as a starting point that will need
a device-profile seam, but that seam is **deliberately deferred**
until CG501's operation surface is finalised — designing the
abstraction against one real product invites guessing wrong; designing
it against two reduces the risk substantially.

**Consequences**:
- Future contributors must not "rename for clarity" by hardcoding
  CG500 deeper into UI or domain models. The repo / app name is a
  legacy artifact, not a scope statement.
- New work that touches the command surface, `$INFO` parser, or
  Quick Setup Wizard should consider whether it generalises. If it
  doesn't, that's fine — but the code should make it visible (e.g.
  comment "GNSS-specific") so that the eventual device-profile
  refactor can find these spots.
- Accelerometer / inclinometer commissioning has an operational
  asymmetry vs GNSS receivers (must be offline to BLE-connect — see
  CONTEXT.md). Any UX flow that leans on CG500's always-online BLE
  access will silently mis-fit those device types.
- The repo and app names are likely to be renamed at some point. That
  is a separable, low-priority cost; it does not block the design
  evolution.

**Considered alternatives**:
- *Split into per-device apps*: rejected. Multiplies cost without
  multiplying value; the engineer audience is the same and prefers a
  single tool.
- *Refactor to device-agnostic now, before CG501 ships*: rejected.
  The right abstraction shape isn't visible from a single example
  (CG500), and we already know one of the next data points (CG501).
  Building the seam against speculation has high regret cost; building
  it against two known data points has low regret cost.
- *Restrict app to CG500-only and write a separate accelerometer app
  later*: rejected. Same reasons as the per-device-apps alternative,
  but worse because the existing accelerometer use is already working
  in this app — undoing it would create a regression to fix a problem
  that doesn't yet hurt.

**Don't reverse this without**: a concrete operational complaint that
the unified app costs more than it saves (e.g. accelerometer users
materially confused by GNSS-shaped UX), AND a plan for what happens to
the existing accelerometer / inclinometer customers who've already
adopted the current setup.
