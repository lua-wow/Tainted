# Classic coverage audit: `refactor/classic` (read-only, nothing modified)

## Context
Audit of what `legacy/{tbc,wotlk,cata,mists}` provided against `master` and `refactor/classic` (23 commits on top of master).
Method: element/event/tag/color inventory from each snapshot (`git show legacy/*:elements/*`), mapped onto master elements, then checked against the `refactor/classic` diff and `wow-ui-source`.

How the sources were used:
- All four classic worktrees ship the same multi-flavor tree. Which flavor loads a file is set by `[AllowLoadGameType ...]` in
  `Blizzard_UnitFrame/Blizzard_UnitFrame_Classic.toc`. That line counts as "verified" for flavor-specific frames.
- The generated API docs are almost identical across flavors. They list modern APIs on every classic client (C_Secrets,
  `CreateUnitHealPredictionCalculator`, `C_UnitAuras.GetAuraSlots`, `UNIT_IN_RANGE_UPDATE`, `SetAlphaFromBoolean`, the castbar
  return order). So most master code is class A. Doc presence is "verified" for API existence, not for whether the API behaves the same on that client.
- Cata has no worktree, so every Cata cell is inferred. The exception is `[cata, mists]` TOC entries, which prove the Blizzard frame exists on Cata.

## 1. Coverage matrix
`ok` = A, works as is. `handled` = B/C/D covered by refactor. `MISSING` = not covered. `ignored` = not useful for Tainted, won't do. `n-a` = feature doesn't exist on that client.

| Feature (legacy → master name) | Era | TBC | WotLK | Cata | MoP |
|---|---|---|---|---|---|
| TOC load (`oUF.toc` Interface) | handled | handled | handled | handled | handled |
| Spawn / header without `SetRolesets`, pet-battle parent | handled | handled | handled | handled | handled |
| DisableBlizzard (party pool, ComboFrame, arena, nameplates) | handled | handled | handled | handled | handled |
| Vehicle swap (`vehicle.lua` → core `toggleForVehicle`) | n-a | n-a | ok | ok | ok |
| Arena units + prep/spec (`arenaspec` tag, class colour) | n-a | handled | handled | handled¹ | handled |
| Health (+ `colorSelection` via `UnitSelectionColor`) | handled | handled | handled | handled | handled |
| HealPrediction / absorbs (→ Health sub-widgets) | ok | ok | ok | ok¹ | ok |
| Power (+ `GetDisplayPower` nil fallback) | handled | handled | handled | handled | handled |
| DruidMana → AdditionalPower (MoP Mistweaver mana) | handled | handled | handled | handled | handled |
| AltPowerBar → AlternativePower | ok | ok | ok | ok | ok |
| Castbar | ok | ok | ok | ok | ok |
| Auras / Buffs / Debuffs | handled | handled | handled | handled | handled |
| CPoints → ClassPower combo points (target-owned) | handled | handled | handled | handled | handled |
| HolyPower → ClassPower | n-a | n-a | n-a | ok | ok |
| SoulShards → ClassPower | n-a | n-a | n-a | ok¹ | handled |
| ClassIcons shadow orbs / chi → ClassPower | n-a | n-a | n-a | n-a | handled |
| EclipseBar | n-a | n-a | n-a | handled | handled |
| Runebar → Runes (rune types, death colour) | n-a | n-a | handled | handled¹ | handled |
| Stagger | n-a | n-a | n-a | n-a | ok |
| Totems | handled | ok | ok | ok | ok |
| Happiness (element, `colorHappiness`, `[happiness]`) | handled | handled | handled | n-a | n-a |
| PvP → PvPIndicator | handled | handled | handled | handled | handled |
| MasterLooter → MasterLooterIndicator | handled | handled | handled | handled | handled |
| Leader/Assistant/RaidRole/LFDRole/ReadyCheck/RaidIcon/Combat/Resting/PhaseIcon/QuestIcon/ResurrectIcon/Portrait/Threat/Range | ok | ok | ok | ok | ok |
| Tag `[cpoints]` | ignored | ignored | ignored | ignored | ignored |
| Tag `[arcanecharges]` | n-a | n-a | n-a | n-a | ignored |
| Tag `[shadoworbs]` (C) | n-a | n-a | n-a | n-a | ignored |
| Tag `[pereclipse]` (C) | n-a | n-a | n-a | ignored | ignored |
| Tags `[pvprank]`, `[pvpranknum]` (C, legacy/tbc) | ignored | n-a | n-a | n-a | n-a |
| Colours: runes[4] death, SHADOW_ORBS, ECLIPSE | n-a | n-a | handled | handled | handled |

