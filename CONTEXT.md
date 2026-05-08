# CG500 BLE App — Context

The shared mental model for this project. Defines who the app exists for,
what it is for, and the project-specific terminology that appears
throughout the code, docs, and conversations.

This file captures decisions and language that no amount of code-reading
can recover. If you're an agent or new collaborator, **read this before
proposing structural or product changes**.

## How to read this document

**Provenance.** This file was extracted from the project owner
(it-service@rstltd.org) via a structured grilling session in 2026-05.
The owner is the **sole software developer** of both this app and the
RST-internal data backend it talks to. They are **not a field user** of
the app; they only operate it during testing. The deployment-environment
sections below describe the owner's mental model of the field engineer's
experience — informed by direct feedback from RST field engineers, but
not personally validated. Treat those sections as the owner's working
hypothesis rather than measured ground truth, and prefer feedback from
actual field users when those sections drive concrete UX decisions.

**Where the owner's pain actually lives.** The owner's daily friction is
in the **codebase**, not in the field — legacy debt accumulated over two
years of multi-AI-model development, and the temporary state of using
the GNSS-shaped app for non-GNSS device types (see ADR-0002). UX gaps
that affect field engineers (interruption resilience, dashboard-context
import, structured monitoring data view) are real and acknowledged, but
their priority is gated by the owner's bandwidth for codebase-health
work first. This is a deliberate posture: build a clean foundation
before iterating on user-facing surface.

---

## Language

### Organisations

**RST Ltd** (品牌 / 銷售方):
The brand-owning company. Markets and sells the CG500 device. Employs the
field engineers who deploy CG500 in the field, and runs the team building
this app.
_Avoid_: "vendor" (ambiguous — could mean either RST or B Company).

**Manufacturer Partner** (B公司):
The external company contracted by RST to design the CG500 hardware,
develop its firmware, manufacture it, and ship firmware updates. The
CG500 is sold under the RST brand even though B Company makes it.
_Avoid_: "OEM", "vendor", "manufacturer" (alone — ambiguous).

**Customer**:
The organisation that purchases CG500 devices from RST. Owns the
deployment environment where CG500s are installed. Customers do not
build the app, but their field engineers operate it in normal mode.

### People (the actors who use this app)

**RST field engineer**:
RST employee who commissions CG500 devices on-site. Uses the app in
**developer mode**. Is the primary owner of the deployment outcome.

**Customer field engineer**:
Engineer employed by the customer organisation. Uses the app in
**normal mode** to commission their own purchased devices. Has the
narrowest UI surface (5-command whitelist) deliberately.

**B Company test engineer**:
Tester at the manufacturer. Uses the app in **developer mode** to
validate firmware behaviour against the app — represents the firmware
side of the BLE contract.

**App development team** (RST internal — "我跟你"):
The user (RST Ltd) plus the AI collaborator (Claude). Maintains the
codebase. Operates in developer mode for self-testing. Not a
deployment-time actor.
_Avoid_: "developer" alone — ambiguous with developer-mode users.

### Concepts

**CG500 (the product class)**:
GNSS receiver class within the RST device family. The repository,
app name, and many code paths still use "CG500" as if it were a
single device, but the strategic intent is that this app serves the
whole family (see below). When you see "CG500" in code or docs, treat
it as shorthand for "the device the app is currently configured to
support" — not as a permanent narrowing of scope.

**CG501**:
Next-generation GNSS receiver. Same overall design as CG500 with an
upgraded GNSS chip. As of 2026-05 still in design; the operation
surface is not yet finalised, but the working assumption is that it
is a near-drop-in for CG500 from the app's perspective.

