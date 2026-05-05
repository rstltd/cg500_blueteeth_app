# 0004 — `CommandManager` is a shared instance across two ViewModels

**Status**: accepted (2026-05)

**Context**: `CommandManager` (`lib/controllers/command_manager.dart`)
holds a `TextEditingController`, a 20-item command history, and a
`sendCommand` pipeline that routes outgoing commands to the BLE
controller and emits chat-log messages via callback. Read in
isolation alongside `CommandInterfaceViewModel`, it looks like a
shallow orchestration layer — its public methods bounce calls to the
controller and mutate local state, with no business logic of its own.

Today's morning architecture audit (an Explore subagent applying the
"deletion test") proposed absorbing `CommandManager` into
`CommandInterfaceViewModel`. Verification of all consumers refuted the
proposal:

- `CommandInterfaceViewModel` constructs the manager and wires its
  `onMessageAdded` callback into the chat log.
- `QuickSetupWizardView._openQuickSetupWizard()` opens
  `QuickSetupWizardView` with **the same `CommandManager` instance**
  passed through, so the wizard's APN / ADDR / FTPADDR / REBOOT
  commands route through the same chat-log callback and history list
  as manually-typed commands.
- Three widgets (`CommandInputPanelWidget`, `CommandHistoryPanelWidget`,
  `ConnectionStatsPanelWidget`) bind directly to the shared
  `TextEditingController` and read `commandHistory` for display and
  tap-to-fill behaviours.

Five consumers, not one. The deletion test, properly scoped, shows
complexity reappearing across all five if the manager is dissolved.

**Decision**: Keep `CommandManager` as a manually-passed shared
instance between `CommandInterfaceViewModel` and `QuickSetupViewModel`.
The widget bindings to its `textController` and `commandHistory` are
intentional: the chat-log message stream and history navigation are
shared state, not per-VM state.

**Why "shallow" was the wrong read**: The deletion test must consider
**every** consumer, not the first one read. A single-VM view of
`CommandManager` exhibits low-density indirection (each public method
is a thin shim). The full consumer set — two view models plus three
widgets — exhibits real depth: a small interface (text controller +
history + send pipeline + callbacks) underwrites coordinated
behaviour across the command-input subsystem. That qualifies the
module as **deep**, not shallow, in the project's own architecture
vocabulary.

**Considered alternatives**:
- *Absorb `CommandManager` into `CommandInterfaceViewModel`*: rejected.
  `QuickSetupViewModel` would need either a new abstraction to send
  commands while routing to the chat log, or a direct dependency on
  `CommandInterfaceViewModel`. Widgets would have to bind through the
  VM. Net: more coupling among unrelated layers, not less.
- *Make wizard commands bypass the chat log*: rejected. The chat log
  is how field engineers verify their commands actually went through
  and observe the device's response. Suppressing wizard commands from
  the log breaks the troubleshooting feedback loop and reduces parity
  between wizard-issued and manually-issued commands.
- *Construct two `CommandManager` instances and synchronise them*:
  rejected outright. Shared state via duplication is strictly worse
  than shared state via shared instance.

**Don't reverse this without**: tracing the full consumer set first.
The shallowness illusion this module presents is the canonical case
for the global "verify subagent claims; the deletion test must check
every caller" rule (see `~/.claude/CLAUDE.md`). Any future proposal
to absorb / collapse / split this module must enumerate ALL five
current consumers in writing and explain how each survives the
change.
