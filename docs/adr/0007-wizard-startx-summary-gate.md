# 0007 — Quick Setup Wizard auto-sends `$STARTX` after changes; summary page is the gate

**Status**: accepted (2026-05)

**Context**: The Quick Setup Wizard (4 steps: APN → ADDR → FTPADDR →
reboot-hour) currently dispatches the diffed-and-changed commands then
fetches `$INFO` for verification. APN, ADDR, and FTPADDR are network /
modem settings — many of them only take effect after a full MCU reboot
(`$STARTX`). Today the engineer has to remember to send `$STARTX`
manually (or wait for the next scheduled `$REBOOT,<hour>` to fire) before
the new configuration is actually live.

The v26.06 plan extends the wizard to send `$STARTX` automatically after
the verification `$INFO`. Two design pressures collide on this:

1. **CONTEXT.md's safety clause for `$STARTX`** — "past on-site mishaps,
   not just precaution. Any future 'shortcut' or 'advanced mode toggle'
   UX must preserve this gating." Today `$STARTX` is dev-mode-only and
   gated by `DangerConfirmDialog`. The wizard is reachable in normal
   mode. Auto-sending `$STARTX` from the wizard inserts the dangerous
   command into a customer-engineer-reachable flow.
2. **ADR-0006's load-bearing maintenance-review property** — "A
   maintenance run that confirms everything is correct issues zero
   commands." An unconditional reboot at the end of every wizard run
   would make every monthly maintenance visit reboot the station even
   when the engineer just opened the wizard to verify configuration.
   Three to eight stations per visit × 30 seconds of downtime each is
   non-trivial, and CONTEXT.md's public-safety bias ("a station that
   silently miswarns matters more than one that fails loudly") argues
   strongly against unnecessary reboots of healthy stations.

**Decision**:

1. **Conditional dispatch.** `$STARTX` is appended to the dispatch
   sequence **only when at least one diffed command was sent**. A
   review-only run (zero diffed commands) sends nothing — no `$INFO`
   fetch, no `$STARTX`, no disruption. This preserves ADR-0006.

2. **Sequence position.** When triggered, the order is `[diffed
   commands]` → `$INFO` → `$STARTX` → `done` phase. `$INFO` runs *before*
   the reboot because BLE drops within ~30 s of `$STARTX`, and for
   accelerometers / inclinometers BLE may never come back during the
   same session (CONTEXT.md operational asymmetry). Verification has to
   happen pre-reboot or not at all.

3. **The summary page IS the gate.** No separate `DangerConfirmDialog`
   for the auto-`$STARTX`. Instead:
   - The summary page lists `$STARTX` as an explicit row, styled with
     the danger / warning palette (red), with the text «重新啟動設備
     (~30 秒無法連線)».
   - The Apply button copy switches between «套用變更» (no reboot
     needed — won't happen given the conditional rule, but kept for
     symmetry) and «套用變更並重啟» when `$STARTX` will fire.
   - The four prior wizard steps + the summary diff already require the
     engineer to walk through the change set consciously. A second
     dialog over an already-deliberate flow is friction theatre.

4. **Failure handling.** Existing `executeChanges()` failure path
   already covers `$STARTX`: if the BLE write fails, phase becomes
   `failed` and `_failureMessage` carries the step label. The label
   wording for the `$STARTX` failure must explicitly read «設定已套用、
   但重啟指令未送出 — 請手動下 `$STARTX` 或重試» so the engineer doesn't
   walk away believing the prior config writes also failed.

5. **Form steps remain four.** Despite the meeting wording «最後步驟
   新增重新啟動», `$STARTX` is **not** added to `stepLabels` /
   `stepCommands`. It is a post-summary dispatch action, not a form
   step. Adding it as a 5th form step would force the user to enter a
   value for it (none exists) and would conflate config with action.

**Why this matters operationally**: The wizard's primary value in
maintenance is "open, glance, confirm, leave" — possibly without sending
any commands. Adding unconditional reboot would convert that flow into
"open, glance, confirm, reboot the station" every time. The conditional
rule keeps maintenance visits cheap and only pays the reboot cost when
configuration actually changed.

**Considered alternatives**:
- *Unconditional `$STARTX` at end of every wizard run*: rejected.
  Directly breaks ADR-0006's zero-commands-on-clean-review property and
  forces a 30-second downtime per maintenance visit per station.
- *Wrap auto-`$STARTX` in `DangerConfirmDialog`* (mirroring the
  command-interface gate): rejected. The summary page already chains
  four conscious steps + a labelled, coloured «重新啟動設備» row + a
  button whose copy explicitly names the reboot. The dialog adds
  friction without adding information; engineers running this flow 3-8
  times per visit would learn to dismiss it reflexively, defeating its
  purpose. The wizard's safety profile differs from "user freely typed
  `$STARTX` in the chat interface" — that is the situation
  `DangerConfirmDialog` was designed to catch.
- *Skip `$INFO` and reboot immediately*: rejected. The verification
  step exists today and removing it for the change-and-reboot path
  would create an asymmetry — the no-change path verifies, the
  change path doesn't. Keep them symmetric; `$INFO` runs before the
  reboot in both branches.
- *Use `$TCPX` instead of `$STARTX`*: rejected. `$TCPX` only resets the
  TCP flow — it does not re-initialise the 4G modem, so a new APN sent
  via the wizard would not take effect. The wizard explicitly changes
  modem-level config (`$APN`); only `$STARTX` makes those changes live.

**Don't reverse this without**:
- A documented field complaint that the auto-reboot is harming a real
  workflow (e.g. engineers losing concurrent BLE work the reboot
  killed). As of 2026-05 there is no such complaint — this ADR records
  a forward-looking design choice, not a remediation.
- Or, an alternative way to make APN / ADDR / FTPADDR changes take
  effect without a full MCU restart (firmware change beyond this app's
  scope).

**Cross-references**: ADR-0002 (one-app scope), ADR-0006 (wizard
dual-purpose, diff-driven), CONTEXT.md `$STARTX` safety clause and
operational asymmetry section.