**RST device family**:
The set of BLE devices RST sells that this app is intended to
configure. As of 2026-05 the family contains:
- **GNSS receivers** — CG500 (current, dominant deployed volume),
  CG501 (in design, near drop-in for CG500 from app's perspective).
- **Accelerometers** (加速度計) — derivative product, exists in
  small volumes, not yet widely deployed.
- **Inclinometers** (傾斜感測計) — derivative product, same status as
  accelerometers.

Commands across the family are **mostly shared** (the `$`-prefixed
command surface is largely device-agnostic). Differences are expected
to be in `$INFO` payload contents and possibly a small number of
device-specific commands. Strategic direction is **one app for the
whole family**, not one app per device.

**Device-name prefix convention** (BLE advertising name, as of 2026-05):
- **GNSS receiver** → `A01LT…`
- **Accelerometer** → `B01LT…`
- **Inclinometer** → **prefix not yet defined** (see Flagged
  ambiguities); v26.06's RST-whitelist scanner filter must be
  toggleable specifically because of this gap.

The prefix is matched case-insensitively (`startsWith` after
`toUpperCase`) so future firmware variations don't silently break
classification. Device-type identification by prefix is **scanner-display
only** in v26.06 — it drives the leading icon, the type-grouped list
order, and the whitelist filter, but **does not** drive command-surface
differences, `$INFO` parsing variants, or wizard-step variants. See
ADR-0008 for why this scope is deliberately narrow.

**Important operational asymmetry between device types**:
- **GNSS receivers** allow BLE connections **while online** (4G SIM
  active). An RST engineer can drive up to a deployed CG500 and
  reconfigure it via BLE without taking the station offline.
- **Accelerometers and inclinometers require the device to be
  offline** (no 4G SIM inserted, no Ethernet connected) before BLE
  will accept a connection. To re-configure a deployed accelerometer,
  the engineer must physically disconnect its network link first,
  then reconnect after configuration — a multi-step workflow that
  cannot fit a "quick BLE re-tweak" mental model.

This asymmetry is a hardware/firmware property; the app cannot
override it. UX designed around CG500's always-online BLE access
will silently mis-fit the accel / inclin scenarios, even though the
command surface looks the same.

**Current state of multi-device support in this app**:
Accelerometers and inclinometers currently use this same app as a
**temporary measure** — they happen to work because commands are
shared, but no device-profile abstraction exists in the code (the
12 commands, `$INFO` regex, Quick Setup Wizard steps are all
GNSS-receiver-shaped). The decision to differentiate is intended but
deferred until CG501's spec is finalised, so any device-profile
seam can be designed against two real products instead of one.

**Slope monitoring station** (邊坡監測測站):
The primary deployment role of the RST device family. Each station
detects ground movement / landslide precursors and uploads readings
via cellular (4G) to the RST data backend. A station may pair multiple
device types (GNSS receiver + accelerometer + inclinometer) for
multi-modal sensing — *to be confirmed; see "Open questions" below*.
Failure modes carry public-safety implications: a misconfigured
station can miss a real landslide warning or generate false alarms. So
in this domain, **"correct" beats "fast"** at every UX trade-off.

**Commissioning**:
The **task** of taking a CG500 from "out of the box" to "ready to
operate". Concretely: setting APN, TCP address, FTP update address,
reboot schedule, and verifying via `$INFO`. Performed in two distinct
contexts:
- *In the lab* by a B Company test engineer, validating firmware
  before release.
- *In the field* by an RST engineer (or customer engineer if they're
  self-deploying), when a freshly-arrived station first goes online.

A commissioning task is the same regardless of where it happens, but
the surrounding context (network, weather, time pressure, engineer
expertise) is completely different.
_Avoid_: "configuration", "setup" (too generic), "provisioning".

**Maintenance visit** (現場維護):
A **field engagement** in which an engineer travels to a deployment
site to attend to one or more already-deployed stations. Target
cadence is monthly per station; a single visit covers 3–8 stations.
Maintenance is an umbrella for several distinct tasks (see below) —
not just parameter adjustment.

**Maintenance tasks** (during a visit, the engineer may do any of):
1. **Commissioning** of a newly-installed station encountered in the
   field (RST engineer scenario).
2. **State inspection** — read `$INFO` and `$SHOWP` to confirm the
   station is alive and configured as expected.
3. **Error diagnosis** (排錯) — when a station has been silent or
   misbehaving, narrow down the cause. Uses richer command surface
   (`$DEBUG`, `$SHOWP`, etc.) and is **why developer mode exists** —
   the bare 5-command whitelist isn't enough to diagnose.
4. **Firmware update** — push new firmware via `$FTPADDR` configuration
   and trigger the device's update path.
5. **Parameter drift correction** — change a single value (commonly the
   TCP server address when the backend moves).

**Lab verification** (B Company test engineer's primary use):
Office-based use of the app to validate that a CG500 prototype or new
firmware build behaves correctly — does it accept commands as expected,
does the data it emits look right. Same app, completely different
deployment context (office, well-lit, no time pressure, repeatable
state). Not a maintenance visit.

**Normal mode** vs **Developer mode**:
The app runs in one of two role-gated modes. Normal mode is the default
on cold start and exposes the 5-command whitelist (`$INFO`, `$APN`,
`$ADDR`, `$FTPADDR`, `$REBOOT`). Developer mode requires a password and
exposes the full command surface plus custom commands. Mode is
**in-memory only**, never persisted — every cold start is normal.
_Avoid_: "admin mode", "engineer mode".

**Quick Setup Wizard**:
A guided 4-step form (APN → TCP address → FTP address → reboot hour)
that walks a field engineer through the minimum commissioning settings.
Available to both normal and developer mode users; designed for the
common case so a field engineer doesn't need to type commands.

---

## Relationships

- **RST Ltd** sells **CG500** to **Customer**.
- **Manufacturer Partner** designs, manufactures, and ships firmware
  updates for **CG500**, on behalf of **RST Ltd**.
- **RST field engineer**: does both **commissioning** and full
  **maintenance visits**. Highest task scope. Acts as the escalation
  point for anything a customer engineer can't handle.
- **Customer field engineer**: does **maintenance visits** on their
  own purchased stations. Default model is "you bought it, you maintain
  it" — except when the customer pays RST for a maintenance contract,
  in which case RST takes over and the customer engineer drops out of
  the picture.
- **B Company test engineer**: works in the **office**, not the field.
  Does **commissioning** on prototype / new-firmware devices, plus
  **lab verification** (does CG500 do what we think it does, does the
  data we get back look right). Drives requirements that are
  feature-completeness oriented, not field-resilience oriented.
- **Developer mode** is intended for **RST field engineer**,
  **App development team**, and **B Company test engineer**. It is
  **not** intended for **Customer field engineer**.
- Engineer technical depth varies considerably and intentionally
  shapes the UI: the 5-command normal-mode whitelist is calibrated for
  a customer engineer who is **not** assumed to know the full command
  surface. Developer mode unlocks the surface specifically because the
  three other actor types DO know it.

## Adjacent systems

### RST data backend (server + dashboard)

CG500 stations send their readings via cellular (4G) to a TCP server
that is owned, operated, and developed by RST Ltd — by the same
person who maintains this app (it-service@rstltd.org). The receiving
program and the web dashboard are both internal RST builds.

Important properties:

- **Same human owns both sides.** Integration between this app and the
  backend has no cross-team dependency; it is a self-imposed scope
  boundary that can be revisited at any time.
- **Dashboard is internal-only.** Web-based, accessible only inside the
  RST corporate network. RST personnel can view; **customer engineers
  cannot**. There is currently no exposed API for the BLE app to query.
- **Asymmetric context awareness.** RST engineers arriving at a site
  already know (from the dashboard) how long a station has been silent
  and what its last reading was. **Customer engineers don't have this
  context** — they can only inspect the device in front of them. This
  is a structural reason the customer engineer's maintenance scope is
  narrower.

### App ↔ backend integration: deliberately deferred

As of 2026-05, the BLE app and the data backend are treated as two
independent products with the **option** to integrate left open. The
app's stated current scope is "configure CG500 and future derivative
products"; pulling dashboard context into the app is recognised as
valuable (see UX gaps below) but not yet committed to. Future work
that proposes integration must address: customer-engineer access scope
(they don't have dashboard credentials today), the network reachability
question (dashboard is intranet-only), and whether the integration is
worth the coupling that would result.

## Known UX gaps (surfaced 2026-05; not yet addressed)

These are gaps between the deployment reality (above) and the
current app's behaviour. They are **observed**, not yet **decided** —
listed here so we don't keep re-discovering them in every architecture
review. Future work that touches these areas should reference this
list.

- **Server-side context isn't available in-app.** Engineers arrive at a
  troubled station already knowing (from a server dashboard) how long
  the station has been silent and what its last reading was. The app
  cannot show this; it only talks to the device in front of it. So
  diagnosis happens with the engineer toggling between the dashboard on
  one screen and the app on another, copying context by hand.
- **GPS / monitoring data has no structured view.** Inspecting the data
  a station is producing — important for verification (B Company use
  case) and for diagnosing complex failures (~20% of troubleshooting
  cases) — currently means reading raw `$DEBUG` output in the chat log.
  No formatted view, no parsed values, no historical trace.
- **No interruption resilience.** The deployment environment guarantees
  interruptions (calls, weather, errands), but unsaved input in the
  command interface or the Quick Setup Wizard is lost on backgrounding
  / app kill. Chat history is in-memory only. This is the largest UX
  cost of the current design relative to the actual use case.
- **80/20 asymmetry.** UX is optimised for the 80% of troubleshooting
  cases that resolve in ~5 minutes. The 20% that drag past 30 minutes
  — exactly the cases where state preservation, structured data
  inspection, and dashboard-context import would matter most — receive
  no special accommodation.
- **Dangerous commands carry real-incident history.** `$DEBUG` (breaks
  normal transmission until reboot) and `$STARTX` (full MCU reboot)
  are gated behind dev mode and confirmation dialogs because of past
  on-site mishaps, not just precaution. Any future "shortcut" or
  "advanced mode toggle" UX must preserve this gating.

## Deployment-environment constraints

These constraints follow from the slope-monitoring deployment scene
and shape almost every UX trade-off:

- **Outdoor, mountain terrain** (台灣山區). Implies: bright sunlight,
  rain, possibly gloves, awkward physical postures, single-handed
  operation, low ambient lighting in early morning / dusk maintenance
  windows.
- **Cellular only**. WiFi is effectively never available at deployment
  sites. The app's "WiFi-only download" toggle exists for usability at
  the engineer's home / office, NOT to gate field behaviour.
- **A typical maintenance visit covers 3–8 stations**, ~5–10 minutes of
  app interaction per station. The "next station" flow matters because
  it happens 3–8 times per visit.
- **Interruptions are guaranteed, not exceptional.** Phone calls,
  needing a tool from the truck, weather changes, a mis-step on the
  trail. Any UX flow that loses unsaved input on backgrounding or
  device disconnect is broken by definition. State that's expensive
  to re-enter must persist across app lifecycle events.
- **Failure cost is public-safety**. A station that silently miswarns
  matters more than one that fails loudly. Bias every error path
  toward visible failure over hidden recovery.

---

## Example dialogue

> **Reviewer**: "Why does normal mode only expose 5 commands?"
> **App owner**: "Because the actor in normal mode is the **Customer field
> engineer** — they don't know our internal command surface, they don't
> need it, and showing it would invite mistakes during **commissioning**.
> The 5 commands are everything you need to take a CG500 from box to
> deployable."

> **Agent**: "I'd like to merge `RoleService` and `RoleAwareCommandRepository`
> into one class — they're tightly coupled."
> **App owner**: "The split exists because role lifecycle is shared with
> dev-mode UI controls (password change, reset), while command filtering
> belongs near the repository it filters. Both modules have **App
> development team** as their primary modifier — but for different
> reasons. Read ADR (when written) before merging."

---

## Flagged ambiguities

- "vendor" — used informally for both RST Ltd and Manufacturer Partner.
  Resolved: avoid the word entirely; name the specific organisation.
- "developer" — overloaded between developer-mode users and the App
  development team. Resolved: use **developer mode** for the runtime
  state and **App development team** for the people maintaining the
  codebase.
- "commission" vs "maintenance" — these are **not** mutually exclusive
  axes. **Commissioning** is a task (set a device up); **maintenance
  visit** is an engagement type (engineer travels to a site). A
  maintenance visit may include a commissioning task if a fresh device
  is encountered. Don't model them as separate flows in the UI without
  first establishing why; the same wizard currently serves both.
- **Inclinometer device-name prefix** is undefined as of 2026-05. GNSS
  uses `A01LT…` and accelerometer uses `B01LT…`, but no prefix has been
  assigned to inclinometers — they currently ship under whatever name
  the deployment happens to set. This is **why the v26.06 RST-whitelist
  scanner filter must be toggleable**: a strict-default-on filter
  would render inclinometers invisible to their own users. Resolve when
  a prefix is assigned (likely alongside CG501 spec finalisation per
  ADR-0002), at which point the filter default can be re-evaluated.
