# PLAN: port oUF `master` to Classic clients (new `classic` branch)

Investigated 2026-10-23, read-only. `libs/oUF` = `master` @ `3692cb6` ("core: Scrub secrets (#930)");
`libs/oUF_Classic` = `classic` @ `55f37cd`; merge-base `9d557b4` (391 master-only commits).
API evidence: `../refs/wow-ui-source` worktrees `classic_era` 1.15.9, `classic_anniversary` 2.5.6,
`classic_titan` 3.80.2, `classic` 5.5.4. Each one checked against generated API docs (D) and against
non-Mainline FrameXML (X). Neither is proof that something works in-game.

This file replaces the earlier rev. 3 of `docs/ouf-core-plan.md` (squash, delete Retail code, no
compat file). No git writes by Claude.

**Scope:** Era `11509`, TBC `20506`, **WotLK `38002` (included, decided)**, MoP `50504`. IDs come from
the legacy branch (`oUF_Classic/oUF.toc`; `init.lua`: `WOW_PROJECT_CLASSIC`,
`_BURNING_CRUSADE_CLASSIC`, `_WRATH_CLASSIC`, `_MISTS_CLASSIC`).

## Decisions (2026-10-24)

| # | Question | Decision |
|:--|:--|:--|
| — | WotLK | Target, same as legacy |
| Q1 | Public flags | Legacy names and meanings: `isRetail`, `isClassic` (= **Era**), `isTBC`, `isWrath`, `isCata`, `isMoP`. Plugins unchanged |
| Q2 | Classic auras | `elements/auras.lua` replaced by `9d557b4:elements/auras.lua` + re-implemented fixes (no separate Classic file) |
| Q2b | Dispel key | Tainted uses `"None"` (`modules/unitframes/elements/auras.lua:155`); no alias in oUF |
| Q3 | Selection colour | Colour taken from `UnitSelectionColor` (`Private.unitSelectionColor`), no type mapping |
| Q4 | Arena frames | CVar `showArenaEnemyFrames` 0 + hide `ArenaEnemyFrame1-5` when `Blizzard_ArenaUI` loads; no `Arena_LoadUI` override |
| Q5 | Runes | Port rune types (`GetRuneType`) on WotLK/MoP |
| Q6 | MoP ClassPower | Chi for all monks (`not GameCompatibility.Legion`) only; warlock/mage changed only if in-game shows them wrong |
| Q7 | Happiness, MasterLooter | **Enable both on Classic** (step 13b) |
| Q8 | Retail files | Keep everything, including `happiness.lua`/`masterlooterindicator.lua` and `questindicator.lua` (inert: Tainted skips the widget without `UnitIsQuestBoss`; deleting it would conflict on every upstream edit) |
| — | Old plan doc | This plan replaces `docs/ouf-core-plan.md` (tracked) |
| — | Go/no-go | Gate after step 4 on `refactor/classic`; `classic` is overwritten only after step 16 passes |

## Progress

Spike = steps 1–4 + gate. Tick a box in the same edit as the change.

- [x] 0: `refactor/classic` from `origin/master` (`3692cb6`)
- [x] 1: TOC for Classic (spike)
- [x] 2: compat module (spike)
- [x] 3: block Blizzard frames without rolesets (spike)
- [x] 4: spawn without rolesets, hide in pet battles (spike)
- [x] Go/no-go gate: castbar, health/prediction, tags, range (spike; passed on MoP)
- [x] 5: arena preparation
- [x] 6: selection colour (pulled before the gate)
- [x] 7: Totems
- [x] 8: ClassPower (8a guards, 8b target combo points, 8c MoP)
- [x] 9: PvPIndicator
- [x] 10: classic aura element
- [x] 11: Runes on WotLK/MoP
- [x] 12: AdditionalPower display pairs (pulled before the gate)
- [x] 13: Tags without UnitFrameUtil
- [x] 13b: Happiness and MasterLooterIndicator
- [x] 14: in-game failures only (range, castbar, health, role indicators; none needed)
- [x] 15: oUF cleanup
- [x] 16: Tainted (indicator gates moved to 13b)
- [ ] Publish: overwrite `classic`

Later (found in-game, outside the port steps):
- [ ] `oUF_RaidDebuffs`: border colour missing for some debuffs
- [ ] Focus range: `C.unitframes.focus.range` constant for the focus `Range` element
- [ ] Classic nameplates use the Retail layout; restore the Classic one

---

## 1. Findings summary

**What master already handles.** Master has a client-version table, `Private.GameVersion` /
`Private.GameCompatibility` (`private.lua:80-119`, based on interface ranges: `Vanilla` <16000,
`BurningCrusade`, `Wrath`, `TitanReforged`, `Mists`, `Forever` 16000–19999, `PTR` ≥120105). Elements
use it for content gates (`classpower.lua:111-288`, `pvpindicator.lua:79-273`, `health.lua:175`,
`happiness.lua:95`, `masterlooterindicator.lua:103`, role indicators `:54`). Most master code is
already safe on Classic:
- The audit covered 149 globals, 32 `C_*` functions, every `Enum.*` member and every event master
  uses. Everything Midnight-era (duration objects, `C_CurveUtil`, `C_StringUtil`, heal-prediction
  calculator, `SetTimerDuration`, `SetAlphaFromBoolean`, `issecretvalue`, `scrubsecretvalues`,
  `C_Secrets.CanCompareUnitTokens`, `UnitGroupRolesAssignedEnum`, nameplate hit-test API) **is in all
  four Classic docs**.
