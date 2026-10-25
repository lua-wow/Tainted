# oUF_Classic `elements/`: NEW vs classic-legacy

Report only. Nothing was edited or committed.

## Refs and assumptions

All refs belong to the submodule `libs/oUF_Classic`, which holds `elements/` and the branches.

| Name   | Ref                                              | Commit  | Note |
|:-------|:-------------------------------------------------|:--------|:-----|
| NEW    | `refactor/classic`                               | 8a9b309 | submodule HEAD, clean tree |
| LEGACY | `classic-legacy`                                 | 55f37cd | `classic` points at the same commit |
| MASTER | `origin/master`                                  | 3692cb6 | NEW's actual base. Local `master` (8f37c36) is stale and is missing #920–#931, so view 2 uses `origin/master` |
| BASE   | `git merge-base origin/master classic-legacy`    | 9d557b4 | identical when computed with local `master` |

- Three views were used: (1) `BASE..LEGACY` is what legacy changed by hand, (2) `BASE..MASTER` is upstream drift, (3) the direct `LEGACY..NEW` diff. A fourth view, `MASTER..NEW`, separates NEW's own Classic changes from upstream code.
- API availability was checked against `Blizzard_APIDocumentationGenerated` in `classic_era` (1.15.9), `classic_anniversary` (2.5.6), `classic_titan` (3.80.2, the WotLK target) and `classic` (5.5.4, MoP). Some globals appear in no generated doc but are called by Blizzard's Classic frames. They are listed as "Blizzard-used" and appear in the UNVERIFIED list.
- All four Classic worktrees document `CreateUnitHealPredictionCalculator`, `UnitGetDetailedHealPrediction`, `GetUnitTotalModifiedMaxHealthPercent`, `C_Spell.GetSpellPowerCost`, `C_CurveUtil.CreateColorCurve`, `UnitHealthPercent`, `UnitPowerPercent`, `SetAlphaFromBoolean`, `SetTimerDuration`, `C_DurationUtil.CreateDuration` and `CreateDurationTextBinding`, `GetTotemDuration`, `UnitInRange` (returns inRange and checkedRange), `AddPrivateAuraAnchor` and `C_PartyInfo.GetLootMethod`. They also document these events: `UNIT_SPELLCAST_EMPOWER_*`, `UNIT_IN_RANGE_UPDATE`, `COMBO_TARGET_CHANGED`, `RUNE_TYPE_UPDATE`, `UNIT_HEAL_PREDICTION`, `UNIT_ABSORB_AMOUNT_CHANGED`, `UNIT_HEAL_ABSORB_AMOUNT_CHANGED`, `UNIT_MAX_HEALTH_MODIFIERS_CHANGED`, `TRAIT_CONFIG_UPDATED`, `UNIT_HAPPINESS`, `PARTY_LOOT_METHOD_CHANGED` and `PLAYER_FOCUS_CHANGED`.
- None of the four documents `UNIT_POWER_POINT_CHARGE`, `HONOR_LEVEL_UPDATE`, `GetUnitChargedPowerPoints`, `PlayerVehicleHasComboPoints`, `UnitIsMercenary`, `UnitHonorLevel` or `C_PvP.GetHonorRewardInfo`.

## 1. Summary

