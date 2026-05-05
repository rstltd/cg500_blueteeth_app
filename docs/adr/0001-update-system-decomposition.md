# 0001 — Update system: 4 narrow services + UpdateController, not a single facade

**Status**: accepted (2026-05)

**Context**: The original update flow lived in a single 830-line
`UpdateService` with six responsibilities (version check, download, install,
preferences, retry policy, network awareness). It was untestable in isolation,
its preferences mutator was the only write path so every UI consumer held a
private copy of preferences, and "fix one thing" PRs routinely touched four
unrelated areas of the file.

**Decision**: Split `UpdateService` into four narrow services
(`UpdateChecker`, `DownloadManager`, `InstallManager`,
`UpdatePreferencesStore`) and put a single `UpdateController` above them as
the state owner + flow coordinator. `UpdatePreferencesStore` is the single
broadcast source for preference changes via its `changeStream` — no caller
holds a private snapshot. `UpdateController` extends `ChangeNotifier` so any
widget that renders update state can `ListenableBuilder` it.

**Consequences**:
- Each of the four services has a single mockable responsibility, so unit
  tests can exercise (e.g.) retry behaviour without spinning up the whole
  flow.
- The "where do I put new code?" question now has an obvious answer per
  responsibility, instead of one giant file.
- The 5-dependency constructor on `UpdateController` is genuinely longer than
  the previous singleton API was, but that cost is paid once at construction
  and unblocks targeted testing.
- **The split looks suspicious from the outside.** A reviewer scanning
  `lib/services/` sees four short files all about updates and naturally
  proposes "merge these into one `UpdateService`." This ADR exists so that
  proposal can be rejected without re-deriving the rationale.

**Considered alternatives**:
- *Keep the original single `UpdateService`*: rejected. The testability and
  state-ownership problems above were the original motivation.
- *Single `UpdateOrchestrator` facade with the four services as private
  members*: rejected. The current shape exposes the four services to the
  service locator anyway (so anything that needs only `DownloadManager` —
  e.g. a download-progress widget — can inject just that, instead of the
  whole orchestrator). A facade adds a layer of indirection without
  improving testability or reducing state.
- *Merge the four services back behind `UpdateController` as private
  collaborators*: rejected for the same reason.

**Don't reverse this without**: enumerating which of the four services no
longer benefit from independent testing, AND demonstrating that the
preference-broadcast pattern survives the merge. If `UpdatePreferencesStore`
goes away, every UI consumer goes back to holding stale snapshots — that was
the original bug.