- Tainted already calls `C_CurveUtil.CreateColorCurve`, `GetTotemDuration`,
  `SetCooldownFromDurationObject`, `SetTimerDuration` and `C_StringUtil.TruncateWhenZero` on Classic
  (`core/curves.lua`, `modules/unitframes/elements/totems.lua`, `classpower.lua`, `auras.lua`). Legacy
  already uses `CreateUnitHealPredictionCalculator`/`UnitGetDetailedHealPrediction`. So those calls
  are exercised in-game.
- `PartyFrame.PartyMemberFramePool` (X, all 4), `PlayerCastingBarFrame`/`PetCastingBarFrame`
  (`Classic/CastingBarFrame.xml`), `AuraUtil.GetDebuffDisplayInfoTable`, `PingableUnitFrameTemplate`
  (empty stub, `Blizzard_SharedXML/Classic/Stubs.xml`), `BuffFramePrivateAuraAnchorTemplate`,
  `CooldownFrameTemplate` and the secure templates all exist.
- `handleFrame` already tolerates nil frames, so `BossTargetFrameContainer` is harmless.
  `CompactArenaFrame` and `ArenaEnemyMatchFramesContainer` are nil-guarded.

**What does not work.** Hard blockers, on every Classic client:
1. **`SetRolesets` is absent** (live docs only). Every `Spawn` (`ouf.lua:852/854`), `SpawnHeader`
   (`:759`) and every Blizzard-frame disable (`blizzard.lua:28`) errors, so **no unit frame spawns**.
2. **Master `Auras` is `AuraContainer`-only** (`CustomAuraContainerTemplate`,
   `AuraContainerSort*`, `CustomAuraContainerAuraProcessingPolicy`: absent). Tainted's Classic auras
   need the old `Buffs`/`Debuffs` button element.
3. **Unknown events reach `Private.validateEvent`.** It calls the error handler, so the user sees a
   Lua error: `UNIT_POWER_POINT_CHARGE` (ClassPower, registered unconditionally) and
   `HONOR_LEVEL_UPDATE` (PvPIndicator).
4. **Missing globals on paths Classic reaches:** `GetUnitChargedPowerPoints`,
   `PlayerVehicleHasComboPoints`, `C_ClassTalents` (ClassPower), `UnitIsMercenary` (PvPIndicator),
   `UnitSelectionType` (Health/Power/AltPower `colorSelection`), `UnitFrameUtil` (arena prep
   `colorClass`, the `arenaspec`/`raidcolor` tags), `_G.ALT_POWER_BAR_PAIR_DISPLAY_INFO` →
   `CopyTable(nil)` (AdditionalPower), `TotemFrame` on Era (Totems).

**Biggest risks.**
- Master code that runs on Classic but that **no Blizzard Classic code uses**, so it is only in the
  docs. These are all **UNVERIFIED**: castbar `UnitCastingDuration`/`UnitChannelDuration` +
  `C_DurationUtil.CreateDurationTextBinding`, Tags `UnitHealthPercent`/`UnitPowerPercent`/
  `C_StringUtil.CreateSecondsFormatter`, Health `calculator:GetCurrentHealth/EvaluateCurrentHealthPercent`.
  If one of them is a stub, the fix is a real port, not a guard.
- **Range**: master depends on `UNIT_IN_RANGE_UPDATE` alone. Legacy added a 0.2 s poll because of this
  (UNVERIFIED that the event alone is enough on Classic).
- **Merge churn**: the role indicators and PvPIndicator Classic paths sit in `else` branches that
  upstream marks `-- TODO: remove in 12.1.5` (`grouproleindicator.lua:52`, `raidroleindicator.lua:52`).
  When upstream deletes them, a merge silently routes Classic into `UnitFrameUtil` (absent). This
  will recur.
- **Flag-name clash**: the brief proposes `oUF.isClassic` = "any Classic". Plugins
  (`libs/oUF_RaidDebuffs`, 22 uses in `debuffs/debuffs.lua`) read the legacy meaning, `oUF.isClassic`
  = **Era only**, plus `isRetail`/`isMoP`. Master exposes no public flags at all.

---

## 2. Ordered steps

Conventions for every step:
- Change type: **guard** (nil/feature check), **shim** (replacement in `compat.lua`), **skip** (not
  loaded on Classic), **delete**, **manifest**.
- Verify every step with `cd libs/oUF_Classic && mise exec -- luacheck .` (after step 2 adds the
  Classic globals), plus `mise exec -- make check` in Tainted.
- Run the grep audit (§6) after each core step.
- In-game checks are listed where a step changes runtime behaviour.
- Every commit is small and touches only the hunk that fails. I edit, you commit (Tainted
  CLAUDE.md).

### Phase 0: branch setup (you run these; I don't)

Branches (`lua-wow/oUF`):

| Branch | Points to | Role |
|:--|:--|:--|
| `master` | upstream (`3692cb6`+) | Retail oUF, never touched |
| `classic-legacy` | `55f37cd` (already on the remote) | archive of the legacy port; never delete or rewrite. Keeps Tainted's old gitlinks fetchable |
| `classic` | `55f37cd` until publish | what Tainted's `.gitmodules` tracks; untouched during the work |
| `refactor/classic` | starts at `origin/master` | the work branch: master + small Classic commits |

**Step 0: create the work branch**
```sh
cd libs/oUF_Classic
git switch -c refactor/classic origin/master             # 3692cb6 or newer; no squash
```
- Verify: `git merge-base refactor/classic origin/master` = the master tip.
- Pushing `refactor/classic` while working is optional (backup); `classic` is not touched.

**Abort** (if the gate fails): `git switch classic && git branch -D refactor/classic` (plus
`git push origin --delete refactor/classic` if it was pushed).

**Publish** (after step 16 passes in-game): overwrite `classic` with the work branch.
```sh
git push --force-with-lease=classic:55f37cd origin refactor/classic:classic
git branch -f classic refactor/classic                   # local classic follows
```
- `.gitmodules` keeps `branch = classic`. Then the Tainted pointer bump.
- Afterwards, upstream updates are `git merge master` on `classic`.

