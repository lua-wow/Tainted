# oUF_Classic: master minus Retail + classic overlay (plan, rev. 3)

## Context
New `classic` branch from master `3e7eff4` (the commit `libs/oUF` uses), overlaid with the Classic elements from
`refactor/retail-mirror`. **Decided:**
- No rebase, no old core files.
- Squashed commits.
- **The branch doesn't support Retail or Forever:** Retail-only master code that no Classic client can reach is removed
  (whole blocks or files), not polyfilled.
- Functions that can stay are not rewritten.
- The Retail-shaped interface Tainted calls is kept:
  - callbacks and their argument shapes (`PostUpdateColor(unit, color)`)
  - ColorMixin colour objects with curves
  - `SpawnHeader` + `SetVisibility`, and the `SpawnNamePlates` driver with `Set*Callback`
  - `Pause/ResumeElement`, `IsEventless`, `oUF.Enum`

Baseline: merge-base `9d557b4`; 20 classic-only vs 384 master-only commits. The oUF_Classic clone **needs a fetch**: it lacks
`3e7eff4`, its `origin/master` is `a1f9df7`.

Categories:
- **D** drift (= master)
- **C** needed for Classic (kept or added, with reason)
- **O** obsolete Classic code (not carried over)
- **T** Tainted relies on it
- **R** Retail-only, remove

For every **R**, "proof" means the symbol is absent from all four Classic worktrees (classic_era 1.15.9, classic_anniversary
2.5.6, classic_titan 3.80.2, classic 5.5.4). I checked both the generated API docs and FrameXML (`grep -rlw` count 0). For a
`GameVersion` gate, the proof is the interface ranges: Classic is 11509/20506/38002/50504, `Forever` is 16000–19999, and the
Retail keys are ≥ 60000.

**Removal rule:** remove whole statements, blocks, table entries outside shared tables, or files. Keep Retail terms inside a
shared expression or table, and Retail branches of an if/else whose other side Classic uses (they're unreached, and removing
them would mean rewriting a function).

## 1. Overlay from refactor/retail-mirror

**Overlaid** (23 differing elements, verbatim):
`additionalpower alternativepower assistantindicator auras castbar classpower combatindicator grouproleindicator health
leaderindicator portrait power pvpindicator raidroleindicator raidtargetindicator range readycheckindicator restingindicator
resurrectindicator runes stagger threatindicator totems`.

**Not overlaid, already equal to master:** `phaseindicator`, `pvpclassificationindicator`, `summonindicator`, `targetindicator`,
`factory.lua`, `finalize.lua`.

**Dropped from the mirror (O/D):**
- all core files (`ouf private events units blizzard colors init`)
- `combatevents.lua` (no `RegisterCombatEvent` caller anywhere)
- `elements/tags.lua` (old internals `__tags`, `__elements`, `__eventless`, `fs.parent`)
- `oUF.toc`/`oUF.xml`/`.luacheckrc` (rewritten from master)
- repo meta files

**Master elements:**

| File | Category | Reason / proof |
|:--|:--|:--|
| `happiness.lua` | R | `Enable` returns unless `GameVersion.Forever`; `C_PetInfo.GetPetHappiness` is absent on all 4 |
| `masterlooterindicator.lua` | R | `Enable` returns unless `GameVersion.Forever` (`C_PartyInfo.GetLootMethod` exists, but the gate is never true on Classic). Tainted creates the widget only on mainline (`modules/unitframes/elements/indicators.lua:137`) |
| `questindicator.lua` | R | `UnitIsQuestBoss` absent on all 4 (its only FrameXML mention is commented out, MoP `Classic/TargetFrame.lua:389`) |
| `focusindicator.lua` | **keep (D)** | reachable: `UnitIsUnit`, focus exists. Tainted creates it only on mainline (`indicators.lua:45`), so it stays inert |
| `privateauras.lua` | **keep (D)** | reachable: `C_UnitAuras.AddPrivateAuraAnchor` + `BuffFramePrivateAuraAnchorTemplate` exist on all 4. Tainted creates it only on mainline (`units/party.lua:17`) |

## 2. Core classification (master as base)

**ouf.lua**
- **R** Spawn: the `if(unit:match('arena%d?')) SetRolesets('arenaFrames') else SetRolesets('unitFrames') end` block. SpawnHeader:
  the `header:SetRolesets('unitFrames')` line. `SetRolesets` is absent on all 4 (Retail/Forever `SimpleFrameAPIDocumentation`
  only).
