# oUF vs oUF_Classic

Compared 2026-10-19. Goal: make `libs/oUF_Classic` mirror `libs/oUF`'s element API so Tainted needs
fewer client branches. Paths are relative to each library unless prefixed.

| Library           | Clients (`oUF.toc`)                                        | Branch    | Commit                                     | Commit date |
|:------------------|:-----------------------------------------------------------|:----------|:-------------------------------------------|:------------|
| `libs/oUF`        | `120100, 120105, 16001`; `AllowLoadGameType: standard, camelot` | `master`  | `a1f9df774263d00e0feedca40200065f06e14eda` | 2026-10-05  |
| `libs/oUF_Classic`| `11509, 20506, 38002, 50504`                               | `classic` | `03fdc7b6a78b96320dd4196f8a9d58ba229bced5` | 2026-10-18  |

Same upstream (`lua-wow/oUF`). Merge base `9d557b4` (2025-04-26, "core: Handle up to 10 boss frames
(#713)"): `master` is 382 commits ahead, `classic` 17.

**Drift vs intentional.** Classic still matches the merge base for `frame.unit`, `smoothGradient`,
`.bg`/`.multiplier`, `ColorGradient`, `SetColorDisconnected`, element-owned state and the Classic aura
element (`git grep 9d557b4`). Everything Retail added after that (`__unit`, `STATE` tables, color
curves, duration objects, `.smoothing`, atlases, secret handling, pause/resume, `AddMetaElement`) is
**drift** (marked D below). Intentional Classic work is the 17 classic commits (marked I): `a997e7f`
(Retail callbacks/colors/factory), `5330b4c` (prediction inside Health/Power), `f7b410d` (rune types),
`05e51cb` (AdditionalPower pairs), `b199095` (nameplates), `5fd0303` (aura growth), `7377f7c` (Era
TotemFrame), `e73a05e` (one oUF for Era/TBC/WotLK/MoP).

**API evidence.** `../refs/wow-ui-source` generated docs (`Blizzard_APIDocumentationGenerated`) for
live 12.1.5, forever 1.60.1, classic 5.5.4, classic_titan 3.80.2, classic_anniversary 2.5.6,
classic_era 1.15.9. On all four Classic clients the docs list the Midnight objects (duration objects,
`C_CurveUtil.CreateColorCurve`, `CreateUnitHealPredictionCalculator`, `UnitHealthPercent`,
`UnitCastingDuration`, `StatusBar:SetTimerDuration`, `SetAlphaFromBoolean`, `C_StringUtil`) and have **no
`Secret*` flags** (only 3 `SecretAura`), so values are plain there. The Classic docs also include
Retail-only systems (housing), so "in the docs" means compiled into the client, not proven usable:
**Classic use of any API not already called by `oUF_Classic` or Blizzard Classic code is unverified
in-game.** Legacy globals (`UnitIsTapDenied`, `GetComboPoints`, `GetPetHappiness`, `GetPartyAssignment`)
are missing from Classic docs but used by Blizzard Classic code (cited where relevant).

## 1. Element inventory

| Element                    | oUF | oUF_Classic | Notes |
|:---------------------------|:----|:------------|:------|
| AdditionalPower            | yes | partial | Classic pairs from `private.lua:GetAltPowerBarDisplayInfo` (I); no curve smoothing |
| AlternativePower           | yes | partial | Classic has extra color modes (threat/class/selection/reaction/smooth, base) |
| AssistantIndicator         | yes | yes     | `__unit` only, plus secret guards |
| Auras                      | yes | partial | Different element: Retail `AddMetaElement` + `AuraContainer`; Classic `Auras`/`Buffs`/`Debuffs` buttons |
| Castbar                    | yes | partial | Retail duration objects; Classic `OnUpdate` + public attributes |
| ClassPower                 | yes | partial | Classic: combo points, MoP Chi/Holy Power/Soul Shards/Arcane Charges only |
| CombatIndicator            | yes | yes     | default texture differs |
| FocusIndicator             | yes | no      | |
| GroupRoleIndicator         | yes | partial | atlas options, `PLAYER_ROLES_ASSIGNED` path |
| Happiness                  | yes | no      | Retail runs it on Forever only |
| Health                     | yes | partial | color pipeline (curves vs gradient), event set |
| LeaderIndicator            | yes | yes     | `useAtlasSize`, default textures |
| MasterLooterIndicator      | yes | no      | Retail runs it on Forever only |
| PhaseIndicator             | yes | no      | |
| Portrait                   | yes | yes     | state location only |
| Power                      | yes | partial | colors, `GetDisplayPower`, `PostUpdate` args |
| PrivateAuras               | yes | no      | |
| PvPClassificationIndicator | yes | no      | |
| PvPIndicator               | yes | partial | `PostUpdate` args, sub-widgets/options |
| QuestIndicator             | yes | no      | |
| RaidRoleIndicator          | yes | partial | atlas options |
| RaidTargetIndicator        | yes | yes     | |
| Range                      | yes | partial | polling and `PostUpdate` 3rd arg |
| ReadyCheckIndicator        | yes | partial | texture options |
| RestingIndicator           | yes | yes     | |
| ResurrectIndicator         | yes | yes     | default texture |
| Runes                      | yes | partial | Classic rune types (I) |
| Stagger                    | yes | partial | colors, state |
| SummonIndicator            | yes | no      | |
| Tags                       | yes | partial | env and tag set |
| TargetIndicator            | yes | no      | Tainted loads `libs/oUF_TargetIndicator` on classic (`Tainted.toc:30`) |
| ThreatIndicator            | yes | yes     | color application only |
| Totems                     | yes | partial | display internals; callback identical |

### Core

| Piece | oUF | oUF_Classic | Change in oUF_Classic |
|:------|:----|:------------|:----------------------|
| Frame unit fields (`events.lua:UpdateUnits`) | `__unit`, `__realUnit`, `__unitIndex` (number) | `unit`, `realUnit`, `id` (string) | D. Rename; keep `unit` as an alias only if layouts read it |
| Element pause (`ouf.lua`) | `PauseElement`, `ResumeElement`, `IsElementPaused`, `PauseAllElements`, `ResumeAllElements` | no | D. Port; used by Retail arena prep and widget-only nameplates |
| `DisableElement(name, unit)` / element `Disable(self, unit)` | unit passed | `Disable(self)` | D. Pass `unit or self.unit` |
| Element update list | private `objectElementUpdateFuncs`; `Private.insertObjectElementUpdateFunc` | `frame.__elements` | D. Internal |
| `oUF:AddMetaElement` (`ouf.lua`) | yes (registers `frame:Create<Name>`) | no | D. Port (needed by an Auras mirror) |
| `oUF:GetUnitFrame(unit)` | yes | no | D. Port |
| `frame:IsEventless()` (`units.lua`) | meta function | `frame.__eventless` field | D. Port |
| Ping | `PingableUnitFrameTemplate`, `SetRolesets` | `ping-receiver` attribute | `SetRolesets` absent from Classic docs: impossible |
| Parent of spawned frames | `UIParent` | `PetBattleFrameHider` (`[petbattle]` driver) | none needed |
| `oUF.Enum.SelectionType` (`enums.lua`) | yes | no | D. Port (data only) |
| `Private.unitSelectionType` / `colors.selection` | type index → `colors.selection[i]` | `Private.UnitSelectionColor` → color object; `colors.selection` keyed 0–13 | `UnitSelectionType` absent from Classic docs and Blizzard Classic code: impossible (I) |
| `Private.unitIsUnit`, `xpcall`, `GameVersion`, `GameCompatibility` | yes | `UnitIsUnit`; `oUF.isClassic/isTBC/isWrath/isCata/isMoP` (`init.lua`) | D. `unitIsUnit` needs `C_Secrets.CanCompareUnitTokens` (in Classic docs, unverified) |
| `Private.error` | `nierror` (error handler) | prints | D. Trivial |
| `oUF:CreateColor` (`colors.lua`) | ColorMixin + `SetAtlas` (validated) / `SetCurve` / `GetCurve`, default curve | ColorMixin + indexed `[1..3]`, `hex`, `SetAtlas`/`GetAtlas`, `GenerateHexColor` | D. Add `SetCurve`/`GetCurve` (`C_CurveUtil` in Classic docs) |
| `colors.smooth`, `oUF:ColorGradient`, `RGB/HCYColorGradient`, `frame:ColorGradient` | no | yes | D. Retail uses curves; keep until callers move |
| `colors.dispel` | from `AuraUtil.GetDebuffDisplayInfoTable`, `Enrage` | `DebuffTypeColor` or the same table, plus `Stealable`, `Bleed`, `Enrage`, `none`, `''` | I. Compatible |
| `colors.happiness`, `colors.power.ICICLES/TIP_OF_THE_SPEAR` | yes | no | Add `happiness` with the element |
| `colors.runes[4]` (death) | no | yes | I |
| RegisterCombatEvent (`combatevents.lua`) | no | yes | No user in libs or Tainted |
| `blizzard.lua:DisableBlizzard` | `SetRolesets('alwaysBlocked')`, Forever PvP sound | reparent to hidden frame; `oUF:DisableNamePlate` | Client UI differs: keep |
| Nameplate driver (`ouf.lua`) | pauses widget-only/game-object plates, hit-test points | `DisableNamePlate`, reparents WidgetContainer to unitFrame | Port pause handling after core pause |
| `units.lua` arena prep | pause/resume | hides listed elements; guarded by `GetArenaOpponentSpec` | `GetArenaOpponentSpec` absent from Classic docs |

## 2. Client support

R = Retail 120105, F = Forever 16001, E/T/W/M = Era/TBC/WotLK/MoP. Files load per `oUF.toc`; the
element files carry no XML tags.

| Element | R F | E T W M | Evidence |
|:--------|:----|:--------|:---------|
| AdditionalPower | yes | W M only | `oUF_Classic/private.lua` (`ALT_POWER_BAR_PAIR_DISPLAY_INFO`: WotLK/MoP druid, MoP Mistweaver) |
| AlternativePower | yes | all, unverified in use | `GetUnitPowerBarInfo` in all docs; Tainted enables it only on mainline/MoP (`modules/unitframes/elements/power.lua:137`) |
| Auras | yes | all | Retail needs `AuraContainer`/`CustomAuraContainerTemplate` (`Blizzard_AuraContainer`, absent on Classic) |
| Castbar | yes | all | empower code paths dormant on Classic |
| ClassPower | yes | combo points all; MoP class powers | `oUF_Classic/elements/classpower.lua` `oUF.isMoP` branches |
| Happiness | F | not in Classic oUF | Retail gates `GameVersion.Forever` (`happiness.lua:95`); `C_PetInfo.GetPetHappiness` only in Forever docs; Classic `GetPetHappiness` at `wow-ui-source/worktrees/classic_era/.../Blizzard_UnitFrame/Classic/PetFrame.lua:169` |
| MasterLooterIndicator | F | not in Classic oUF | `masterlooterindicator.lua:103` gates Forever; `C_PartyInfo.GetLootMethod` in all docs |
| QuestIndicator | yes | — | `UnitIsQuestBoss` absent from Classic docs |
| Runes | yes (DK) | W M | file returns unless DEATHKNIGHT; `GetRuneType` used by Classic `RuneFrame_Shared.lua` |
| Stagger | yes (Monk) | M | file returns unless MONK |
| Totems | yes | all | Era: `TotemFrame` guarded (`7377f7c`) |
| PvPIndicator honor badge | yes | unverified | `UnitHonorLevel`, `C_PvP.GetHonorRewardInfo` absent from Classic docs; Classic element calls them unguarded |
| All other shared elements | yes | all | no client checks in the element; APIs in all docs |

## 3. API per element

Common to every element: `frame.__unit` vs `frame.unit` (core rename). Rows below list only other
differences. "→" is the change needed in `oUF_Classic`.

**Identical apart from `__unit`:** RaidTargetIndicator, RestingIndicator (Retail `Private.unitIsUnit`),
ThreatIndicator (`PostUpdate(unit, status, color)` both; Retail `color:GetRGB()`), CombatIndicator and
ResurrectIndicator (default atlas vs texture only), AssistantIndicator and LeaderIndicator (secret
guards; Leader `useAtlasSize`), Portrait (`STATE` vs `element.guid/state`).

### Health (`elements/health.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Value source | `element.values` (calculator) always; `UnitGetDetailedHealPrediction` → `GetCurrentHealth`/`GetMaximumHealth` | `UnitHealth`/`UnitHealthMax`; calculator only with prediction sub-widgets (I, `5330b4c`) | D. Use calculator always (APIs in Classic docs; unverified) |
| `.smoothing` | `SetValue(v, smoothing)` | no | D. Add (`Enum.StatusBarInterpolation`, unverified) |
| `.colorSmooth` | `colors.health:GetCurve()` → `values:EvaluateCurrentHealthPercent` | `ColorGradient(cur, max, smoothGradient or colors.smooth)` | D. Needs `CreateColor` curve |
| `.smoothGradient`, `.bg`/`.multiplier` | no | yes | D. Remove after Tainted stops using them (`modules/unitframes/elements/health.lua` comments out `bg`) |
| `.colorHappiness` | Forever pet | no | Add with Happiness (Era/TBC/WotLK) |
| `.colorSelection` | `colors.selection[unitSelectionType]` | `UnitSelectionColor` object | impossible: no `UnitSelectionType` on Classic |
| class color | `C_ClassColor.GetClassColor` when class is secret | `colors.class[class]` | none (no secrets) |
| Setters | `SetColorSelection/Tapping/Reaction/Threat` | `SetColorDisconnected/Selection/Tapping/Threat` | D. Add `SetColorReaction`, drop `SetColorDisconnected` |
| Events | `UNIT_CONNECTION`→Path; `PARTY_MEMBER_ENABLE/DISABLE` for party/raid; `UNIT_FACTION` for tapping or reaction; `UNIT_MAX_HEALTH_MODIFIERS_CHANGED` only with `TempLoss` | `UNIT_CONNECTION`→ColorPath only if `colorDisconnected`; `UNIT_FACTION` only tapping; `UNIT_MAX_HEALTH_MODIFIERS_CHANGED` always | D. Match Retail |
| `TempLoss` | `GetUnitTotalModifiedMaxHealthPercent` | same, guarded + `Clamp` | none |
| Callbacks | `PreUpdate(unit)`, `PostUpdate(unit, cur, max, lossPerc)`, `PostUpdateColor(unit, color)`, `UpdateColor`, `Override`, `UpdatePredictionSize` | same (I, `a997e7f`) | identical |
| Enable | `Enable(self, unit)` | `Enable(self)` | D |

### Power (`elements/power.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| `GetDisplayPower` override | `(element, unit)` | `(element)`, reads `__owner.unit` | D. Add `unit` arg |
| `PostUpdate` | `(unit, cur, min, max, displayType)` | `(unit, cur, min, max)` | D. Append `displayType` |
| `.displayAltPowerOnly` | yes | no | D. Port |
| `.colorPowerSmooth` (curve via `UnitPowerPercent`) | yes | no; `.colorSmooth` + `smoothGradient` | D. Port with curves |
| `GetAlternativeColor` | no | yes | Classic-only hook (base) |
| `.colorPowerAtlas` | `color:GetAtlas()`, restores `STATE.texture` | `color.atlas`, `element.__texture` | trivial |
| `PostUpdateColor` | `(unit, color, r, g, b)` | same | identical |
| Setters/events | `SetColorReaction`; `UNIT_CONNECTION`/`PARTY_MEMBER_*`→Path | `SetColorDisconnected`; →ColorPath when `colorDisconnected` | D. Match Retail |
| Prediction | `CostPrediction`, `OverridePrediction` | same (I) | identical |

### AdditionalPower / AlternativePower / Stagger

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| AdditionalPower colors | `colorPower` (+`colorPowerSmooth` curve) | `colorPower`, `colorClass`, `colorSmooth` + `bg` | D. Add `colorPowerSmooth`; drop extras when unused |
| AdditionalPower pairs | `_G.ALT_POWER_BAR_PAIR_DISPLAY_INFO` | `Private.GetAltPowerBarDisplayInfo()`; MoP Mistweaver via `PLAYER_SPECIALIZATION_CHANGED` | impossible: global absent on Classic (I) |
| AlternativePower colors | `colorPower` (+curve) | threat/power/class/classNPC/selection/reaction/smooth | Classic superset (base); keep or trim |
| Stagger | `STATE.cur/max`, `.smoothing`; Enable returns false for non-monks | `element.cur/max`, `.bg`; file returns for non-monks (element never registered) | D. Register always, gate in Enable |
| Callbacks | `PostUpdate(cur, max)` / `(unit, cur, min, max)`; `PostUpdateColor(color)` / `(unit, color)` | same (I, `a997e7f`) | identical |

### ClassPower (`elements/classpower.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| `PreUpdate` | `(unit)` | `()` | D. Pass `unit` |
| `PostUpdate` | `(cur, max, hasCurChanged, hasMaxChanged, powerType, ...chargedPoints)` | `(cur, max, hasCurChanged, hasMaxChanged, powerType)` | `GetUnitChargedPowerPoints` absent from Classic docs: nothing to append |
| `UpdateColor` override | `ClassPower.UpdateColor(self, event, unit)` + `SPELLS_CHANGED` ColorPath | `element:UpdateColor(powerType)` | D. Retail signature |
| `PostUpdateColor` | `(color)` | `(color)` + sets `.bg` | identical args |
| Bar visibility | `SetShown(i <= max)` on max change | shows only `i <= cur` | D. Retail behavior |
| Power source | `GetPower/GetPowerMax/GetPowerColor` per class; `UNIT_AURA` powers | `UnitPower`; combo points via `GetComboPoints(unit, 'target')` | keep Classic source (MoP target combo points) |
| Events | `PLAYER_LEVEL_UP`, `TRAIT_CONFIG_UPDATED`, `UNIT_POWER_POINT_CHARGE` | `PLAYER_TALENT_UPDATE`, `PLAYER_TARGET_CHANGED`, `COMBO_TARGET_CHANGED` | client events; keep |

### Runes (`elements/runes.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Color | spec color, `PostUpdateColor(color)` | with `GetRuneType`: per-rune color, `PostUpdateColor(color, rune)`, `RUNE_TYPE_UPDATE`; else as Retail + `.bg` | I. Extra arg is backward compatible |
| Order | `sortOrder` | fixed Blizzard order with rune types | I |
| `PostUpdate(runemap)` | yes | yes | identical |

### Castbar (`elements/castbar.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Progress | `SetTimerDuration(UnitCastingDuration/UnitChannelDuration/UnitEmpoweredChannelDuration, smoothing, direction)` | `OnUpdate`, `SetMinMaxValues`/`SetValue`, `element.duration/max` | D. APIs in Classic docs (unverified) |
| State | private `STATE[element]` | public `castID`, `casting`, `channeling`, `empowering`, `notInterruptible`, `spellID`, `numStages`, `curStage`, `stagePoints`, `holdTime`, `delay` | D. Hide state as Retail |
| Cast identity | castBarID (10th/11th return, last event arg) | castGUID + spellID | D. castBarID is in Classic docs |
| `.Time` | `Time.binding` (`DurationTextBinding`), `Time.formatter` | `CustomTimeText(duration)`; delay rendered into `Time` | D |
| `.Delay`, `CustomDelayText(delay, isChanneling)` | yes | no; `CustomDelayText(duration)` | D. Signature change |
| `.Shield` | `SetAlphaFromBoolean(notInterruptible)` | `SetShown` | D |
| `.smoothing`, `.showGlobalCooldown`, `PostCastGlobal(unit, spellID, cooldownInfo, duration)` | yes | no | D. Port |
| `PostCastStart` | `(unit, spellID, notInterruptible, displayName, texture, isTradeSkill)` | same | identical |
| `PostCastUpdate` | `(unit, spellID, duration, direction)` | `(unit, spellID)` | D |
| `PostCastStop` | `(unit, spellID[, empowerComplete])` | `(unit, spellID)` | D |
| `PostCastInterrupted(unit, spellID, interruptedBy)` | yes | no (folded into `PostCastFail`) | D |
| `PostCastFail`, `PostCastInterruptible(unit, spellID, notInterruptible)` | yes | yes | identical |
| Pips | `UpdatePips(stages)` / `PostUpdatePips(stages)` with `UnitEmpoweredStagePercentages` | `(numStages)` | D. Empower dormant on Classic |
| `PostUpdateStage(stage)` | commented out | yes | none |
| Events | table incl. `UNIT_SPELLCAST_EMPOWER_*`, opt. `UNIT_SPELLCAST_SUCCEEDED` | 10 events, no empower | D |
| Blizzard bar | `PlayerCastingBarFrame` unregister / re-register | `CastingBarFrame_SetUnit` fallback, `OnLoad()` on disable | client UI (`CastingBarFrame_SetUnit` absent from all Blizzard sources) |

### Totems / Range / PvPIndicator / role indicators / ReadyCheck

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Totems display | `SetAlphaFromBoolean(haveTotem)`, `Cooldown:SetCooldownFromDurationObject(GetTotemDuration(slot))` | `Show/Hide`, `SetCooldown(start, duration)` | D. APIs in Classic docs |
| Totems `PostUpdate` | `(slot, haveTotem, name, icon, duration)` (duration object) | same, `GetTotemDuration(slot)` | identical |
| Range | `UnitInParty` + `UnitIsConnected`; `SetAlphaFromBoolean(inRange, in, out)`; events `UNIT_IN_RANGE_UPDATE`, `UNIT_CONNECTION`, `PARTY_MEMBER_*` | 0.2 s shared `OnUpdate` + `UNIT_IN_RANGE_UPDATE`; `checkedRange` | D. Drop polling (verify `UNIT_IN_RANGE_UPDATE` fires on Classic) |
| Range `PostUpdate` | `(self, inRange, isEligible)` | `(self, inRange, connected and checkedRange)` | D. Name/meaning |
| PvPIndicator `PostUpdate` | `(unit, status, info)` (status/info deprecated) | `(unit, status)` | D. Append `info` (nil) |
| PvPIndicator options | `.Background`, `useAtlasSize`, `*Atlas` overrides; `PLAYER_REGEN_ENABLED`, Forever `PLAYER_PVP_FLAG_CHANGED` | textures, honor badge | D. Atlas options trivial |
| GroupRoleIndicator | `UnitGroupRolesAssignedEnum`/`UnitFrameUtil`; `tankAtlas/healerAtlas/damageAtlas`; `PLAYER_ROLES_ASSIGNED` (player) | `UnitGroupRolesAssigned`, texcoords; `GROUP_ROSTER_UPDATE` | D. `UnitFrameUtil` absent on Classic; atlas options/event portable |
| RaidRoleIndicator | `mainTankAtlas/mainAssistAtlas`, `PLAYER_REGEN_ENABLED` | textures | D. Trivial; `PostUpdate(role)` identical |
| ReadyCheckIndicator | atlases, `useAtlasSize`, reuses `element.Animation` | `readyTexture/notReadyTexture/waitingTexture`, `.status` | D. Trivial |

### Tags (`elements/tags.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Tag set | `happiness` | `deficit:name` | Add `happiness` (via `GetPetHappiness`, Era/TBC/WotLK); `deficit:name` Classic-only |
| Env | `ColorMixin`, `GameVersion`, `GameCompatibility`; `Hex` → `C_ColorUtil.GenerateTextColorCode` | `ColorGradient`; `Hex` accepts tables | D |
| Methods | `UnitHealthPercent/UnitPowerPercent/UnitHealthMissing` + `C_StringUtil`; color objects (`GenerateHexColorMarkup`) | arithmetic; `Hex(table)` | D. Arithmetic is fine on Classic (no secrets) |
| Affixes | `C_StringUtil.WrapString` (secret-safe) | concatenation | none |
| Fontstring owner | `fs.__owner`, state in `STATE` | `fs.parent`, `frame.__tags` | D |
| Events | `offline`/`status` add `PARTY_MEMBER_ENABLE/DISABLE` | no | D |
| `frequentUpdates` on eventless frames | ignored (frame timer) | always timer | D |

### Auras (`elements/auras.lua`)

| Item | oUF | oUF_Classic | → |
|:-----|:----|:------------|:--|
| Shape | `frame:CreateAuras(options)` → `AuraContainer`; `:AddGroup(filter, options)`, `:AddSlot`, `:ForceUpdate` | `frame.Auras/Buffs/Debuffs` frames with options (`num`, `spacing`, `growthX/Y`, `filter`, `onlyShowPlayer`, …) | impossible natively: no `AuraContainer` widget on Classic |
| Callbacks | `CreateButton(options, button)`, `PostCreateButton(button, options)`, `PostUpdate(event)` | `CreateButton(position)`, `PostCreateButton(button)`, `PostUpdateButton(button, unit, data, position)`, `PostProcessAuraData`, `FilterAura`, `Sort*`, `SetPosition`, `PostUpdateInfo`, `PreUpdate`, `PostUpdate(unit)` | adapter only (a Lua `CreateAuras`/`AddGroup` over the Classic buttons) |

## 4. Missing elements

### In oUF, not in oUF_Classic

| Element | Does | Needs | Classic? |
|:--------|:-----|:------|:---------|
| FocusIndicator | shows when unit is focus | `PLAYER_FOCUS_CHANGED`, `UnitIsUnit` | yes: in all docs; focus exists from TBC (Era focus unverified) |
| TargetIndicator | shows when unit is target | `PLAYER_TARGET_CHANGED`, `UnitIsUnit` | yes; same API as `libs/oUF_TargetIndicator` (`PostUpdate(isTarget)`) |
| Happiness | hunter pet mood | `C_PetInfo.GetPetHappiness`, `UNIT_HAPPINESS` | yes on Era/TBC/WotLK via `GetPetHappiness` (Blizzard Classic `PetFrame.lua:169`); not MoP (no happiness, unverified in code) |
| MasterLooterIndicator | loot master icon | `C_PartyInfo.GetLootMethod`, `PARTY_LOOT_METHOD_CHANGED` | yes: both in all docs; remove the Forever gate |
| PhaseIndicator | phased unit + tooltip | `UnitPhaseReason`, `UNIT_PHASE` | likely: in all docs; `GetPhasedReasonString` not found in docs (unverified) |
| PvPClassificationIndicator | BG role/flag carrier | `UnitPvpClassification`, `UNIT_CLASSIFICATION_CHANGED` | in all docs; Classic BG content unverified |
| QuestIndicator | quest boss | `UnitIsQuestBoss` | no: absent from Classic docs and code |
| SummonIndicator | pending summon | `C_IncomingSummon.IncomingSummonStatus`, `INCOMING_SUMMON_CHANGED` | yes: in all docs (unverified in-game) |
| PrivateAuras | private aura anchors | `C_UnitAuras.AddPrivateAuraAnchor/RemovePrivateAuraAnchor` | in all docs; `Blizzard_PrivateAurasUI` ships on Classic; no Classic content known (unverified) |

### In oUF_Classic, not in oUF

| Element / piece | Why | Retail equivalent |
|:----------------|:----|:------------------|
| none (elements) | — | — |
| `combatevents.lua` (`RegisterCombatEvent`) | base leftover; unused | none |
| `oUF:ColorGradient`, `colors.smooth`, `smoothGradient` | base gradient coloring | `CreateColor():SetCurve`, `colors.health:GetCurve()`, `.colorPowerSmooth` |
| `.bg` + `.multiplier` on bars | base background tint | none (layout's job; `PostUpdateColor`) |
| `oUF:DisableNamePlate` | hide pooled Blizzard plates (I) | `SetRolesets('alwaysBlocked')` in `DisableBlizzard` |
| `oUF.isClassic/isTBC/isWrath/isCata/isMoP` | client flags | `Private.GameVersion` (private) |

## 5. Summary (cheapest first)

1. **Identical** — RaidTargetIndicator, RestingIndicator, ThreatIndicator, CombatIndicator,
   ResurrectIndicator, Portrait, AssistantIndicator; callbacks already mirrored in Health
   (`PostUpdate`, `PostUpdateColor`), Stagger, AlternativePower, AdditionalPower, Runes, Totems
   `PostUpdate`, ClassPower `PostUpdate`/`PostUpdateColor`, Castbar `PostCastStart/Fail/Interruptible`.
2. **Trivial rename/argument** —
   - Core `unit/realUnit/id` → `__unit/__realUnit/__unitIndex`; `Disable(self, unit)`.
     Tainted: drop the dual writes in `modules/unitframes/core.lua:RunTest` (450–457) and the fallback in
     `modules/unitframes/elements/auras.lua:17`.
   - Power `PostUpdate(..., displayType)`, `GetDisplayPower(unit)`; ClassPower `PreUpdate(unit)` and
     `UpdateColor(self, event, unit)`; PvPIndicator `PostUpdate(unit, status, info)`; Range 3rd arg;
     Castbar `PostCastUpdate/PostCastStop` args, `PostCastInterrupted`.
   - Health/Power `SetColorReaction` and Retail event set; atlas options on Leader/GroupRole/RaidRole/
     ReadyCheck/PvP; Tags `happiness`, `PARTY_MEMBER_*`.
   - Port `TargetIndicator`, `FocusIndicator`, `MasterLooterIndicator`, `SummonIndicator`,
     `PhaseIndicator` (APIs in Classic docs). Tainted: `TargetIndicator` could drop
     `libs/oUF_TargetIndicator` (`Tainted.toc:30`); the `not E.isMainline` gates in
     `modules/unitframes/elements/indicators.lua` (Phase 69, Summon 230) go.
3. **Needs an adapter / porting (unverified on Classic)** —
   - Color curves (`CreateColor` `SetCurve/GetCurve`, `colorSmooth` on curves, `colorPowerSmooth`) and
     the Health calculator as value source. Tainted: the duplicated Retail `UpdateColor` in
     `modules/unitframes/units/nameplate.lua:187–237` vs the MoP `PostUpdateColor` (239–255) could
     become one path.
   - Castbar duration objects (`SetTimerDuration`, `Time.binding`, castBarID, private state). Tainted:
     `modules/unitframes/elements/castbar.lua` `CustomDelayText`/`CustomTimeText` (13–19, Classic-only)
     and `UpdateColor` (33–49, re-derives state Retail hides).
   - Totems duration-object display; Tainted already overrides it with duration objects on every client
     (`modules/unitframes/elements/totems.lua:45–70`).
   - Element pause/resume, `IsEventless`, `GetUnitFrame`, `AddMetaElement`, `oUF.Enum`, nameplate
     widget-only pausing.
   - Range without polling; ClassPower bar visibility; Stagger/Runes registered for every class.
   - Happiness (Era/TBC/WotLK via `GetPetHappiness`, not `C_PetInfo`).
4. **Impossible** —
   - Auras as `AuraContainer` (`CreateAuras`/`AddGroup`): widget absent on Classic. Only a Lua shim
     over Classic buttons. Tainted keeps `elements/auras.lua` vs `auras_mainline.lua` and the branch in
     `modules/unitframes/units/raid.lua:72`.
   - `colorSelection` by selection type (`UnitSelectionType` absent); `SetRolesets` ping/blocking;
     `ALT_POWER_BAR_PAIR_DISPLAY_INFO`; ClassPower charged points (`GetUnitChargedPowerPoints`);
     QuestIndicator (`UnitIsQuestBoss`). Tainted keeps the QuestIndicator gate
     (`indicators.lua:138`).

## Needs in-game verification

- Duration objects, color curves, `CreateUnitHealPredictionCalculator` as Health source,
  `SetTimerDuration`, `SetAlphaFromBoolean`, `C_StringUtil` on Era/TBC/WotLK/MoP (listed in docs only).
- `UNIT_IN_RANGE_UPDATE` firing often enough on Classic to drop the 0.2 s poll.
- `UnitHonorLevel`/`C_PvP.GetHonorRewardInfo` on Classic (Classic PvPIndicator calls them unguarded).
- Focus on Era; `PvPClassification`, `PrivateAuras`, `IncomingSummon` behavior on Classic.