### Phase 1: compat module and manifests

**Step 1: TOC for Classic** (manifest)
- Files: `oUF.toc` only. `## Interface: 11509, 20506, 38002, 50504` and
  `## AllowLoadGameType: vanilla, tbc, wrath, mists` (replaces `standard, camelot`).
- Leave `oUF.xml` alone. Tainted loads `oUF.xml` directly, so `oUF.toc` only matters for standalone
  installs.
- Commit: `toc: load on Classic Era, TBC, WotLK and MoP`
- Verify: TOC parses (standalone install not required).

**Step 2: compat module** (shim, manifest)
- Files: new `compat.lua`; `oUF.xml` (one line after `private.lua`); `.luacheckrc` (add Classic
  globals such as `WOW_PROJECT_*`, `GetComboPoints`, `GetRuneType`, `ArenaEnemyFrame*`,
  `RegisterStateDriver`, `GetSpecializationInfoByID`, `UnitIsPVPFreeForAll`, …).
- `compat.lua` contents. No new globals, nothing runs at load time except table setup.
  - Public flags from `WOW_PROJECT_ID`, with **legacy names and meanings** (Q1, decided):
    `oUF.isRetail`, `oUF.isClassic` (Era), `oUF.isTBC`, `oUF.isWrath`, `oUF.isCata`, `oUF.isMoP`.
    Core code keeps using `Private.GameVersion`; the public flags exist for plugins.
  - `Private.eventExists(event)`: `C_EventUtils.IsEventValid` (D on all 4). It's a silent check,
    unlike `validateEvent`, which reports through the error handler.
  - Shims as `Private.*` locals that call the native API when it exists:
    - `Private.setRolesets(frame, set)` (step 3)
    - `Private.unitFrameParent` (step 4)
    - `Private.getArenaOpponentSpecInfo(index)` (step 5)
    - `Private.getUnitChargedPowerPoints`, `Private.playerVehicleHasComboPoints` (step 8)
    - `Private.unitIsMercenary` (step 9)
    - `Private.altPowerBarPairDisplayInfo` (step 12)
- A new file plus one XML line keeps future `git merge master` conflicts to that single line.
- Commit: `compat: client flags and API shims for Classic`
- Verify: luacheck. In-game `/dump` of the flags on each client. Nothing uses the shims yet.

### Phase 2: core fixes (each one makes the next failure reachable)

**Step 3: block Blizzard frames without rolesets** (shim, guard)
- Files: `compat.lua`, `blizzard.lua`.
- `handleFrame` → `Private.setRolesets(frame, 'alwaysBlocked')`. Without `SetRolesets` this hides
  and reparents to a hidden frame, plus a `SetParent` re-hide hook. That is the merge-base
  (`9d557b4:blizzard.lua`) technique, from master's own history.
- Nameplates: hook `OnShow` once **per `UnitFrame`**, not per plate, because Blizzard pools
  UnitFrames (legacy `b199095`). Skip forbidden or nil `UnitFrame`s.
- Add the nil-safe `handleFrame(ComboFrame)` for `target` (`Classic/ComboFrame.xml`, all 4).
- Arena (Q4, decided): when `ArenaEnemyMatchFramesContainer` is nil, set CVar
  `showArenaEnemyFrames` to 0 and hide `ArenaEnemyFrame1..5` (`Blizzard_ArenaUI.xml`,
  load-on-demand) once `Blizzard_ArenaUI` is loaded: immediately if it already is, else on its
  `ADDON_LOADED`. No `Arena_LoadUI` override.
- Commit: `blizzard: hide Blizzard frames where SetRolesets is missing`
- Verify, in-game on all 4: Blizzard player/pet/target/combo/focus/party/boss frames never appear;
  arena frames on TBC/WotLK/MoP; Blizzard nameplates stay hidden through plate reuse.

**Step 4: spawn without rolesets, hide in pet battles** (shim)
- Files: `ouf.lua` (`Spawn`, `SpawnHeader`: 3 `SetRolesets` lines and 2 `UIParent` parents).
- `Private.unitFrameParent` is `UIParent` where `SetRolesets` exists. Elsewhere it is a secure frame
  with `RegisterStateDriver(f, 'visibility', '[petbattle] hide; show')`, which is the merge-base
  `PetBattleFrameHider` idea.
- Keep `PingableUnitFrameTemplate` (a stub on Classic).
- Commit: `ouf: spawn frames without SetRolesets`
- Verify: login and `/reload` with no errors; every frame spawns (player, target, tot, focus,
  focustarget, pet, party, raid, boss, arena); MoP pet battle hides frames.

**Go/no-go gate (after step 4, one client).** Classic auras may be missing until step 10; that's
expected. Check:
- castbar progress and time text (duration objects)
- health values and prediction (calculator)
- Tainted tags (percent APIs)
- range alpha

All work → continue with step 5. Any is a stub → abort (step 0): delete `refactor/classic`; `classic` was never touched.

**Step 5: arena preparation** (shim, guard)
- Files: `units.lua`, `compat.lua`.
- `UnitFrameUtil.GetArenaOpponentSpecDisplayInfo` (`units.lua:55`) →
  `Private.getArenaOpponentSpecInfo`, built on `GetArenaOpponentSpec` + `GetSpecializationInfoByID`.
  Both are X only (`Blizzard_ArenaUI.lua`), so **UNVERIFIED**, and Era has no arena.
- Register `ARENA_PREP_OPPONENT_SPECIALIZATIONS` only `if(GetNumArenaOpponentSpecs)`.
- Commit: `units: arena preparation without UnitFrameUtil`
- Verify: `/tainted test arena`; MoP real arena queue (prep shows class colour); TBC/WotLK arena.