- **C** That roleset also hid unit frames in pet battles, and MoP has pet battles: add a `PetBattleFrameHider` block
  (`[petbattle] hide; show`, as before). It becomes the `CreateFrame` parent in Spawn and SpawnHeader (2 arguments).
- **D** the rest, including `PingableUnitFrameTemplate` (an empty stub on Classic, `Blizzard_SharedXML/Classic/Stubs.xml`), the
  pause API, `AddMetaElement`, `GetUnitFrame`, `issecretvalue` (exists on all 4) and the nameplate driver
  (`UnitNameplateShowsWidgetsOnly`, `UnitIsGameObject` and `Set/ClearAllHitTestPoints` exist on all 4).

**blizzard.lua**
- **R + C** handleFrame: `frame:SetRolesets('alwaysBlocked')` (proof as above). Replaced by Classic blocking: `Hide()`,
  reparent to a hidden parent, `SetParent` hook (the pre-rewrite Classic method), with the `doNotReparent` flag for nameplates.
- **R** player: the Forever PvP-sound block + `isPlayerHooked` (gate `GameVersion.Forever`; no else).
- **R** boss: `handleFrame(BossTargetFrameContainer)` + its comment. No Classic XML defines it; only EditMode references it. The
  `Boss%dTargetFrame` loop stays (D: Boss1-5 exist, `MAX_BOSS_FRAMES = 5`).
- **R + C** arena: the body of the `isArenaHooked` block. `CompactArenaFrame` is created only by
  `Blizzard_UnitFrame_Mainline.toc`, and `ArenaEnemyMatchFramesContainer` is absent on all 4. Replaced by Classic
  `ArenaEnemyFrame1-5` (`Blizzard_ArenaUI.xml`), `Arena_LoadUI` no-op and the `showArenaEnemyFrames` CVar.
- **C** target: `handleFrame(ComboFrame)` (`Classic/ComboFrame.xml`, in the Classic TOC only).
- **C** nameplate branch: `handleFrame(frame.UnitFrame, true)` + a once-per-frame `OnShow` hide hook (Blizzard pools nameplate
  UnitFrames; without rolesets they re-show).
- **D** party (`PartyFrame.PartyMemberFramePool` and `CompactPartyFrameMember1-5` exist on all 4), health/castbar/aura lookups
  (Retail terms inside shared `or` expressions: kept). **T**: Tainted also reparents `PartyFrame`
  (`modules/unitframes/core.lua:88-93`).

**private.lua**
- **R** the `validSelectionTypes` loop + `Private.unitSelectionType`. `UnitSelectionType` is absent on all 4. Its only callers are
  master health/power/alternativepower, which are replaced by the overlay; the overlaid elements mention it only in doc comments.
- **D** `GameVersion`/`GameCompatibility` (data; Classic elements use `Mists`/`Vanilla`), `unitIsUnit`
  (`C_Secrets.CanCompareUnitTokens` exists on all 4), and the rest.

**units.lua**
- **R + C** arena prep `colorClass`: `UnitFrameUtil.GetArenaOpponentSpecDisplayInfo` is absent on all 4, but Classic does reach
  this branch. The 2 lines become `GetSpecializationInfoByID(specID)` → `self.colors.class[class]` (a colour object, same shape).
- **C** register arena prep only `if(GetArenaOpponentSpec)`. It's undocumented on Classic (`Blizzard_ArenaUI` calls the
  `GetNumArenaOpponentSpecs` family); **unverified** per client.
- **D** the rest (curve `colorSmooth`, pause/resume, `IsEventless`, secret-safe `numOpponents`).

**colors.lua**
- **R** the `if(color.atlasElementName)` block (absent from Classic `PowerBarColor`, 0 refs). Also the ICICLES/TIP_OF_THE_SPEAR
  block: fake Retail resources, no Classic element or tag reads them.
- **D (kept)** the soul-fragment entries in `stageIndices` (inside a shared table), curves (`C_CurveUtil` on all 4), atlas
  validation (`C_Texture.GetAtlasInfo`), dispel from `AuraUtil.GetDebuffDisplayInfoTable`, `happiness`, Enum-keyed `selection`.
- **C** `runes[4]` death colour (WotLK/MoP rune types). **T**: `dispel` by name, `CreateColor`, and the happiness/Bleed/Enrage
  overrides (`core/colors.lua:153,238`, `core/curves.lua:29`).

