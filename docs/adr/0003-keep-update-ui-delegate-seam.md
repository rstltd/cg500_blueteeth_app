# 0003 — Keep `UpdateUIDelegate` as a UI / logic seam in `UpdateController`

**Status**: accepted (2026-05)

**Context**: `SIMPLIFICATION_PLAN.md` (2024-12-09, Phase 1) listed
`UpdateUIDelegate` among the eight single-implementation interfaces
marked for removal. Phases 2 and 3 of that plan executed — `UpdateService`
was decomposed (see ADR-0001) and the other seven interfaces deleted —
but `UpdateUIDelegate` survived. The reasoning was never recorded, so
today's architecture audit re-raised the question and we re-derived the
answer. Without an ADR this loop will repeat on the next review.

**Decision**: Keep `UpdateUIDelegate`. It separates UI side-effects
(showing SnackBars for installation status, showing skip-version
confirmation dialogs, closing in-flight update dialogs) from
`UpdateController`'s flow logic. Production wires a thin
`const UpdateUIDelegate()` that calls `ScaffoldMessenger` and
`showDialog` directly. Tests inject `MockUpdateUIDelegate` to drive
non-trivial flows (skip confirmation paths, installation-failed
handling, dialog lifecycle on update completion) without standing up
a full widget tree.

**Why this is a real seam, not a hypothetical one**: The project
applies the rule "one adapter means a hypothetical seam, two adapters
means a real one". `UpdateUIDelegate` has exactly two: the production
const-instance and `MockUpdateUIDelegate` in
`test/mocks/mock_services.dart`. The test mock is not a speculative
"future variation" — it actively underwrites the unit-test coverage
for `UpdateController`'s UI-coupled logic. Removing it would force
every such test into Flutter widget-test scaffolding (BuildContext +
dialog stack), or push the UI calls into a private helper that test
mocks would have to replicate by other means. Both alternatives cost
more than the delegate's surface area.

**Considered alternatives**:
- *Inline the UI calls into `UpdateController`* (SIMPLIFICATION_PLAN's
  stated intent): rejected. Would force every `UpdateController` test
  to set up a widget tree, ballooning test setup complexity for what
  is currently a small mock.
- *Split `UpdateController` into a logic core plus a UI-aware
  wrapper*: rejected. Same testing benefit as the delegate, but
  introduces a "which one do I inject?" question for view-model
  consumers without commensurate gain.

**Don't reverse this without**: an alternative testing strategy for
`UpdateController`'s UI-coupled flows (skip confirmation, installation
result, dialog lifecycle) that doesn't drag the full Flutter widget
test environment into every relevant test.