**Step 6: selection colour** (shim)
- Files: `compat.lua` (`unitSelectionColor`), `elements/{health,power}.lua`.
- `UnitSelectionType` is absent. `UnitSelectionColor` is X only (`Shared/CompactUnitFrame.lua`) and is
  what legacy used in production. Q3, decided: `Private.unitSelectionColor` returns the `UnitSelectionColor(unit, true)` colour (computed per `UpdateColor`); no type mapping.
- Commit: `private: selection colour from UnitSelectionColor on Classic`
- Verify: Classic nameplate selection colours (hostile, neutral, friendly, tapped, party, dead).

### Phase 3: elements (failure-driven, in the order Tainted hits them)

**Step 7: Totems** (guard)
- Files: `elements/totems.lua:160-179`. Wrap the `TotemFrame` (un)registration in `if(TotemFrame)`.
  Era doesn't load it; legacy `7377f7c` fixed the same thing.
- Commit: `totems: guard TotemFrame, which Era doesn't load`
- Verify: Era shaman totems; WotLK/MoP totems.

**Step 8: ClassPower on Classic** (guard, shim, real delta; 2–3 commits)
- Files: `elements/classpower.lua`.
- 8a, guard/shim (`classpower: register only events and APIs the client has`):
  - `GetUnitChargedPowerPoints` (`:104`) → shim returning nil
  - `PlayerVehicleHasComboPoints` (`:437`) → shim returning false
  - `UNIT_POWER_POINT_CHARGE` (`:522`) and `TRAIT_CONFIG_UPDATED` + `C_ClassTalents` (`:495,566`) →
    register only `if(Private.eventExists(...))` / `if(C_ClassTalents)`
- 8b, real delta (`classpower: Classic combo points on target`): Classic combo points belong to the
  target (Blizzard `Classic/ComboFrame.lua` uses `GetComboPoints('player','target')`).
  `UnitPower('player', ComboPoints)` behaviour is **UNVERIFIED**.
  - Port the idea, not legacy code: when `not GameCompatibility.Warlords` (MoP Classic loads the same
    `Classic/ComboFrame.lua`), use `GetComboPoints(unit, 'target')` and register `PLAYER_TARGET_CHANGED` +
    `COMBO_TARGET_CHANGED` (documented on all 4) while combo points are the active power.
- 8c, MoP content (`classpower: MoP class powers`):
  - Master gates Monk chi to Windwalker (`:245`). MoP chi is shared by all monk specs, and master's
    own tags already know this (`tags.lua:160`, `not GameCompatibility.Legion`). Gate it the same way.
  - Warlock (`:288-310`) and Mage arcane charges (`:198`, Midnight-only): keep master behaviour
    (Q6, decided). Change only if in-game shows them wrong; the legacy MoP behaviour
    (`classic-legacy:elements/classpower.lua:310-327`) is the checklist.
- Verify: rogue/druid combo points on all 4 (target switch keeps or clears points); vehicle combo
  points (WotLK/MoP); MoP monk all specs, paladin, warlock specs.

**Step 9: PvPIndicator** (shim, guard)
- Files: `elements/pvpindicator.lua`.
- `UnitIsMercenary` (`:103,134`) → `Private.unitIsMercenary`.
- `HONOR_LEVEL_UPDATE` (`:245/270`) → register only if the event exists.
- `UnitHonorLevel`/`C_PvP.GetHonorRewardInfo` (`:154-156`) are reached only with `element.Badge`. Keep
  the shim/guard local, honor badge **UNVERIFIED** on Classic.
- Commit: `pvpindicator: skip honor and mercenary APIs Classic lacks`
- Verify: flag PvP, FFA zone, enemy player nameplate/target; Tainted gate `indicators.lua:206` can
  then be revisited (separate decision).

**Step 10: classic aura element** (replace; Q2, decided)
- Files: `elements/auras.lua`, replaced (the AuraContainer element is Retail-only).
- Source: **master's own history**, `git show 9d557b4:elements/auras.lua`, the last upstream
  button-based element and not a legacy file. Then re-implement the problems legacy solved:
  - `growthX`/`growthY` (legacy `5fd0303`)
  - `__unit` (master core)
  - dispel colour key `None` (master `colors.dispel` from `AuraUtil`); colours are color objects (`GetRGB`)
- Registers `'Auras'` with `AddElement` like the old element.
- Commit: `auras: button-based Buffs/Debuffs for Classic (no AuraContainer)`
- Verify: player/target/party/nameplate buffs and debuffs, growth direction, tooltips, dispel
  borders, stealable; AuraTrack/RaidDebuffs plugins on raid frames.

**Step 11: Runes on WotLK/MoP** (real delta; Q5, decided)
- Files: `elements/runes.lua`, `colors.lua` (`runes[4]` death).
- With `GetRuneType` (X: `Classic/RuneFrame_Shared.lua`): Blizzard order, per-rune type colour,
  `RUNE_TYPE_UPDATE`, `PostUpdateColor(color, rune)`. This is the idea from legacy `f7b410d`, written
  against master's `STATE` layout.
- Rune type is the `colors.runes` index directly (1 blood, 2 frost, 3 unholy, 4 death), as in
  `Classic/RuneFrame_Shared.lua:6-9`, ElvUI and Tukui. Legacy's `{1, 3, 2, 4}` remap (combat-text order)
  was dropped. **UNVERIFIED** in-game.
- `GetSpecialization` doesn't run with rune types, and `PLAYER_SPECIALIZATION_CHANGED` is registered
  only without them.
- Commit: `runes: rune types on WotLK and MoP`
- Verify: DK blood/frost/unholy/death runes, Blood Tap and death-rune conversion.

