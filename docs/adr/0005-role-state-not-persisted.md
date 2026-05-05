# 0005 — Developer-mode state is in-memory only; only the password hash persists

**Status**: accepted (2026-05)

**Context**: `RoleService` (`lib/services/role_service.dart`) gates a
small set of dangerous operations behind a developer-mode role —
visibility of the full command surface, custom-command CRUD, and
unrestricted access to `$DEBUG` / `$STARTX` (commands that have caused
real on-site mishaps). The conventional approach for any UI mode
toggle on mobile is to persist the current state and clear it on the
app's lifecycle hooks (background, foreground, terminate). That is
*not* what this app does, and the divergence from convention is
load-bearing.

The reasoning lives today as a doc comment in `role_service.dart`:

> The current role lives **only in memory**. Cold start always starts
> in `UserRole.normal`; the role is never persisted. This is strictly
> safer than persisting + clearing on a lifecycle hook because the
> hook can be missed when the OS kills the process.

That comment carries the rationale, but doc comments don't surface
during architecture reviews. Today's grilling round flagged "every
cold start re-asks for the password" as a UX cost a future reviewer
will reach for. Without a discoverable record of why the cost is paid
deliberately, the rationale gets re-derived (or worse, "fixed").

**Decision**: Split the state. The **password hash** is persisted
(SharedPreferences key `role_dev_password_hash`) so users keep custom
passwords across cold starts and we have a stable factory-default
fallback (`sha256("cg500dev")`). The **active role** is **not**
persisted — every cold start begins in `UserRole.normal`, regardless
of whether the previous run elevated to developer mode. Dev-mode
users (RST field engineers, B Company test engineers, app dev team)
re-enter the password each cold launch.

**Why a process-kill hook isn't enough**: The natural alternative is
"persist current role, clear on `WidgetsBindingObserver` lifecycle
events". The OS — both iOS and Android — can terminate a backgrounded
app process without firing the cleanup callback (low-memory kills,
forced stop, OS upgrade reboot, kernel panic). A persisted "dev mode
active" flag will then survive into the next launch and into whatever
hands the device next. In a deployment scenario where field phones are
shared, lost, or recovered, that's a real exposure of the dangerous
command surface. We do not have a reliable cross-platform mechanism to
invalidate persisted state in **all** termination paths, so we don't
persist it at all.

**The cost is real and acknowledged**: A dev-mode user opens the app a
few times per day during a maintenance visit; that's a few extra
password entries. With the password short and remembered (default is
`cg500dev`, custom passwords have a 4-char minimum), the friction is
seconds per launch. Acceptable for the audience: technical engineers
who already accept friction in exchange for safety in their daily
work.

**Considered alternatives**:
- *Persist the role, clear on lifecycle hook*: rejected for the
  OS-termination reason above.
- *Persist with a timeout (e.g. clear after N minutes background)*:
  rejected — same OS-kill issue applies to any timer-based cleanup,
  plus the timer adds complexity and misses the "phone given to
  someone else without ever backgrounding" case.
- *Don't gate developer mode at all*: rejected outright. `$DEBUG`
  (interrupts normal transmission until reboot) and `$STARTX` (full
  MCU reboot) are gated specifically because of past on-site
  incidents, per CONTEXT.md.
- *Use platform-native secure-storage (Keychain / Keystore) for the
  role state*: rejected. Doesn't change the OS-kill issue; secure
  storage protects the *contents* of the saved state, not the
  *invariant* that it gets cleared.

**Don't reverse this without**: a reliable mechanism to clear the
persisted "developer-mode active" flag in **every** termination path,
including kernel-level process kills on both iOS and Android. As of
2026-05 such a mechanism doesn't exist on either platform.
