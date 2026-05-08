# 0008 — Scanner-layer device-type identification; device-profile abstraction stays deferred

**Status**: accepted (2026-05)

**Context**: v26.06 introduces device-name-prefix-based identification:
GNSS receiver (`A01LT…`), accelerometer (`B01LT…`), inclinometer (prefix
not yet defined — see CONTEXT.md Flagged ambiguities). The scanner uses
this to (a) render type-specific icons, (b) group the device list by
type, and (c) optionally filter out non-RST devices via a header toggle.

The classifier — a `RstDeviceType` enum plus a const prefix map — looks
deceptively like the first piece of the device-profile abstraction that
ADR-0002 explicitly defers. The next reader who finds `RstDeviceType` in
`device_type_classifier.dart` will be tempted to thread it through the
command repository, the `$INFO` parser, the Quick Setup Wizard, and the
notification verbosity rules — the natural shape of "let's make the app
device-aware everywhere".

ADR-0002 deferred that work for a specific reason: "design against two
real products instead of one." CG501 is still in design (CONTEXT.md
2026-05). Building the abstraction now means anchoring it to one
finalised product (CG500 GNSS) and one in-flight one — the same risk
ADR-0002 was written to avoid.

**Decision**: `RstDeviceType` and the prefix classifier are
**scanner-display only** in v26.06. They are allowed to drive:

1. The leading icon in the device list and the connected-device card
   (`Icons.satellite_alt` / `Icons.vibration` / `Icons.architecture` /
   `Icons.bluetooth`).
2. The order of devices in the scanner list (groups: GNSS →
   accelerometer → inclinometer → unknown; intra-group order remains
   discovery order).
3. The whitelist-filter behaviour — when the toggle is on, devices that
   don't match a known prefix are hidden.

They are **not** allowed to drive:

- Command repository contents or filtering (`CommandRepository`,
  `CustomCommandRepository`, `RoleAwareCommandRepository` stay
  device-agnostic).
- `$INFO` parsing or `DeviceInfo` field shape (`InfoParserService`
  remains regex-on-the-shared-format).
- Quick Setup Wizard step composition (`stepLabels` / `stepCommands`
  are not device-type-keyed).
- Notification verbosity, role-aware filtering, or any other layer
  beyond the scanner UI.

This boundary is enforced by convention only — there is no compile-time
fence — so this ADR is the discoverable record of where it lives.

The toggle is **persistent** (via `LayoutPreferenceService`),
**default-on**, and **role-agnostic**. Persistence is the right default
for a display preference (contrast with ADR-0005's role state, which is
in-memory because it gates security). Default-on serves the dominant
customer-engineer scenarios (GNSS or accelerometer deployments) without
making them learn a setting; the toggle remains visible in the scanner
AppBar so inclinometer users, B Company test engineers, and RST debug
sessions can opt out without spelunking into Settings.

**Why this matters operationally**: The scanner improvement is a
v26.06-shippable item that does not need to wait for CG501. Forcing it
to wait — or expanding its scope into device-profile territory — would
either delay v26.06 or commit the codebase to an abstraction designed
on incomplete information. Keeping the classifier confined to the
scanner gives field engineers the cleanup they asked for in the
2026-05 meeting while preserving ADR-0002's defer.

**Considered alternatives**:
- *Open the device-profile abstraction now*: rejected. Directly
  contradicts ADR-0002. CG501 spec is still in flight; designing a
  profile seam against one finalised + one in-design product yields a
  shape that will likely need to change once CG501 is real.
- *Show all devices, label only, no filter toggle*: rejected. The
  meeting requirement explicitly asked to «排除名稱格式不符的設備».
  Label-only would silently fail to deliver that.
- *Strict whitelist filter, no toggle (always on)*: rejected.
  Inclinometer prefix is undefined; a default-on filter with no escape
  would render inclinometers invisible to their own users (CONTEXT.md
  Flagged ambiguities pins this).
- *RSSI-based list ordering*: rejected. RSSI fluctuates per advertising
  burst; sorting by it makes the list reorder constantly during a scan,
  causing the engineer to mis-tap. Type-grouped + intra-group discovery
  order is stable and sufficient.
- *Source the device type from `$INFO` after connecting*: rejected.
  Filtering happens pre-connection, so the source has to be the BLE
  advertising name. Also `$INFO` does not carry an explicit device-type
  field today, and adding one would itself be a device-profile move
  (deferred).

**Don't reverse this without**:
- CG501 spec finalised (the precondition ADR-0002 named) AND a
  documented reason that the device-profile abstraction is now
  load-bearing for a specific feature. Re-evaluate the inclinometer
  prefix at the same time — it is the second precondition for tightening
  the filter default.

**Cross-references**: ADR-0002 (one-app scope, device-profile defer),
CONTEXT.md device-name prefix convention, CONTEXT.md Flagged ambiguities
(inclinometer prefix).