**Step 12: AdditionalPower display pairs** (shim)
- Files: `elements/additionalpower.lua:63,395`, `compat.lua`.
- `_G.ALT_POWER_BAR_PAIR_DISPLAY_INFO` is absent, which crashes `CopyTable(nil)`. Use
  `Private.altPowerBarPairDisplayInfo`, which is the global when it exists.
- Otherwise a per-client table following Blizzard `Wrath/AlternatePowerBar.lua`:
  - druid Rage/Energy → Mana on all 4 (Era/TBC added by choice; Blizzard has no bar there)
  - MoP Mistweaver Energy → Mana
  - MoP spec restriction **UNVERIFIED** (idea from legacy `05e51cb`)
- Commit: `additionalpower: Classic display pairs`
- Verify: druid shapeshift mana bar (WotLK/MoP); druid also on Era/TBC; MoP Mistweaver.

**Step 13: Tags without UnitFrameUtil** (shim)
- Files: `elements/tags.lua:155,353`.
- `arenaspec` and the `raidcolor` arena branch → `Private.getArenaOpponentSpecInfo` (from step 5).
- Commit: `tags: arena spec tags without UnitFrameUtil`
- Verify: Tainted tags on all units; arena tags (MoP).

**Step 13b: Happiness and MasterLooterIndicator on Classic** (shim, guard; Q7, decided; 2 commits)
- Happiness (`elements/happiness.lua:45,95`, `elements/health.lua:175,524` `colorHappiness`,
  `elements/tags.lua:227-228` `happiness` tag):
  - `Private.getPetHappiness` = `C_PetInfo.GetPetHappiness` where it exists, else the global
    `GetPetHappiness`. That's Blizzard `Classic/PetFrame.lua:169`
    (`local happiness, damagePercentage, loyaltyRate = GetPetHappiness()`) on all 4 worktrees, so the
    first return has the same 1–3 meaning.
  - Gate `GameVersion.Forever` → `Private.getPetHappiness` (hunter + `pet`, as now).
  - `UNIT_HAPPINESS` is in all 4 docs.
  - MoP removed pet happiness, but its PetFrame still calls `GetPetHappiness`. In-game (2026-10-25)
    it returns `nil, 100, 0`, so the element hides.
  - Commit: `happiness: Classic hunter pets via GetPetHappiness`
- MasterLooter (`elements/masterlooterindicator.lua:103`): gate `GameVersion.Forever` → the API
  check (`C_PartyInfo.GetLootMethod`, D on all 4; `PARTY_LOOT_METHOD_CHANGED` in all 4 docs).
  - Commit: `masterlooterindicator: enable where GetLootMethod exists`
- Tainted (part of 13b, not step 16): relax the mainline gates for `CreateHappinessIndicator` /
  `CreateMasterLooterIndicator` (`modules/unitframes/elements/indicators.lua:99,137`).
- Verify:
  - hunter pet on Era/TBC/WotLK: icon and health colour change with feeding/unhappy
  - MoP hunter: nothing shown, no error
  - party/raid with master loot (all 4): icon on the looter, moves on change

**Step 14: only if in-game fails (placeholders, no speculative work)**
- **Result (2026-10-25):** not needed. Range, castbar and health (incl. heal prediction) passed in-game on
  Era/TBC/WotLK/MoP; the castbar drain-then-fill came from Tainted's `smoothing` (now Retail only).
- `range`: if `UNIT_IN_RANGE_UPDATE` alone leaves stale alpha, add a gated shared timer
  (`if not GameVersion.Retail`), with the legacy 0.2 s poll as the idea.
  Commit `range: poll on Classic`.
- `castbar`: if duration objects or the text binding misbehave, guard per API. A port back to an
  `OnUpdate` progress is a big delta; stop and decide. Empower pips (`CastingBarFrameStagePipTemplate`,
  absent) stay dormant unless `UnitEmpoweredStagePercentages` returns stages.
- `health`: if `calculator:GetCurrentHealth`/`EvaluateCurrentHealthPercent` fail, fall back to
  `UnitHealth`/`UnitHealthMax` behind a capability check.
- `grouproleindicator`/`raidroleindicator`: no change (the `else` branch runs on Classic; its APIs
  `UnitGroupRolesAssignedEnum`, `Enum.LFGRole` (D), `GetPartyAssignment`, `UnitHasVehicleUI` (X) exist
  on all 4). **Merge note:** upstream's 12.1.5 cleanup (`-- TODO: remove in 12.1.5`) will delete that
  `else` branch; keep it on `classic` when merging.

### Phase 4: cleanup and Tainted

**Step 15: oUF cleanup**
- Keep `elements/questindicator.lua` unchanged (Q8): `UnitIsQuestBoss` is absent on all 4, but Tainted
  skips the widget when it is nil, so the element never enables.