| File | Classification | Risk | Note |
|:-----|:---------------|:-----|:-----|
| additionalpower | Classic logic preserved | low | `SPEC_RESTRICTION` (MoP Mistweaver) and `PLAYER_SPECIALIZATION_CHANGED` are verbatim. Display pairs moved to `compat.lua` as `Private.altPowerBarPairDisplayInfo`. The druid pair on Era/TBC is a deliberate change (8a9b309); legacy showed nothing there. CostPrediction and `PostUpdateColor(color)` come from upstream |
| alternativepower | Upstream improvement | none | legacy changed only `__unit`, the selection colour, `SmoothColor` and `PostUpdateColor`. Upstream has since removed colorSelection and colorSmooth here. NEW matches MASTER exactly |
| assistantindicator | Upstream improvement | none | legacy changed only `self.unit`→`__unit` |
| auras | Preserved, plus one drop | low | the button-based Buffs/Debuffs were restored (2cc639d) along with `growthX`/`growthY` and `colors.dispel`. Legacy's Era tooltip by aura index was dropped, see §2.4 |
| castbar | Upstream improvement, plus one drop | low | legacy removed the EMPOWER events, which exist on every Classic client. Legacy's `CastingBarFrame_SetUnit` fallback was dead code, see §2.5 |
| classpower | Classic logic preserved (re-implemented) | low | MoP Arcane Charges were dropped (§2.3). `UNIT_POWER_FREQUENT` is no longer registered (§2.6) |
| combatindicator | Upstream improvement | none | `__unit` only |
| focusindicator | File only in NEW | low | upstream element. `PLAYER_FOCUS_CHANGED` exists everywhere. Tainted uses it in `units/target.lua` |
| grouproleindicator | NEW-only addition | low | Forever goes through the UnitFrameUtil path with `displayVehicleRoleIcon = false` |
| happiness | File only in NEW | low | upstream element (Forever). NEW enables it on Classic via `Private.getPetHappiness` and the PetFrame texture when the atlas is missing |
| health | Preserved, plus drops | **medium** | selection colour comes from `Private.unitSelectionColor` and happiness from `getPetHappiness`. The main-bar data source changed, see §2.2 |
| healthprediction | Removed on both sides | none | upstream folded it into Health |
| leaderindicator | Upstream improvement | none | `__unit` only |
| masterlooterindicator | File only in NEW | low | upstream element. NEW gates it on `C_PartyInfo.GetLootMethod` and makes the events unitless |
| phaseindicator | Identical | none | legacy had cherry-picked upstream 6e61212 (secret phase reason) |
| portrait | Upstream improvement | none | `__unit` only |
| power | Upstream improvement, selection colour preserved | low | legacy's CostPrediction was a backport of upstream |
| powerprediction | Removed on both sides | none | folded into Power and AdditionalPower |
| privateauras | File only in NEW | low | upstream element. The private aura anchor APIs are documented on every Classic client |
| pvpclassificationindicator | Identical | none | the pcall comes from upstream 5eb16bc |
| pvpindicator | NEW-only addition | low | `nop` fallbacks, `HONOR_LEVEL_UPDATE` gated, and an inverted `scrubsecretvalues(UnitIsPVP(unit))` (927c675) that also differs from Retail upstream, see §3 |
| questindicator | File only in NEW | low | legacy deleted it. `UnitIsQuestBoss` is UNVERIFIED, see §3 |
| raidroleindicator | NEW-only addition | low | same Forever path as grouprole |
| raidtargetindicator | Upstream improvement | none | `__unit` only |
| range | **Classic logic MISSING?** | **high** | legacy polled every 0.2 s and honoured `checkedRange`. NEW relies on events only, see §2.1 |
| readycheckindicator | Upstream improvement | none | `__unit` only |
| restingindicator | Upstream improvement | none | no legacy change |
| resurrectindicator | Upstream improvement | none | `__unit` only |
| runes | Preserved, legacy remap dropped (correct) | low | `GetRuneType`, `runemap {1,2,5,6,3,4}` and `RUNE_TYPE_UPDATE` are kept. Legacy's colour remap was wrong, see §2.8 |
| stagger | Upstream improvement | none | legacy's `GetSpecialization` local became `C_SpecializationInfo.GetSpecialization` |
| summonindicator | Identical | none | |
| tags | Classic logic preserved (shim) | low | arena spec goes through `Private.getArenaOpponentSpecInfo`. Legacy's existence guard is gone, see §2.7 |
| targetindicator | Identical | none | legacy had ported the upstream element |
| threatindicator | Upstream improvement | none | 2 lines differ, both upstream |
| totems | Classic logic preserved | none | `if(TotemFrame)` guard is verbatim |