¹ inferred, Cata has no worktree.

Not counted (dropped upstream on purpose, not classic-specific): `[deficit:name]` and the oUF-1.x tags from legacy/tbc (`curxp`, `maxxp`, `rested`, `happynum`, `lowhpcolor`, …). `[happiness]` already covers the happiness tags.

Verified evidence for the "handled" and "ok" rows that matter:
- Target-owned combo points: `classic_era/.../Blizzard_UnitFrame/Classic/ComboFrame.lua` uses `GetComboPoints(self.unit, "target")`.
- TotemFrame is not loaded on Era: `Blizzard_UnitFrame_Classic.toc` has `Classic\TotemFrame.lua [AllowLoadGameType tbc, wrath, cata, mists]`.
- Runes: `Classic\RuneFrame_Shared.lua [wrath, cata, mists]` calls `GetRuneType`.
- Pair mana bar: `Wrath\AlternatePowerBar.lua [wrath, cata, mists]`.
- Heal prediction: `CreateUnitHealPredictionCalculator` is in `UnitDocumentation.lua` in all 4 worktrees, and `UNIT_MAX_HEALTH_MODIFIERS_CHANGED` too.
- Castbar: the `UnitChannelInfo`/`UnitCastingInfo` return order in the Era docs matches master's `elements/castbar.lua` CastStart. `PlayerCastingBarFrame` exists in `Blizzard_UIPanels_Game/Classic/CastingBarFrame.xml`.
- Health events: classic Blizzard frames use `UNIT_HEALTH` (`Classic/UnitFrame.lua:162`).

## 2. Missing list
1. **Done** (`oUF.toc` now lists 40402). **Cata TOC load.** `oUF.toc` listed `## Interface: 11509, 20506, 38002, 50504`, so nothing loads on Cata.
   - Legacy: `legacy/cata` `oUF.toc` = 40300.
   - Upstream shape: n/a.
   - Where: `oUF.toc`, add the Cata Classic interface (40402). Inferred.
2. **ClassPower soul shards, MoP spec gate.** **Done.**
   - Done: Cata shows shards for every spec; MoP only for affliction, and destruction shows burning embers once `WARLOCK_BURNING_EMBERS` (108647) is known (`SPELLS_CHANGED` re-checks visibility). `GetSoulShardsDestruction` is gated to Legion+.
   - Legacy: `legacy/mists` `elements/classicons.lua` shows SOUL_SHARDS only with `RequireSpec = SPEC_WARLOCK_AFFLICTION` (+ `RequireSpell` Soulburn). Blizzard does the same, verified: `classic/.../Mists/ShardBar.lua:68` `if ( spec == SPEC_WARLOCK_AFFLICTION )`.
   - Master: the `elements/classpower.lua` WARLOCK branch shows shards for every spec, and destruction gets the fractional `GetSoulShardsDestruction`.
   - Upstream shape: keep `ClassPower`, `PostUpdate(cur, max, hasMaxChanged, powerType)` and the `GetPowerInfo` return contract.
   - Where: inline class branch in `elements/classpower.lua`, a `WARLOCK and Mists and not Warlords` branch whose `GetPowerInfo` returns only for affliction. This mirrors the existing Mists MAGE branch.
3. **Done.** **EclipseBar on Cata.** The class/version guard also moved from file level into `Enable`, as runes/stagger.
   - Legacy: `legacy/cata` `elements/eclipsebar.lua`, gated on `GetPrimaryTalentTree() == 1`, with callbacks `PostUpdatePower(unit, power, max)`, `PostUnitAura`, `PostDirectionChange`, `PostUpdateVisibility`.
   - Refactor: `elements/eclipsebar.lua` returns early unless `GameCompatibility.Mists`.
   - Blizzard: `Cata\EclipseBarFrame.lua [cata, mists]` handles Cata with `C_SpecializationInfo.GetSpecialization() == 1` (verified, `ShouldDisplay`).
   - Upstream shape: keep the refactor's `PostUpdate(cur, max)` / `PostUpdateEclipse` / `PostUpdateDirection` / `PostVisibility`.
   - Where: inline, change the file guard to `GameCompatibility.Cataclysm`. On Cata, also register `PLAYER_TALENT_UPDATE` for visibility (inferred).