**elements/tags.lua**
- **R** the `happiness` tag + its `Events` entry (`GameVersion.Forever` gate; `C_PetInfo` absent).
- **R + C** `arenaspec` and the `raidcolor` arena branch: `UnitFrameUtil` → `GetArenaOpponentSpec` + `GetSpecializationInfoByID`
  (specName / class colour via `GenerateHexColorMarkup`).
- **D (kept)** the `name` Forever branch and `chi`'s `GameCompatibility.Legion`: Classic uses the other side of both.

**Other files**
- **events.lua, init.lua, enums.lua, factory.lua, finalize.lua**: D (enums is used by `colors.selection`).
- **oUF.toc** C: `Interface: 11509, 20506, 38002, 50504`, and `AllowLoadGameType: vanilla, tbc, wrath, mists` replaces master's
  `standard, camelot`.
- **oUF.xml** R: the 3 removed elements.
- **.luacheckrc** R/C: drop globals only the removed code used (`SOUNDKIT`, `PlaySound`, `C_PetInfo`, `UnitFrameUtil`,
  `ArenaEnemyMatchFramesContainer`, `UnitSelectionType`, `UnitIsQuestBoss`, …); add the Classic ones (`Arena_LoadUI` write,
  `ComboFrame`, `GetRuneType`, `UnitSelectionColor`, `CastingBarFrame*`, `RegisterStateDriver`, …).

No shim file: each Classic replacement sits where the Retail block was. That keeps a re-applied upstream diff local to the
same hunk. The only new helper is `Private.unitSelectionColor`, which goes in `private.lua` next to the removed
`unitSelectionType`. That spot is where its Retail counterpart lived, so a future upstream change there conflicts visibly.

## 3. Overlaid elements on old core helpers (fixes, in C3)

| Old helper | Sites | Master | Fix |
|:--|:--|:--|:--|
| `Private.UnitSelectionColor` | health:139, power:108, alternativepower:57 | never existed | `Private.unitSelectionColor` (private.lua, see above). **T**: Classic nameplate `colorSelection` (`units/nameplate.lua:170`) |
| `self:ColorGradient`, `colors.smooth`, `Private.SmoothColor`, `.smoothGradient` | health:165, power:180, alternativepower:105, additionalpower:92 | removed (curves) | `self.colors.health:GetCurve()` with `UnitHealthPercent(unit, true, curve)` / `UnitPowerPercent` (curve arg documented on all 4); `curve:Evaluate(cur / max)` for alt/additional power. Tainted uses no `colorSmooth` on Classic |
| `Private.GetAltPowerBarDisplayInfo` | additionalpower:74 | never existed | local table in additionalpower.lua |
| indexed colours `color[1..3]` | health:172, power:190, alternativepower:110, additionalpower:97, classpower:73, stagger:72, runes:110,148, threatindicator:67, auras:213 | no indices | `color:GetRGB()` |
| `oUF.isMoP`, `oUF.isClassic` | classpower:310-327, additionalpower:77, auras:289 | removed | `Private.GameVersion.Mists` / `.Vanilla` |
| `colors.dispel.none` | auras:211 | key is `None` | `.None`; **T** Tainted `modules/unitframes/elements/auras.lua:155` → `"None"` |
| `colors.runes[4]` | runes:109 | absent | added in colors.lua (C) |
| `Private.unitExists` | readycheck:43, threat:35 | same API (`UnitIsVisible`) | none |
| `DisableElement(self)`, pause/resume | all | `(self, unit)`; nameplates and arena prep pause/resume | none; test re-enable |

**T** `libs/oUF_RaidDebuffs` reads `oUF.isRetail/isClassic/isMoP`, which no longer exist → N2.

## 4. Commits

**C1: classic: drop Retail-only code, load on Era, TBC, WotLK and MoP**
- Change: the §2 R/C edits in `ouf.lua`, `blizzard.lua`, `private.lua`, `units.lua`, `colors.lua`, `elements/tags.lua`; `git rm` the 3
  elements; `oUF.toc`, `oUF.xml`, `.luacheckrc`.