No element file exists only in LEGACY.

## 2. Missing or intentionally dropped logic

### 2.1 range: OnUpdate polling and `checkedRange` (possibly MISSING)

- **Legacy hunk:** `classic-legacy:elements/range.lua:31-135`

  ```lua
  local function OnRangeUpdate(_, elapsed)   -- :85
  	timer = timer + elapsed
  	if(timer >= .20) then
  		for _, object in next, _FRAMES do
  			if(object:IsShown()) then Path(object, 'OnUpdate') end
  ...
  inRange, checkedRange = UnitInRange(unit)   -- :50
  if(checkedRange and not inRange) then self:SetAlpha(element.outsideAlpha) ...
  ```

- **What it did:** a shared frame polled every registered object every 0.2 s, in addition to `UNIT_IN_RANGE_UPDATE`. History: 3b65657 ("patch 1.15.7") replaced the event with polling, then e73a05e added the event back next to the poll. Fading only happened when `checkedRange` was true.
- **What NEW does:** it is event-only (`UNIT_IN_RANGE_UPDATE`, `UNIT_CONNECTION`, and `PARTY_MEMBER_ENABLE`/`PARTY_MEMBER_DISABLE` for party and raid). Eligibility is `UnitIsConnected and UnitInParty`, and NEW uses `SetAlphaFromBoolean(inRange, ...)`, which is documented everywhere. There is no equivalent of the poll in core or compat.
- **Recommendation:** needs an in-game test. The event is documented on all Classic clients, but whether it fires reliably there is not something the docs say (UNVERIFIED). If party or raid frames don't fade when a member walks out of range, port only the poll, and keep it Classic-only.

### 2.2 health: main bar data source and lazy calculator (dropped?)

- **Legacy hunk:** `classic-legacy:elements/health.lua:222`, `:235-236`, `:242`, `:459`

  ```lua
  local cur, max = UnitHealth(unit), UnitHealthMax(unit)
  ...
  if(element.TempLoss and GetUnitTotalModifiedMaxHealthPercent) then
  	lossPerc = Clamp(GetUnitTotalModifiedMaxHealthPercent(unit), 0, 1)
  ...
  -- the main bar keeps UnitHealth/UnitHealthMax, the calculator only feeds the prediction sub-widgets
  if(STATE[element].prediction) then UnitGetDetailedHealPrediction(unit, 'player', element.values) end
  ```

- **What it did:** the calculator was created and queried only when a prediction sub-widget existed. The main bar used `UnitHealth`/`UnitHealthMax`, and `element.cur`/`element.max` were set for the colour gradient.
- **What NEW does (upstream):** it calls `UnitGetDetailedHealPrediction` on every update. The main bar reads `values:GetMaximumHealth()` and `values:GetCurrentHealth()`, and smooth colouring uses `values:EvaluateCurrentHealthPercent(curve)`. All of these APIs are documented on every Classic client.
  - The `GetUnitTotalModifiedMaxHealthPercent` guard is obsolete, because the API exists everywhere.
  - The `Clamp` is gone. That matches upstream, where the value may be secret.
- **Recommendation:** needs an in-game test. Compare the bar against the real health values on the player, target, pet and party frames, and during the arena preparation fake data. Skip porting unless the values disagree. The always-on calculator call is an efficiency point that belongs upstream, not in a Classic fork.

### 2.3 classpower: MoP Mage Arcane Charges (intentionally dropped?)

- **Legacy hunk:** `classic-legacy:elements/classpower.lua:327-330`

  ```lua
  elseif(oUF.isMoP and PlayerClass == 'MAGE') then
  	ClassPowerID = SPELL_POWER_ARCANE_CHARGES
  	ClassPowerType = 'ARCANE_CHARGES'
  	RequireSpec = SPEC_MAGE_ARCANE
  ```