4. **Ignored** (tags not useful for Tainted, applies to 4–8). **Tag `[cpoints]`.**
   - Legacy: `GetComboPoints(vehicle-or-player, 'target')`, events `UNIT_COMBO_POINTS PLAYER_TARGET_CHANGED`.
   - Master: `UnitPower(u, ComboPoints)`, which is wrong before Warlords. The refactor's own classpower comment says MoP keeps the previous target's points.
   - Upstream shape: keep `[cpoints]` and its `'UNIT_POWER_FREQUENT PLAYER_TARGET_CHANGED'` events, and add `COMBO_TARGET_CHANGED`.
   - Where: add `Private.getComboPoints(unit)` to `compat.lua` (the target-owned lookup now local in classpower), expose it in the tags `_ENV` (same pattern as `GetPetHappiness`), and have classpower reuse it.
5. **Ignored.** **Tag `[arcanecharges]` on MoP.**
   - Legacy: none. MoP charges are stacks of debuff 36032, and `UnitPower(ArcaneCharges)` is constant (refactor comment, `classpower.lua` Mists MAGE branch).
   - Upstream shape: same tag name, return a number > 0.
   - Where: move `GetArcaneCharges` from classpower into `compat.lua` as `Private.getArcaneCharges`, use it in the tag, and add `UNIT_AURA` to the tag's events.
6. **Ignored.** **Tag `[shadoworbs]` (C).**
   - Legacy: `legacy/mists` `elements/tags.lua` `UnitPower('player', SPELL_POWER_SHADOW_ORBS)`.
   - Upstream shape: copy the `[holypower]` / `[chi]` tags with `Enum.PowerType.ShadowOrbs`.
   - Events: `UNIT_POWER_FREQUENT PLAYER_TALENT_UPDATE` (the refactor notes shadow orbs only fire FREQUENT).
   - Where: inline in `elements/tags.lua`, gated on the enum existing.
7. **Ignored.** **Tag `[pereclipse]` (C).**
   - Legacy: `abs(UnitPower(Eclipse)/max*100)`, event `UNIT_POWER`.
   - Upstream shape: like `[perpp]`, using `Enum.PowerType.Balance`, events `UNIT_POWER_FREQUENT UNIT_MAXPOWER`.
   - Where: inline in `elements/tags.lua`.
8. **Ignored.** **Tags `[pvprank]` / `[pvpranknum]` (Era, C).**
   - Legacy: `legacy/tbc` `UnitPVPRank(u)` / `GetPVPRankInfo(rank, u)`. The API is still used in Era (`Blizzard_InspectUI/Vanilla/InspectHonorFrame.lua`).
   - Where: inline in `elements/tags.lua`, guarded by `UnitPVPRank`. Low value.

## 3. Top 10 fixes, ranked by classic functionality lost
1. **Done.** Cata Interface in `oUF.toc`. Without it, nothing loads on Cata (inferred number).
2. **Ignored.** `[cpoints]` target-owned combo points via `compat.lua`. Wrong for every rogue and feral druid on all 5 clients.
3. **Done.** ClassPower: soul shards only for affliction on MoP. Destruction and demonology currently show bogus pips (verified).
4. **Done.** EclipseBar enabled on Cata. Blizzard supports Cata in the same mixin (verified).
5. **Ignored.** `[arcanecharges]` on MoP via the shared `Private.getArcaneCharges`.
6. **Ignored.** `[shadoworbs]` tag on MoP.
7. **Ignored.** `[pereclipse]` tag on Cata and MoP.
8. **Ignored** (tags). Inferred risk: MoP tag events `[chi]`, `[holypower]` and `[soulshards]` use `UNIT_POWER_UPDATE`. The refactor found that some pre-Warlords powers only fire `UNIT_POWER_FREQUENT`. Check in game and switch where needed.
9. **Done** (no event needed: Cata uses whole shards for every spec). Inferred risk: ClassPower on Cata has no spec-change event. `Enable` registers `PLAYER_SPECIALIZATION_CHANGED` only for Mists, so a Cata warlock's destruction shard formula doesn't refresh on respec. Register `PLAYER_TALENT_UPDATE` there.
10. **Ignored.** `[pvprank]` / `[pvpranknum]` on Era.

Optional, not in any legacy snapshot so not counted: MoP burning embers (**done**, orange `BURNING_EMBERS` in `core/colors.lua`) and demonic fury (**done**, one full-width ClassPower segment with a `cur / max` text, purple `DEMONIC_FURY`) (Blizzard `Mists/ShardBar.lua` `BurningEmbersBarMixin` / `DemonicFuryBarMixin`).

## Verification (if fixes are implemented later)
- `git diff master refactor/classic --stat` stays minimal; `luacheck .` per `.luacheckrc`.
- In game per client: rogue `[cpoints]` across target swaps; MoP warlock in all 3 specs; Cata and MoP moonkin eclipse; MoP arcane mage and shadow priest tags.