- Clients: none yet (master elements don't run on Classic).
- Test: luacheck.
- Depends on: fetch + branch.

**C2: elements: Classic API mirror**
- Change: overlay of the 23 elements, verbatim.
- Clients: none yet.
- Test: luacheck.
- Depends on: C1.

**C3: elements: use master core**
- Change: the §3 fixes.
- Clients: Era, TBC, WotLK, MoP (in-game).
- Test:
  - login, /reload, target change, focus (TBC+), targettarget updating, `/tainted test boss`, `/tainted test arena`
  - arena prep (MoP, real queue), party/raid join/leave, combat, vehicle (WotLK), pet battle hides frames (MoP), DK rune
    types (WotLK, MoP)
  - Blizzard player/pet/target/combo/focus/boss/arena/party frames never appear
  - nameplates add/remove/target/widgets-only/forbidden friendly plates in instances; nameplate selection colours
  - no Lua errors
- Depends on: C2.

**P1: parent repo**
- Change: Tainted `auras.lua:155` (N4), RaidDebuffs per N2, `docs/compatibility.md` oUF-variants note, the pointer.
- Clients: all 4.
- Test: `make check` + /reload each client.
- Depends on: C3 pushed.

After C1, I'll paste the real `git diff --stat 3e7eff4..classic-next` and check that every core file in it matches a §2 line.

## 5. Git commands (you run them)

```sh
cd libs/oUF_Classic
git fetch origin
git cat-file -t 3e7eff4                               # "commit"
git tag archive/classic-legacy origin/classic          # 03fdc7b
git tag archive/retail-mirror refactor/retail-mirror   # 6f7e1fe
git push origin archive/classic-legacy archive/retail-mirror
git switch -c classic-next 3e7eff4

# C1 (after my edits)
git rm elements/happiness.lua elements/masterlooterindicator.lua elements/questindicator.lua
git add oUF.toc oUF.xml .luacheckrc ouf.lua blizzard.lua private.lua units.lua colors.lua elements/tags.lua
git commit

# C2
git checkout archive/retail-mirror -- \
  elements/additionalpower.lua elements/alternativepower.lua elements/assistantindicator.lua elements/auras.lua \
  elements/castbar.lua elements/classpower.lua elements/combatindicator.lua elements/grouproleindicator.lua \
  elements/health.lua elements/leaderindicator.lua elements/portrait.lua elements/power.lua elements/pvpindicator.lua \
  elements/raidroleindicator.lua elements/raidtargetindicator.lua elements/range.lua elements/readycheckindicator.lua \
  elements/restingindicator.lua elements/resurrectindicator.lua elements/runes.lua elements/stagger.lua \
  elements/threatindicator.lua elements/totems.lua
git commit

# C3 (after my edits)
git add elements && git commit
git diff --stat 3e7eff4..classic-next

# publish
git branch -f classic classic-next
git switch classic && git branch -d classic-next
git push --force-with-lease=classic:03fdc7b origin classic
git branch -D refactor/retail-mirror && git push origin --delete refactor/retail-mirror
cd ../.. && git add libs/oUF_Classic && git commit     # P1
```

No `merge --squash`: it would bring the old core files back. `checkout <tag> -- <paths>` overlays path by path.

End state:
- `master`: untouched
- `classic`: `3e7eff4` + C1–C3
- tags: `archive/classic-legacy`, `archive/retail-mirror` (they keep old Tainted pointers fetchable)
- `.gitmodules`: `branch = classic`

## 6. Needs confirmation
- **N2** RaidDebuffs: change it upstream to its own `WOW_PROJECT_ID` flags (recommended; master has no `oUF.is*`), or
  re-add the flags in init.lua (C).
- **N3** Smooth colour via master curves (recommended) or a local gradient.
- **N4** `dispel.None` in classic auras + Tainted `auras.lua:155` (recommended) or a `none` alias in colors.lua.
- **N5** `oUF.toc` Author "Luaerror".
- **N6** C2/C3 separate (recommended) or squashed.
- **N7** Pet-battle hider on all 4 (previous behaviour) or MoP only.
- **N8** Tag names and the force-push.
- **N9** Keep `focusindicator`/`privateauras` (reachable, inert for Tainted), or remove them as unused.

Unverified: `GetArenaOpponentSpec`/`GetNumArenaOpponentSpecs` per client; master nameplate widget reparenting on Classic (C3).

## Execution protocol
For each step: one question → wait → edit → `cd libs/oUF_Classic && mise exec -- luacheck .` + `mise exec -- make check` → report →
commit message as text → stop until "committed". No git or gh writes by me; `libs/oUF` untouched; `docs/ouf-core-plan.md` only after
"write the plan".