- **What NEW does:** the Mage block is gated by `GameCompatibility.Midnight`, so MoP mages get no ClassPower. MoP's documentation lists `Enum.PowerType.ArcaneCharges = 16`, but no MoP Blizzard frame displays it as a class bar. In MoP, Arcane Charge is a debuff.
- **Recommendation:** this is your decision. If you want it back, it needs an in-game test on MoP to see whether `UnitPower('player', 16)` reports anything (UNVERIFIED). The likely outcome is to skip it.

### 2.4 auras: Era tooltip by aura index (intentionally dropped)

- **Legacy hunk:** `classic-legacy:elements/auras.lua:80`, `:270-283`, `:289`

  ```lua
  if self.auraIndex then
  	GameTooltip:SetUnitAura(unit, self.auraIndex, self.isHarmful and "HARMFUL" or "HELPFUL")
  ...
  if oUF.isClassic then data.auraIndex = GetAuraIndex(unit, data.auraInstanceID, filter) end
  ```

- **What it did:** on Era only, legacy rescanned the auras (`GetAuraDataByIndex` in a loop for each processed aura) to show the tooltip by index. It was added in 3b65657 (1.15.7).
- **Why it can go:** Era 1.15.9 Blizzard code calls `GameTooltip:SetUnitBuffByAuraInstanceID` and `SetUnitDebuffByAuraInstanceID` itself, in `Blizzard_UnitFrame/Shared/CompactUnitFrame.lua:2133` and `PartyMemberFrame.lua:202`, with the mapping in `TooltipDataHandler.lua:595`. NEW uses those methods. Blizzard passes `self.filter` as a third argument; neither legacy nor NEW does.
- **Recommendation:** skip it, after an in-game test on Era (hover a buff and a debuff on the player and target frames).

### 2.5 castbar: `CastingBarFrame_SetUnit` fallback and EMPOWER events (intentionally dropped)

- **Legacy hunk:** `classic-legacy:elements/castbar.lua:574-581`, plus the removed `UNIT_SPELLCAST_EMPOWER_*` registrations.
- **Why it can go:**
  - No Classic worktree defines `CastingBarFrame_SetUnit`. Legacy therefore always took the `PlayerCastingBarFrame:UnregisterAllEvents()` and `:Hide()` branch, which is exactly what NEW does.
  - The EMPOWER events are documented on every Classic client, so registering them is safe.
- **Recommendation:** skip.

### 2.6 classpower: `UNIT_POWER_FREQUENT` (dropped)

- **Legacy hunk:** `classic-legacy:elements/classpower.lua:280`, `:296`
- **What NEW does:** like upstream, it registers only `UNIT_POWER_UPDATE`. Target combo points are refreshed through `PLAYER_TARGET_CHANGED` and `COMBO_TARGET_CHANGED` (`TargetComboPointsPath`).
- **Recommendation:** skip unless combo points or holy power visibly lag in-game.

### 2.7 tags: `GetArenaOpponentSpec` existence guard (re-implemented, guard gone)

- **Legacy hunk:** `classic-legacy:elements/tags.lua:152`, `:357`, written as `if(id and GetArenaOpponentSpec) then`.
- **What NEW does:** the `arenaspec` and `arenaclass` tags call `Private.getArenaOpponentSpecInfo` (`compat.lua:66-97`). The shim calls `GetArenaOpponentSpec` and `GetSpecializationInfoByID` without a guard, and so does `units.lua:143`.
  - Neither function appears in the Classic generated docs.
  - Era's Blizzard_ArenaUI calls `GetArenaOpponentSpec` (`Blizzard_ArenaUI.lua:163`), and `GetSpecializationInfoByID` is used in 7 Blizzard files on each client.
- **Recommendation:** UNVERIFIED. The calls are only reached for `arenaN` units, so test them in a TBC, WotLK or MoP arena or skirmish. Add a guard only if one errors.

### 2.8 runes: rune-type colour remap (intentionally dropped, NEW is correct)

