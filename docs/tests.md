# Tests

Open in-game checks. `/reload` before testing; report Lua errors and pass/fail per item.

## Forever: rogue combo points

Class power keeps the old combo points after changing target. Is this a `libs/oUF` bug (`UnitPower` + no
`PLAYER_TARGET_CHANGED`) or a stale `UnitPower`? Macro (`4` = `Enum.PowerType.ComboPoints`):
`/dump UnitPower("player", 4), GetComboPoints("player", "target"), UnitPowerMax("player", 4)`

- [x] Baseline: build 3 points on mob A; macro returns `3, 3, 5` and the class power bar shows 3. Confirmed 2026-11-10.
- [x] Per target? Keep A alive and target mob B: macro and bar. `3, 0, 5`: `UnitPower` keeps A's points,
      `GetComboPoints` is per target. Neither is secret (PvE). Confirmed 2026-11-10.
- [ ] Blizzard reference (Tainted disabled): repeat A → B; Blizzard's combo points on the target frame.
- [x] Back to A: are the 3 points still there (kept per target), or gone? Kept: 2 points on A → target
      self → A, Eviscerate usable. Confirmed 2026-11-10.
- [x] Decisive: 3 points on A, target untouched B (`3, 0, 5`), Eviscerate B. Fails / 0-point damage
      = per target; casts with 3-point damage and `UnitPower` → 0 = per player (bar correct).
      Per target: 2 on A, B reads `2, 0, 5`, Eviscerate unusable on B; back to A it works, then `0, 0, 5`.
      `UnitPower` follows the combo target, not the current target. Confirmed 2026-11-10.
- [x] Clear target (`Esc`): macro and bar. `2, 0, 5` (no error), retarget A `2, 2, 5`. Confirmed 2026-11-10.
- [x] Friendly or no target after building on A: macro. Self: `2, 0, 5`, back to A `2, 2, 5`. Confirmed 2026-11-10.
- [x] Build on B after A: points on A after switching back (only one combo target at a time?).
      One combo target: A `2, 2, 5` → build 1 on B `1, 1, 5` → back to A `1, 0, 5`. Confirmed 2026-11-10.
- [x] Events: `/etrace`, then switch targets; check whether `UNIT_POWER_UPDATE`/`UNIT_POWER_FREQUENT`
      (player, `COMBO_POINTS`) or `COMBO_TARGET_CHANGED` fire on switch. All fire on Forever:
      `PLAYER_TARGET_CHANGED` per switch, `UNIT_POWER_*` (ENERGY/COMBO_POINTS), one `COMBO_TARGET_CHANGED`.
      Confirmed 2026-11-10.
- [ ] Secret: macro in combat, and in PvP vs a player; `issecretvalue` on both results.

Expected readings:
- `UnitPower` follows the target and an event fires: the bug is oUF missing a refresh.
- `UnitPower` follows the target and nothing fires: register `PLAYER_TARGET_CHANGED` and force an update.
- `UnitPower` stays at 3 while `GetComboPoints` = 0: read `GetComboPoints(unit, "target")` (as `oUF_Classic` does).

## Era: swing timer (oUF_Classic `elements/swing.lua`, combat log)

- [x] Globals: `IsDualWielding` exists, `SWING_TIMER_MAIN_HAND` is nil, labels use `INVTYPE_*`. Confirmed 2026-11-16.
- [x] Wand (priest Shoot): ranged bar per shot. Confirmed 2026-11-16.
- [x] Melee 2H (priest staff): main-hand bar restarts on each swing. Confirmed 2026-11-16.
- [x] Hunter Auto Shot: ranged bar replaces the melee bars. Confirmed 2026-11-16.
- [x] Dual wield: main-hand and off-hand bars run independently. Confirmed 2026-11-16.
- [ ] Next melee: hunter Raptor Strike or druid Maul restarts the main-hand bar when it lands, not on press
      (Heroic Strike/Cleave share the code path, no warrior on Era).
- [ ] Speed change mid-swing: rogue Slice and Dice, or a mob slow; the running bar rescales without jumping.
- [ ] Parry haste: rogue/hunter/paladin facing a slow-hitting mob; on a parry the main-hand bar jumps forward.
- [ ] Off hand removed: off-hand bar stays hidden in combat.
- [ ] Combat leave: bars hide once the last swing ends.
- [ ] Weapon swap in combat: that bar resets, restarts on the next swing.
- [ ] Other clients: `/reload` on Forever (unchanged) and MoP/TBC (no load errors, element inactive).

## Retail/Forever: interrupt announcer (`modules/miscellaneous/interrupts/mainline.lua`)

Plan and findings: `docs/interrupts.md`. Needs a party (a second account for the teammate cases). The
probe in `core/development.lua` still prints; paste its lines with each result. Run on Retail and Forever.

- [x] Kick a normal cast: one message, `Interrupted with <spell name>!`, in party chat. Forever: works; link showed the rank, now the plain name. Confirmed 2026-11-21.
- [ ] Kick a channel: one message.
- [ ] A channel ends naturally, no kick: no message.
- [ ] Kick with nothing casting: no message.
- [x] Teammate interrupts, you don't: no message. Confirmed 2026-11-24.
- [ ] You and the teammate interrupt the same cast at once (several tries): note any message that isn't yours.
- [ ] Your interrupt hits nothing (no cast, immune mob) while the teammate interrupts: no message.
- [ ] AoE interrupt hitting several casters (Disrupting Shout, Solar Beam; Retail): one message.
- [x] Dungeon, in combat: the cases above; channel is SAY in a 5-man, RAID in a raid. SAY and PARTY confirmed 2026-11-24; RAID not tested (same code path).
- [ ] Solo outdoors: the message is printed to your chat frame only (nothing sent), no errors.
- [ ] Pet interrupt (Felhunter Spell Lock): message with the pet's spell name.
- [ ] Retail Prot Paladin: Avenger's Shield and Divine Toll on a casting mob; paste the probe's IDs and
      `dt`. If `dt = 0`, they can be set to `true` in the table.
- [ ] Every interrupt spell ID the probe prints is in the table (Forever ranks, Retail pet IDs).
- [ ] Classic clients (Era/TBC/WotLK/MoP): `/reload` with no errors; one kick in a party still announces
      via the combat log.

## Forever: group (needs a second account)

### Group frames (8cdf7c5, `modules/unitframes/core.lua`)

- [x] Joining a group in combat shows the header (`[@raid1, exists]` visibility). Confirmed 2026-11-09.
- [ ] Clicks in combat: enter combat solo, invite the alt; left-click its new frame targets it, right-click opens the menu
      (children are created at login so `RegisterForClicks` isn't blocked).
- [ ] Leaving in combat: alt leaves or is kicked while you're in combat; its frame hides.
- [ ] Party → raid in combat: convert to raid in combat; frames swap, party and raid headers never show together.
- [ ] Login already grouped: log in with the alt already in the group; frames show.
- [ ] Raid40 switch at `[@raid21, exists]`: not testable with 2 accounts.

### Raid auras (609eac5, `modules/unitframes/elements/auras_mainline.lua`)

- [ ] Buffs: only defensives and short buffs (≤ 60s) on the alt's frame; long buffs (Kings, Arcane Intellect) hidden.
- [ ] Debuffs: one debuff, no duplicates; permanent debuffs and those over 600s hidden.

### Unverified

- [ ] `PLAYER` filter token on party units: cast your own buff on the alt, then `/tauras party1`.
- [ ] `isBossAura` candidate filter (`auras_mainline.lua:155`): needs a boss debuff.