- `.luacheckrc` final pass (clean; leave master's entries); README note "classic branch = master + Classic compat".
- Commit: `classic: README note`.

**Step 16: Tainted** (one commit you group)
- Files:
  - `libs/oUF_Classic` pointer
  - `modules/unitframes/elements/auras.lua:155` (`"none"` → `"None"`, Q2b)
  - `docs/compatibility.md` "oUF variants" section
  - `docs/ouf-core-plan.md` (this plan): mark done or trim to the remaining notes
- Plugins: `oUF_RaidDebuffs`/`oUF_AuraTrack` need no change (Q1: legacy flag names).
- Verify: `mise exec -- make check`; full in-game checklist (§6) on Era, TBC, WotLK and MoP;
  Retail/Forever `/reload` sanity (unchanged `libs/oUF`).

---

## 3. Failure table (master on Classic, static)

E/T/W/M = Era/TBC/WotLK/MoP. "Absent" = not in the docs and not in non-Mainline FrameXML of that
worktree.

| file:line | API | Missing on | Guarded? | Fix |
|:--|:--|:--|:--|:--|
| `ouf.lua:759,852,854` | `Frame:SetRolesets` | E T W M | no | shim (step 4) |
| `blizzard.lua:28` | `Frame:SetRolesets('alwaysBlocked')` | E T W M | no | shim (step 3) |
| `blizzard.lua:83-96` | `PLAYER_PVP_FLAG_CHANGED`, `SOUNDKIT` | event absent E T W M | yes (`GameVersion.Forever`) | none |
| `blizzard.lua:113` | `BossTargetFrameContainer` | E T W M (EditMode refs only) | yes (`handleFrame` nil-safe) | none |
| `blizzard.lua:125` | `PartyFrame.PartyMemberFramePool` | present (X `Shared/PartyFrame.lua`) | — | none |
| `blizzard.lua:137-152` | `CompactArenaFrame`, `ArenaEnemyMatchFramesContainer` | container absent all; `CompactArenaFrame` referenced only | yes (`if`) | guard + Classic arena frames (step 3) |
| `blizzard.lua` (target) | `ComboFrame` not handled | present all (`Classic/ComboFrame.xml`) | — | add (step 3) |
| `blizzard.lua:157` | nameplate `frame.UnitFrame` (pooled, re-shown) | behaviour | partial | per-UnitFrame hook (step 3) |
| `units.lua:55` | `UnitFrameUtil.GetArenaOpponentSpecDisplayInfo` | E T W M | no (reached with `colorClass`) | shim (step 5) |
| `units.lua:124,150` | `GetNumArenaOpponentSpecs`, `GetArenaOpponentSpec` | X only (ArenaUI); Era no arena | no | guard (step 5), **UNVERIFIED** |
| `private.lua:76` | `UnitSelectionType` | E T W M | no | shim (step 6) |
| `private.lua:34` | `C_Secrets.CanCompareUnitTokens` | D all | — | none (**UNVERIFIED** in-game) |
| `colors.lua:153` | `AuraUtil.GetDebuffDisplayInfoTable` | present all (legacy `e2ce15f`) | — | none |
| `colors.lua:25` | `C_CurveUtil.CreateColorCurve` | D all; used by Tainted on Classic | — | none |
| `elements/auras.lua:250,251,370,407` | `AuraContainerSort*`, `CustomAuraContainerTemplate`, `…ProcessingPolicy`, `:GetUnit` | E T W M | no | skip + classic file (step 10) |
| `elements/castbar.lua:109` | `CastingBarFrameStagePipTemplate` | E T W M | dormant (empower only) | none / step 14 |
| `elements/castbar.lua` | `UnitCastingDuration`, `UnitChannelDuration`, `SetTimerDuration`, `C_DurationUtil.*`, `C_StringUtil.CreateSecondsFormatter` | D all, no Classic Blizzard user | — | none (passed in-game, step 14) |
| `elements/castbar.lua:683-750` | `PlayerCastingBarFrame`, `PetCastingBarFrame` | present (X `Classic/CastingBarFrame.xml`, `PetFrame.xml`) | — | none |
| `elements/classpower.lua:104` | `GetUnitChargedPowerPoints` | E T W M | no | shim (8a) |
| `elements/classpower.lua:437` | `PlayerVehicleHasComboPoints` | E T W M | no | shim (8a) |
| `elements/classpower.lua:495-496,566` | `TRAIT_CONFIG_UPDATED` → `C_ClassTalents.GetActiveConfigID` | namespace absent E T W M | no | guard (8a) |
| `elements/classpower.lua:522` | event `UNIT_POWER_POINT_CHARGE` | E T W M | no → error-handler popup | guard (8a) |
| `elements/classpower.lua:103,262` | combo points via `UnitPower(…ComboPoints)` | target-bound on Classic | — | real delta (8b), **UNVERIFIED** |
| `elements/classpower.lua:245` | Chi only for Windwalker | MoP content | n/a | gate (8c) |
| `elements/classpower.lua:116` | `GetCollapsingStarCost` | DH only, `GameCompatibility.Midnight` | yes | none |
| `elements/pvpindicator.lua:103,134` | `UnitIsMercenary` | E T W M | no | shim (step 9) |
| `elements/pvpindicator.lua:245` | event `HONOR_LEVEL_UPDATE` | E T W M | no → popup | guard (step 9) |
| `elements/pvpindicator.lua:154-156` | `UnitHonorLevel`, `C_PvP.GetHonorRewardInfo` | X only (LFGList) / not in docs | partly (`Badge`) | guard (step 9), **UNVERIFIED** |
| `elements/pvpindicator.lua:81,84` | `UnitFrameUtil.*` | E T W M | yes (`PTR`/`Forever`) | none (merge risk) |
| `elements/grouproleindicator.lua:58`, `raidroleindicator.lua:58` | `UnitFrameUtil.UpdateUnitFrameRoleIcon` | E T W M | yes (`PTR`/`Forever`) | none now; merge risk |
| `elements/additionalpower.lua:63,395` | `_G.ALT_POWER_BAR_PAIR_DISPLAY_INFO` → `CopyTable(nil)` | E T W M | no | shim (step 12) |
| `elements/totems.lua:160-179` | `TotemFrame` | Era (not in Era TOC; legacy `7377f7c`) | no | guard (step 7) |
| `elements/stagger.lua:195-232` | `MonkStaggerBar` | E T W (no monks) | yes (monk only) | none |
| `elements/runes.lua:79` | `C_SpecializationInfo.GetSpecialization` on WotLK | D all; WotLK spec semantics **UNVERIFIED** | — | real delta (step 11) |
| `elements/questindicator.lua:42` | `UnitIsQuestBoss` | E T W M (commented-out ref only) | Tainted gates widget creation | none (kept, Q8) |
| `elements/happiness.lua:45`, `health.lua:175`, `tags.lua:228` | `C_PetInfo.GetPetHappiness` | E T W M | yes (`Forever`) | shim (step 13b) |
| `elements/masterlooterindicator.lua:103` | `C_PartyInfo.GetLootMethod` | D all | yes (`Forever` gate, never true) | guard (step 13b) |
| `elements/tags.lua:155,353` | `UnitFrameUtil.GetArenaOpponentSpecDisplayInfo` | E T W M | lazy (tag use only) | shim (step 13) |
| `elements/tags.lua` | `UnitHealthPercent`, `UnitPowerPercent`, `UnitHealthMissing`, `C_StringUtil.WrapString` | D all; `WrapString` used by Tainted | — | **UNVERIFIED** (percent APIs) |
| `elements/range.lua` | `UNIT_IN_RANGE_UPDATE` only | D all | — | none (passed in-game, step 14) |
| `elements/privateauras.lua` | `C_UnitAuras.Add/RemovePrivateAuraAnchor` | D all | Tainted creates mainline only | none |

## 4. Legacy checklist

| Problem legacy solved | Legacy solution | On master |
|:--|:--|:--|
| Client flags for content (`e73a05e`, `3f931b2`) | `oUF.is*` in `init.lua` from `WOW_PROJECT_ID` | `compat.lua` public flags (step 2); core uses `Private.GameVersion` |
| `C_AddOns` missing (old clients) | `C_AddOns and … or GetAddOnMetadata` | master already handles (D all 4); drop |
| `DebuffTypeColor` removed (1.15.9/2.5.x/5.5.x, `e2ce15f`) | fallback to `AuraUtil.GetDebuffDisplayInfoTable` | master already handles |
| Custom dispel colours Stealable/Bleed/Enrage (`f3bbbd1`) | entries in `colors.dispel` | master has `Enrage`; Tainted overrides the rest (`core/colors.lua`) → drop |
| `none`/`''` dispel keys | aliases of `None` | drop; Tainted uses `"None"` (step 16) or alias (Q2) |
| `ShowBossFrameWhenUninteractable` deprecated (`fed5d15`) | local fallback | master uses `unitExists` (UnitIsVisible) → already handled |
| Blizzard frames without rolesets | hide + reparent to hidden parent | shim, merge-base technique (step 3) |
| Boss frames without container | per-index `Boss%dTargetFrame` | master loop + nil-safe container → already handled |
| Party frames | `PartyMemberFrame%d` | master `PartyMemberFramePool` exists on Classic → drop legacy |
| Arena frames | `ArenaEnemyFrame%d`, `Arena_LoadUI` no-op, `showArenaEnemyFrames` CVar | step 3 (Q4 for `Arena_LoadUI`) |
| `ComboFrame` visible | `handleFrame(ComboFrame)` | step 3 |
| Pooled nameplate UnitFrames re-show (`b199095`) | `OnShow` hide hooked per UnitFrame | step 3 |
| Pet battles show frames | `PetBattleFrameHider` parent | step 4 |
| Ping on Classic | removed `PingableUnitFrameTemplate`, `ping-receiver` attr | template is a stub on Classic → keep master |
| Retail callbacks/colours/factory/header/nameplate driver (`a997e7f`, `b1e765f`) | hand-port | master native → drop |
| `__unit`/`__realUnit`/`__unitIndex` (`55f37cd`) | hand-port | master native → drop |
| Target/Phase/Summon/PvPClassification (`55f37cd`) | Retail files | identical to master → drop |
| Heal prediction in Health/Power (`5330b4c`) | calculator sub-widgets | master native → drop |
| Selection colour (no `UnitSelectionType`) | `Private.unitSelectionColor` → colour object | step 6 (Q3) |
| Smooth gradient colours (`Private.SmoothColor`, `colors.smooth`) | gradient helpers | master curves (D all, used by Tainted) → drop |
| `ColorMixin` nil alpha breaks `ColorCurve:AddPoint` | `a or 1` | check in-game; master `SetRGBA(r,g,b,a)` with `a=nil` → **UNVERIFIED**, fix in `colors.lua` only if it fails |
| Death rune colour, rune types (`f7b410d`) | `runes[4]`, `GetRuneType` | step 11 |
| AdditionalPower pairs (`05e51cb`) | private table per client | step 12 |
| Era `TotemFrame` (`7377f7c`) | guard | step 7 |
| Aura growth direction (`5fd0303`) | `growthX/Y` | step 10 |
| Player castbar hide without `CastingBarFrame_SetUnit` (`51b3f32`) | fallback | master uses `PlayerCastingBarFrame` (exists) → already handled |
| Range on Classic | 0.2 s shared poll | not needed (step 14) |
| Combo points on target, MoP class powers | `GetComboPoints(unit,'target')`, `COMBO_TARGET_CHANGED`, `isMoP` branches | step 8b/8c |
| `RegisterCombatEvent` (`combatevents.lua`) | base leftover | no caller anywhere → drop |
| Patch bumps (`3b65657`, `21bdcbd`) | TOC interface | step 1 |

## 5. Element classification (master vs `classic-legacy`)

| Element | Class | Note |
|:--|:--|:--|
| PhaseIndicator, PvPClassificationIndicator, SummonIndicator, TargetIndicator | identical | — |
| AssistantIndicator, CombatIndicator, LeaderIndicator, RaidTargetIndicator, RestingIndicator, ResurrectIndicator, ThreatIndicator, Portrait, ReadyCheckIndicator | API availability (master runs as is) | diffs are `__unit`, secret guards, atlases |
| GroupRoleIndicator, RaidRoleIndicator | API availability | Classic uses the non-PTR `else`; upstream will remove it (merge risk) |
| Health, Power, AlternativePower | shim candidate | `unitSelectionColor` (step 6); calculator/percent APIs **UNVERIFIED** |
| PvPIndicator | shim candidate | step 9 |
| Totems | shim candidate | step 7 |
| Tags | shim candidate | step 13; percent APIs **UNVERIFIED** |
| Castbar, Range | shim candidate (failure-driven) | step 14 |
| AdditionalPower | real classic delta | pairs data (step 12) |
| ClassPower | real classic delta | target combo points, MoP powers (step 8) |
| Runes | real classic delta | rune types (step 11) |
| Auras | real classic delta → Retail-only master file | replaced by the button element (step 10) |
| Stagger | API availability | MoP monks only; loads fine elsewhere |
| QuestIndicator | Retail-only | kept, inert on Classic (Q8) |
| Happiness, MasterLooterIndicator | shim candidate | enabled on Classic (step 13b) |
| FocusIndicator, PrivateAuras | load and run; unused by Tainted on Classic | keep |
| `combatevents.lua`, gradient helpers, `.bg`/`.multiplier` | classic-only (legacy) | recommend drop (no user) |

## 6. Verification strategy (no game client)

1. **luacheck per client.** This is the worthwhile "harness". A throwaway script (scratchpad, not
   committed) builds a `read_globals` list per worktree:
   - generated docs: global functions + namespaces
   - non-Mainline FrameXML: `name="…"` frames and `function X(` / `X =` globals
   It then runs `luacheck --no-config --std lua51 --read-globals <list> --only 113 .` on the classic
   branch. Every undefined global is an unguarded Classic gap. Re-run after each step: the expected
   residue is only guarded names (e.g. `UnitFrameUtil` under `PTR`).
2. **grep audits.**
   - events: `'[A-Z_]+'` vs `LiteralName =` per worktree (no unknown event may be registered
     unguarded)
   - `:SetRolesets`, `UnitFrameUtil`, `Enum.*` members, `*Template` names vs XML
3. **Lua stub harness** (load files with a mocked API): **not worth building**. The blockers are
   runtime frame behaviour (rolesets, secure templates, event dispatch), which a mock can't
   reproduce honestly. Load-time nil globals are already covered by (1).
4. **In-game checklist**, every client unless noted:
   - [ ] login + `/reload`, no Lua errors (BugSack/`/console scriptErrors 1`)
   - [ ] player, target, targettarget, pet, focus/focustarget (focus on Era **UNVERIFIED**)
   - [ ] party (join/leave, in combat), raid (roster changes, healer layout), boss (`/tainted test boss`), arena (T/W/M; prep on MoP)
   - [ ] nameplates: add/remove/reuse, target highlight, selection colours, widgets-only/game objects, Blizzard plate hidden
   - [ ] castbar: player/target/channel/interrupt/not-interruptible/fail, time text, pet castbar hidden
   - [ ] auras: buffs/debuffs growth, timers, tooltips, dispel colours, stealable; AuraTrack, RaidDebuffs
   - [ ] power: mana/rage/energy/runic; AdditionalPower druid (W/M), Mistweaver (M); AlternativePower bar hidden
   - [ ] ClassPower: combo points (rogue/druid, target switch), vehicle (W/M), MoP chi/holy power/warlock
   - [ ] Runes (W/M) incl. death runes; Totems (Era shaman, W/M); Stagger (M)
   - [ ] health prediction (heals incoming, absorbs on W/M)
   - [ ] tags (all Tainted tags; arena tags on M)
   - [ ] range alpha updates moving in/out of 40 yd
   - [ ] indicators: leader, assist, raid role, group role, ready check, resurrect, summon, phase, PvP, raid target, combat, resting
   - [ ] Blizzard frames never appear (player/pet/target/combo/focus/party/boss/arena); MoP pet battle hides frames
   - [ ] Retail/Forever unchanged (`libs/oUF` untouched)

## 7. Risks and open questions

**Decisions:** all resolved, see "Decisions (2026-10-24)" at the top.

**UNVERIFIED** (in-game only): castbar duration objects and text binding; Tags percent APIs and
seconds formatter; Health calculator getters; `UNIT_IN_RANGE_UPDATE` cadence; `UnitPower` combo
points on Classic; `COMBO_TARGET_CHANGED`; arena spec APIs per client;
honor APIs; WotLK `GetSpecialization`; focus on Era; nil-alpha `ColorMixin` with curves.

**Hard-fork triggers.** Any of these would justify a hard fork instead:
- the castbar duration APIs are stubs on Classic, so the castbar needs an `OnUpdate` rewrite (large
  delta in a hot file)
- upstream deletes the non-PTR branches in several elements at once
- upstream makes `AuraContainer` load-bearing in core

If two of these happen, a separate maintained branch with periodic cherry-picks is cheaper than
merges.

## 8. Estimated size

oUF `classic`:
- **~18–21 commits**: setup 0, manifests/compat 2, core 4, elements 10–12, cleanup 2
- **~16 files**: `oUF.toc`, `oUF.xml`, `.luacheckrc`, `compat.lua` (new, ~80–120 lines),
  `blizzard.lua`, `ouf.lua`, `units.lua`, `private.lua`, `colors.lua`, `elements/{totems,classpower,pvpindicator,runes,additionalpower,tags,happiness,masterlooterindicator,health}.lua`,
  `elements/auras.lua` (replaced, ~900 lines from `9d557b4`), plus 0–3 from step 14
- Expected diff vs master outside the new files: **~150–250 lines**

Tainted: 1 commit, 4–5 files (pointer, `auras.lua`, `indicators.lua`, `docs/compatibility.md`, `docs/ouf-core-plan.md`).