- **Legacy hunk:** `classic-legacy:elements/runes.lua:61`, `local runeTypeColor = {1, 3, 2, 4}`. Legacy itself marked it "(unverified)".
- **Why NEW is right:** Blizzard defines `RUNETYPE_BLOOD=1`, `RUNETYPE_FROST=2`, `RUNETYPE_UNHOLY=3` and `RUNETYPE_DEATH=4` in `Blizzard_UnitFrame/Classic/RuneFrame_Shared.lua:6-9`. NEW's `colors.runes` uses that same order (blood, frost, unholy, death), so indexing it directly by `GetRuneType` is correct. Legacy's remap swapped frost and unholy.
- Legacy also tinted `rune.bg` itself. NEW leaves that to Tainted's `Runes:PostUpdateColor(color, rune)` in `modules/unitframes/elements/runes.lua:22`.
- **Recommendation:** skip.

### 2.9 health: `element.cur` and `element.max`

NEW no longer sets these fields; upstream reads them through the calculator instead. A grep of Tainted's `modules/unitframes/elements/{health,power}.lua` finds no reads of them. **Recommendation:** none.

## 3. Files only on one side

| File | Side | Recommendation |
|:-----|:-----|:---------------|
| questindicator.lua | NEW (legacy deleted it in 3b65657) | Keep it. `UnitIsQuestBoss` is not in any generated doc, and the only Classic Blizzard call (`Classic/TargetFrame.lua:389`) is commented out, so it is UNVERIFIED. Tainted doesn't use QuestIndicator. If you ever do, add a guard first |
| privateauras.lua | NEW (upstream) | Keep. Tainted uses it in `units/party.lua` and `units/raid.lua` (created via `auras_mainline.lua`). Check whether those calls run on Classic |
| focusindicator.lua | NEW (upstream) | Keep. Used by `units/target.lua` |
| happiness.lua | NEW (upstream plus Classic shim) | Keep. Test on a hunter pet |
| masterlooterindicator.lua | NEW (upstream plus Classic shim) | Keep. Test in a group with master loot |
| healthprediction.lua, powerprediction.lua | in neither (present only at BASE) | nothing to do |

`pvpindicator`: NEW inverts upstream's `not scrubsecretvalues(UnitIsPVP(unit))` (927c675, "show faction icon only while flagged"). If Retail shows the same behaviour, it is worth reporting upstream; the Retail oUF is read-only here. See also the FFA flag note in memory.

## 4. In-game checks per client

- **All Classic clients**
  - Range fade on party and raid when a member leaves and re-enters 40 yd, including while stationary (§2.1).
  - Health bar values against `/dump UnitHealth("target"), UnitHealthMax("target")` (§2.2).
  - Aura tooltips on buffs and debuffs (§2.4).
  - Player castbar shows, and Blizzard's cast bar stays hidden after `/reload` and after a disable/enable cycle.
  - FocusIndicator works.
- **Classic Era**
  - Totems are skipped cleanly without TotemFrame.
  - Happiness icon and tag on a hunter pet.
  - Rogue and druid combo points move on target change (`GetComboPoints(unit, 'target')`).
  - Druid AdditionalPower mana bar in cat and bear form (new behaviour, 8a9b309).
  - PvPIndicator only while flagged.
- **TBC (Anniversary)**
  - Same as Era for combo points, the druid mana bar and happiness.
  - Arena `[arenaspec]` and `[arenaclass]` tags and arena preparation (§2.7).
- **WotLK (Titan)**
  - Rune colours by type, including death runes (`RUNE_TYPE_UPDATE`) and Blizzard's 1,2,5,6,3,4 order.
  - Vehicle combo points (`UnitIgnoresVehicleComboPoints` fallback).
  - Arena tags.
- **MoP**
  - Monk chi on every spec (pre-Legion), Mistweaver mana bar on spec change, stagger on Brewmaster.
  - Holy power, soul shards and burning embers (Destruction).
  - Arcane mage shows no ClassPower (decision needed, §2.3).
  - Rogue combo points don't stick to the previous target.
  - Arena tags.

