# Interrupt announcer (plan)

Plan for `modules/miscellaneous/interrupts` (submodule `lua-wow/interrupts`): keep the combat-log
announcer on Classic, add a Retail/Forever announcer. Status: **Phase 2 done, B implemented; in-game
testing** (`docs/tests.md`). The probe stays on until testing ends.

## Goal

- Announce in group chat when the player (or their pet) interrupts an enemy cast.
- Never announce someone else's interrupt. If nothing proves the interrupt was the player's, announce
  nothing: silence beats a false claim.
- Classic (`classic` family): `classic.lua` (combat log).
- Retail and Forever (`mainline` family): new event-based announcer, `mainline.lua`.
- No options, no SavedVariables.

## Findings

### Blizzard API docs

`../refs/wow-ui-source`, live 12.1.0 and `worktrees/forever` 1.60.1 (identical):

- `UNIT_SPELLCAST_INTERRUPTED`, `_CHANNEL_STOP`, `_EMPOWER_STOP` and `_SUCCEEDED` are
  `SecretWhenUnitSpellCastRestricted`: the payload is secret when the unit isn't the player or their pet
  (`castBarID` is `NeverSecret`). For enemies, `interruptedBy`, `spellID` and `castGUID` are documented
  as secret, so `interruptedBy == UnitGUID("player")` can't be evaluated. Player and pet casts are
  readable.
- `C_ChatInfo.SendChatMessage` is `SecretArguments = "AllowedWhenUntainted"`: an addon can't send a
  message built from a secret enemy name or spell name.
- `C_DamageMeter` (interrupt totals per player) is `SecretWhenInCombat`: no real-time use. Rejected.
- Blizzard's cast bar names the interrupter with `UnitNameFromGUID(interruptedBy)`
  (`Blizzard_UIPanels_Game/Shared/CastingBarFrame.lua`, `GetInterruptText`). Secure code; not a
  pattern for an addon.

### `Interrupt` 1.22.0 (third-party addon)

All Rights Reserved: ideas and findings only, no code. Its claims, **unverified** by us:

- Touching the combat log raised "action blocked", even under `pcall`.
- Teammates' spell IDs in `UNIT_SPELLCAST_SUCCEEDED` were 100% secret in dungeons; own spells readable.
- Enemy cast names secret ~99.7% of the time. Raid pet GUIDs can be secret.
- No `UNIT_SPELLCAST_*` for `raidN`; enemy events only arrive for tokens the player has (target,
  focus, nameplates, boss).
- `interruptedBy` "can be readable or secret" (contradicts the docs; no recorded result).
- Its own-kick announcement pairs a player `UNIT_SPELLCAST_SUCCEEDED` (known kick spell) with any enemy
  `UNIT_SPELLCAST_INTERRUPTED` within 1 s. A teammate's kick in that window is credited to the player.
  Interrupted channels are ignored.

### Tainted

- TEMPORARY probe in `core/development.lua` (`if issecretvalue then`): player/pet
  `UNIT_SPELLCAST_SUCCEEDED` (spell ID, name, `GetTime()`), and INTERRUPTED / CHANNEL_STOP /
  EMPOWER_STOP for other units (secrecy of `unit`, `spellID`, `interruptedBy`, `UnitCanAttack`,
  `castBarID`, `GetTime()`, same frame and delta against the last player/pet cast, event order).

### Probe results: Forever (1.60.1, Rogue, open world, party with a Shaman)

Normal casts only. Channels, natural channel end and dungeons not tested yet.

- Enemy INTERRUPTED: `unit` readable (`nameplateN`, `target`, `softenemy`); `spellID` secret;
  `UnitCanAttack("player", unit)` readable (`true`). Friendly units can be filtered out.
- `interruptedBy` secret on the player's Kick and on the Shaman's Earth Shock. One Earth Shock interrupt
  gave a readable `nil` instead (docs: `Nilable = false`). Secrecy doesn't tell whose interrupt it was:
  **design A is not possible**.
- Player's Kick (1766): SUCCEEDED fires first, then INTERRUPTED once per token (up to 3: nameplate,
  target, softenemy), all in the same frame (`GetTime()` equal, `dt = 0`). Every token has a different
  `castBarID`, so it can't deduplicate.
- Shaman's Earth Shock: no player SUCCEEDED in that frame, so B gives no credit. In one case the player's
  Kick landed 0.27 s after the Shaman's interrupt. It still fired SUCCEEDED (no enemy event follows), and
  `Interrupt`'s 1 s window would have credited the player.
- Kick with nothing to interrupt: SUCCEEDED fires, no enemy event.
- Shaman interrupts with Earth Shock, which has ranks: the Forever table needs every rank. IDs to come
  from the probe.

## Design (mainline)

**B chosen**: Forever showed `interruptedBy` secret for every interrupter, so A is not possible.

### A. `interruptedBy` readable