## 5. UNVERIFIED

- Whether `UNIT_IN_RANGE_UPDATE` fires reliably on Classic for party and raid members. The event is documented; its runtime behaviour isn't.
- `UnitIsQuestBoss` on any Classic client.
- `GetArenaOpponentSpec` and `GetSpecializationInfoByID`: Blizzard-used but missing from the Classic generated docs.
- Whether `UnitPower('player', Enum.PowerType.ArcaneCharges)` returns anything on MoP.
- `GetComboPoints`, `UnitIgnoresVehicleComboPoints`, `UnitSelectionColor`, `GetPetHappiness` and `GetRuneType`: none is in the generated docs, but each is called by Blizzard Classic frames (`Classic/ComboFrame.lua:46,72`, `TargetFrame.lua:292`, `PetFrame.lua:169`, `RuneFrame_Shared.lua:58`).
- Whether `TotemFrame` loads per client. The XML exists in the Era worktree. Legacy and NEW both guard on `TotemFrame`, so this carries no risk.

## 6. Commands run

Run in `libs/oUF_Classic` unless noted:

```sh
git branch -a
git -C libs/oUF_Classic branch -a        # from the Tainted root
git status --short
git merge-base master classic-legacy
git merge-base origin/master classic-legacy
git merge-base master refactor/classic
git merge-base refactor/classic origin/master
git rev-parse --short classic classic-legacy refactor/classic master
git rev-list --count classic-legacy..classic
git rev-list --count classic..classic-legacy
git log --oneline --no-merges 9d557b4..classic-legacy
git log --oneline master..refactor/classic
git ls-tree --name-only classic-legacy elements/
git ls-tree --name-only refactor/classic elements/
git diff --stat 9d557b4 classic-legacy -- elements
git diff --stat 9d557b4 origin/master -- elements
git diff --stat -w --ignore-blank-lines origin/master refactor/classic -- elements
git diff --stat -w --ignore-blank-lines classic-legacy refactor/classic -- elements
git diff -w -U1 9d557b4 classic-legacy -- elements/<file>.lua
git diff -w -U2 origin/master refactor/classic -- elements/<file>.lua
git diff -w --ignore-blank-lines classic-legacy refactor/classic -- elements/<file>.lua
git diff -w --numstat <a> <b> -- elements/<file>.lua   # per-file matrix
git show classic-legacy:elements/<file>.lua | grep -n '<pattern>'
git show 3b65657 -- elements/range.lua
git show e73a05e -- elements/range.lua
git log -S'GetAuraIndex' classic-legacy -- elements/auras.lua
git log -S'pcall(UnitPvpClassification' master -- elements/pvpclassificationindicator.lua
git log -S'issecretvalue(phaseReason)' master -- elements/phaseindicator.lua
grep -n '<api>' elements/*.lua compat.lua units.lua private.lua colors.lua
```

API checks, run in `../refs/wow-ui-source` for each of `classic_era`, `classic_anniversary`, `classic_titan` and `classic`:

```sh
grep -l 'Name = "<Api>"' worktrees/<w>/Interface/AddOns/Blizzard_APIDocumentationGenerated/*.lua
grep -l 'LiteralName = "<EVENT>"' worktrees/<w>/Interface/AddOns/Blizzard_APIDocumentationGenerated/*.lua
grep -rln '<global>' worktrees/<w>/Interface/AddOns --include=*.lua
grep -rl 'name="<Frame>"' worktrees/<w>/Interface/AddOns --include=*.xml
grep -n 'RUNETYPE_' worktrees/classic_titan/Interface/AddOns/Blizzard_UnitFrame/Classic/RuneFrame_Shared.lua
```

Tainted usage, from the Tainted root:

```sh
grep -rn 'QuestIndicator\|PrivateAuras\|FocusIndicator\|TargetIndicator' modules
grep -rn 'PostCastStart\|PostCastInterruptible' modules
grep -n 'PostUpdate' modules/unitframes/elements/classpower.lua
```