Docs say it isn't; verify. On an enemy INTERRUPTED or CHANNEL_STOP, announce only if
`not issecretvalue(interruptedBy)` and it equals the player's or pet's GUID. Exact; no spell list.

### B. `interruptedBy` secret (expected)

Same-frame pairing:

- `RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")`. If `spellID` is in the interrupt
  table, store `pendingTime = GetTime()` and `pendingSpell = spellID`.
- On `UNIT_SPELLCAST_INTERRUPTED` or `_CHANNEL_STOP` for a non-player unit, announce only if
  `GetTime() == pendingTime` (same frame, after the player's cast), then clear the pending cast. The
  duplicate events from the target and nameplate tokens then announce once.
- Same frame rather than `Interrupt`'s 1 s window: a teammate's kick in the next second must not be
  credited to the player.
- Ship B only if Phase 0 shows a deterministic order and the teammate tests give no false credit.
  Otherwise ship nothing on mainline and record it in `docs/limitations.md`.

Interrupt table (`mainline.lua`), chosen by `WOW_PROJECT_ID`. The lists can't be merged: Retail's
Earth Shock isn't an interrupt.

- Retail: Blizzard's `InterruptSpellsBySpec` (`Blizzard_CooldownBroadcaster/TrackedCooldowns.lua`, same
  in the Forever source), plus pet casts 19647 Spell Lock and 89766 Axe Toss (**unverified**).
  Avenger's Shield (31935) and Divine Toll (375576) are listed as `false`: the shield lands after the
  cast, so same-frame pairing would miss them (**unverified** IDs and timing). Every interrupt stays in
  the table, grouped by class.
- Forever: vanilla IDs with every rank (**unverified**; Kick 1766 seen in the probe): Kick, Pummel,
  Shield Bash, Counterspell, Earth Shock, Silence, Feral Charge, Felhunter Spell Lock.

### Message and channel

- Enemy name and spell are secret, so B sends `"Interrupted with %s!"` with the player's own
  `C_Spell.GetSpellName` (not the link: on Forever the link text carries the rank). A reuses the Classic format `"Interrupted %s %s!"` when the fields are
  readable.
- Channel rules as `Interrupt:UpdateChatType` in `Interrupts.lua`: no SAY outdoors (needs a hardware
  event); INSTANCE_CHAT, RAID or PARTY by group. With no channel (solo outdoors) the message is
  printed locally. No anti-spam timer: clearing the pending cast already sends one message per interrupt.

## Files

Upstream `lua-wow/interrupts`, then bump the pointer:

- `Interrupts.lua`: shared frame, `UpdateChatType` and `Announce` (send, or print with no channel),
  `ns.Interrupts` (like `ns.Dispels`). Calls `Enable` at `PLAYER_LOGIN`.
- `classic.lua`: combat log (moved out of `Interrupts.lua`); `Enable` registers CLEU.
- `mainline.lua`: new; `Enable` registers the cast events.
- `init.xml`: removed.
- `Interrupts.toc`: add `120105, 16001`; `Interrupts.lua`, `classic.lua [AllowLoadGameType classic]`,
  `mainline.lua [AllowLoadGameType mainline]`.
- `.luacheckrc` (`issecretvalue`, `GetTime`, …), `CHANGELOG.md`.

Tainted:

- `Tainted.toc`: the same three lines as `Interrupts.toc`.
- `docs/compatibility.md`, `docs/limitations.md`: announcer wording.
- `core/development.lua`: remove the TEMPORARY probe once findings are recorded here.
- `docs/tests.md`: test section.

## Phases

0. **Probe**, no feature code. Extend the temporary probe: on player/pet `UNIT_SPELLCAST_SUCCEEDED`
   print `spellID` and `GetTime()`; on enemy INTERRUPTED/CHANNEL_STOP print `GetTime()`, the secrecy of
   each field and whether `unit` is readable. On Retail and Forever:
   Forever: normal cast, kick with nothing casting and teammate's interrupt done (see Findings).
   The remaining cases moved to `docs/tests.md`, run against the announcer.
1. Record results here; choose A, B or "not possible".
2. Implement in the submodule plus Tainted TOC and docs; `mise exec -- make check`.
3. In-game verification on Retail and Forever; `/reload` on a Classic client (combat-log announcer
   unchanged). Remove the probe.

## Open questions

- Is `unit` readable for enemies? If secret, friendly units can't be filtered out. Forever: readable.
- Order and frame of the player's SUCCEEDED and the enemy's INTERRUPTED under server batching.
  Forever: SUCCEEDED first, same frame (normal casts).
- Can a teammate's interrupt land in the same frame as a player kick that hit nothing? That would be the
  only false credit under B.
- With a secret `interruptedBy`, can CHANNEL_STOP tell a kick from a natural end? (B relies on the
  same-frame pairing instead.)
- Forever interrupt spell IDs.
