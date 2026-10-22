# oUF mirror plan

## Checklist

oUF_Classic branch: `refactor/retail-mirror` (pushed).

- [x] Step 1 — TargetIndicator into oUF_Classic (oUF_Classic `a5aca70`, Tainted `f24f800`)
- [x] Optional G — `libs/oUF_TargetIndicator` submodule removed (in `f24f800`)
- [x] Step 2 — Phase, Summon, PvPClassification (oUF_Classic `626da9b`, Tainted `d6a9953`)
- [x] Step 3 — Quest indicator: `indicators.lua:223` → `not UnitIsQuestBoss`
- [x] Step 4 — Raid auras: `raid.lua:72` → `self.CreateRaidAuras`
- [ ] Step 5 — AlternativePower everywhere: `power.lua:114-115, 137-139`
- [ ] Step 6 — Core `__unit/__realUnit` (oUF_Classic commit 3 + Tainted `auras.lua:17`, `core.lua:450-458`)
- [ ] Docs — `docs/compatibility.md` "oUF variants"/"Decisions" per step
- [ ] Decide whether `refactor/retail-mirror` merges into oUF_Classic `classic`

Not in this plan (gates added later by `40f721b`, `indicators.lua`): Focus `:46`, Happiness `:100`,
MasterLooter `:138`, PvP `:206` (`UnitHonorLevel` unguarded in oUF_Classic). Line numbers in the
sections below predate `40f721b`.

## Context
Planned 2026-10-19. Goal: Tainted unit-frame code identical on Retail/Forever (`libs/oUF`, read-only) and Classic
(`libs/oUF_Classic`). Retail is the reference. Remove `E.isMainline`-style branches; where a difference
stays, use a capability check; leftovers in one place. Input: `docs/ouf-comparison.md`.

**Key finding:** Tainted uses few of the drifted APIs. The client branches that actually exist in
`modules/unitframes` are few (list below). Most "needs adapter" work in the comparison (castbar duration
objects, curves, range polling, pause/resume, Auras shim) removes **no or almost no** Tainted branch.
So the plan does the cheap, branch-removing ports and leaves the big ports as "not now".

Current oUF-variant/client branches in `modules/unitframes`:

| Site | Branch | After plan |
|:--|:--|:--|
| `elements/indicators.lua:69` Phase | `not E.isMainline` | gone (port) |
| `elements/indicators.lua:95` PvPClassification | `not E.isMainline` | gone (port) |
| `elements/indicators.lua:230` Summon | `not E.isMainline` | gone (port) |
| `elements/indicators.lua:138` Quest | `not E.isMainline` | capability: `UnitIsQuestBoss` |
| `units/raid.lua:72` raid auras | `E.isMainline` | capability: `self.CreateRaidAuras` |
| `elements/power.lua:137` AlternativePower | `E.isMainline or E.isMists` | gone |
| `elements/power.lua:115` | `self.__barID or UnitPowerBarID(unit)` | `UnitPowerBarID(unit)` |
| `elements/auras.lua:17` | `owner.__unit or owner.unit` | `owner.__unit` (after core rename) |
| `core.lua:450-458` RunTest | dual `__unit`/`unit` writes | `__unit` only (after full rename) |
| `Tainted.toc:30` | `oUF_TargetIndicator [classic]` | line removed |
| `units/nameplate.lua:187/239` health color | `E.isMainline` / `E.isMists` | stays (impossible, see below) |
| `elements/stagger.lua:43`, `classes/shaman.lua:69` | `E.isMists` / `E.isStandard` | stay: game content, allowed by compatibility.md |
| `core.lua:109` raid manager | `E.isMainline` | stays: Blizzard UI, not oUF (`CompactRaidFrameManager_SetSetting` exists on all Classic too, so a capability check would change Classic behavior) |
| `elements/castbar.lua:12-19` | Classic-only `CustomDelayText/TimeText` | stays: inert on Retail, not a branch |

## 1. Classification

Only elements/pieces Tainted uses are listed with call sites; unused ones are marked "unused".

**Identical (no work):** RaidTargetIndicator, RestingIndicator, ThreatIndicator, CombatIndicator,
ResurrectIndicator, AssistantIndicator, LeaderIndicator, Portrait, Runes callbacks, Totems `PostUpdate`
(Tainted overrides Totems on every client anyway: `elements/totems.lua:45`), ClassPower
`PostUpdate`/`PostUpdateColor`, Health `PostUpdate`/`PostUpdateColor`, Stagger callbacks, Castbar
`PostCastStart/Interruptible`, Range as used (`elements/range.lua`: alphas only), Tags as used
(`tags.lua` guards `issecretvalue` already).

**Trivial change (in oUF_Classic):**
- TargetIndicator (port) → removes `Tainted.toc:30`.
- PhaseIndicator, SummonIndicator, PvPClassificationIndicator (port) → removes `indicators.lua:69/95/230`.
- Core `unit/realUnit` → `__unit/__realUnit` → removes `auras.lua:17` fallback, `core.lua:452,458`.
  Plugins (`oUF_AuraTrack`, `oUF_RaidDebuffs`, `oUF_Atonement`) already read `__unit or unit`: no change needed.
- AlternativePower: no oUF change; Tainted drops gate `power.lua:136-138` and `__barID` fallback
  (`UnitPowerBarID` is in all Classic docs).
- Unused by Tainted (no call site disappears; skip): Power `PostUpdate(displayType)`/`GetDisplayPower(unit)`,
  ClassPower `PreUpdate(unit)`/`UpdateColor`, PvPIndicator args (`player.lua:28` commented out),
  Castbar `PostCastUpdate/Stop/Interrupted` args, Health/Power `SetColorReaction`, atlas options,
  FocusIndicator, MasterLooterIndicator, Happiness, Tags `happiness`.

**Needs adapter (port, unverified on Classic) — not recommended now:**
- Health calculator + color curves (`CreateColor:SetCurve/GetCurve`, `colorSmooth`): only gain would be
  merging `nameplate.lua:187-237` with `239-255`, and that is blocked by `UnitSelectionType` anyway.
- Castbar duration objects/`Time.binding`: removes `castbar.lua:12-19` (8 inert lines). High risk.
- Range without polling, ClassPower bar visibility, Stagger/Runes registration, pause/resume,
  `IsEventless`, `GetUnitFrame`, `oUF.Enum`, nameplate widget pausing: no Tainted call site.
- Totems duration display: Tainted's `Override` stays regardless.

**Impossible:**
- Auras as `AuraContainer` / `CreateAuras` + `AddGroup` (widget absent on Classic). Tainted keeps the
  toc-tagged pair `elements/auras.lua` / `auras_mainline.lua`; `raid.lua:72` becomes a capability check.
- `colorSelection` by type (`UnitSelectionType` absent): `nameplate.lua:187` stays (oUF-variant code).
- QuestIndicator (`UnitIsQuestBoss` absent on Classic): `indicators.lua:138` → API check.
- `SetRolesets`, `ALT_POWER_BAR_PAIR_DISPLAY_INFO`, charged combo points: no Tainted call site.

## 2. oUF_TargetIndicator

- **Today:** `Tainted.toc:30` loads `libs/oUF_TargetIndicator/oUF_TargetIndicator.lua`
  `[AllowLoadGameType classic]` into Tainted's namespace (`ns.oUF`). Tainted creates it in
  `units/raid.lua:86` and `units/nameplate.lua:277`; `elements/targetindicator.lua` supplies
  `PostUpdate(isTargeted)` + `UpdateBorderColor` (also called from `threatindicator.lua:15`).
- **APIs:** `UnitIsUnit`, `PLAYER_TARGET_CHANGED` are in every client's generated docs (Era, TBC, WotLK,
  MoP, Forever, Retail). Classic has no secret flags.
- **Standalone for all clients: not possible.** Retail oUF already registers `TargetIndicator`
  (`libs/oUF/elements/targetindicator.lua`); loading the plugin there hits "Element [TargetIndicator] is
  already registered". It also reads `self.unit` (nil on Retail oUF).
- **Plugin defects** (fixed by porting): `AddElement("TargetIndicator", nil, ...)` registers no update
  function, so `UpdateAllElements` never refreshes it — a raid slot that changes unit, or a nameplate
  created for the current target, keeps a stale border until the next target change. No `ForceUpdate`.
- **Recommendation: port into oUF_Classic** as `elements/targetindicator.lua` (Retail file; `self.unit`
  until the core rename), add to `oUF.xml`. Tainted: delete `Tainted.toc:30`. `elements/targetindicator.lua`
  unchanged (same `PostUpdate` signature). Removing the `libs/oUF_TargetIndicator` submodule is a separate
  decision (§6).

## 3. Missing elements

Possible on Classic (evidence = generated docs + Blizzard Classic code):

| Element | Data source | Tainted use |
|:--|:--|:--|
| TargetIndicator | `UnitIsUnit`, `PLAYER_TARGET_CHANGED` | raid, nameplate |
| PhaseIndicator | `UnitPhaseReason`, `UNIT_PHASE`, `PartyUtil.GetPhasedReasonString`, atlas `RaidFrame-Icon-Phasing` (all used by Era `CompactUnitFrame.lua:1504`) | player |
| SummonIndicator | `C_IncomingSummon.IncomingSummonStatus`, `INCOMING_SUMMON_CHANGED`, `RaidFrame-Icon-Summon*` (Era `CompactUnitFrame.lua:1486-1532`) | player |
| PvPClassificationIndicator | `UnitPvpClassification`, `UNIT_CLASSIFICATION_CHANGED` (Era `Blizzard_NamePlateClassificationFrame.lua:109`); Classic BG content unverified | player |
| FocusIndicator, MasterLooterIndicator (`C_PartyInfo.GetLootMethod`), Happiness (`GetPetHappiness`, Era/TBC/WotLK) | possible | unused → skip |
| PrivateAuras | docs only, no Classic content | unused → skip |

Impossible: **QuestIndicator** (`UnitIsQuestBoss` absent from Classic docs and Blizzard Classic code).

| Option | Risk |
|:--|:--|
| Stub in oUF_Classic (registers, hides widget) | pretends support; diverges from Retail file; a Classic `UnitIsQuestBoss` later would be silently ignored |
| **Absent + capability check** (recommended): `if not UnitIsQuestBoss then return nil end` in `CreateQuestIndicator` | one line stays; if Blizzard adds the API to Classic, the widget is created without an element → static texture shown (only if oUF_Classic still lacks the element) |
| Adapter in Tainted | code for nothing |

Without a check, an unhandled QuestIndicator texture would show permanently on Classic plates.

## 4. Steps

**Step 1 — TargetIndicator into oUF_Classic**
- Change: oUF_Classic: add `elements/targetindicator.lua` (Retail file, `self.unit`), list in `oUF.xml`.
  Tainted: remove `Tainted.toc:30`.
- Clients: Era, TBC, WotLK, MoP (Retail/Forever: no change, `/reload` sanity).
- Test: raid frames — target a member, change target, clear target (border highlight ↔ threat ↔ normal);
  roster change while a member is targeted (border follows the unit); nameplates — target a mob, then
  move until its plate appears (highlight immediately); combat with threat colors.
- Depends on: —

**Step 2 — Phase, Summon, PvPClassification indicators**
- Change: oUF_Classic: add the three Retail element files (`self.unit`), list in `oUF.xml`.
  Tainted: drop gates `indicators.lua:69-71, 95-97, 230-232`.
- Clients: Era, TBC, WotLK, MoP.
- Test: login/`/reload` no errors; get summoned (warlock/stone) → player summon icon; BG flag/role
  (PvPClassification, unverified content); phase: element on `player` never shows on any client
  (player is never phased from itself) — only check no errors and no stray mouse-enabled frame.
- Depends on: —

**Step 3 — Quest indicator capability check**
- Change: Tainted only: `indicators.lua:138` `not E.isMainline` → `not UnitIsQuestBoss`.
- Clients: all six.
- Test: Retail/Forever quest-boss nameplate icon still shows; Classic no icon, no errors.
- Depends on: —

**Step 4 — Raid auras capability check**
- Change: Tainted only: `raid.lua:72` `E.isMainline` → `self.CreateRaidAuras` (defined only in
  `auras_mainline.lua`, toc-tagged mainline); update the comment.
- Clients: all six.
- Test: raid frames Retail/Forever (Blizzard groups), Classic (AuraTrack/Buffs + RaidDebuffs).
- Depends on: —

**Step 5 — AlternativePower everywhere**
- Change: Tainted only: remove `power.lua:136-138` gate; `power.lua:114-115` → `UnitPowerBarID(unit)`.
- Clients: all six; Era/TBC/WotLK newly create the bar.
- Test: Era/TBC/WotLK bar stays hidden outside alt-power content, no errors; MoP/Retail an alt-power
  encounter/quest shows name and %. Unverified: any WotLK Titan alt-power content.
- Depends on: —

**Step 6 — Core unit fields like Retail**
- Change: oUF_Classic: `events.lua:UpdateUnits` sets `__unit/__realUnit` (decide `id` → `__unitIndex`
  number, §6); replace `self.unit`/`frame.unit`/`realUnit` reads in core (`ouf.lua`, `units.lua`,
  `events.lua`) and all elements, incl. those ported in steps 1–2. Tainted: `auras.lua:17` →
  `owner.__unit`; `core.lua:450-458` drop the `unit` writes and the comment.
- Clients: Era, TBC, WotLK, MoP.
- Test: every unit (player, target, tot, focus, focustarget, pet, party, raid, boss, arena, nameplates);
  target change; pet summon/dismiss; WotLK/MoP vehicle enter/exit (unit ↔ realUnit swap); raid roster
  changes and group join/leave in combat; aura tooltips on Classic auras; `/tainted test`; ping on unit
  frames (`ouf.lua:314` reads `frame.unit`).
- Depends on: 1, 2 (so ported files are renamed in one pass).

**Not now (adapters, no meaningful Tainted gain):** health calculator + curves, castbar duration objects,
range polling, ClassPower visibility, pause/resume/`AddMetaElement`/Auras shim, unused elements.

**Can't be verified without the game:** everything in-game above; specifically Classic summon/phase/
PvP classification atlases rendering, `UnitPvpClassification` content in Classic BGs, stale-border fix
on raid roster changes, vehicle unit swap after the rename, Era/TBC/WotLK alt-power behavior.

## 5. Commits

oUF_Classic, on a new branch off `classic` (pushed before the pointer bump, or CI/packager can't fetch it):
1. `targetindicator: port Retail element`
2. `phase, summon, pvpclassification indicators: port Retail elements`
3. `core: __unit/__realUnit like Retail`

Tainted (each includes the `libs/oUF_Classic` pointer bump for its submodule commit):
- A (step 1): bump oUF_Classic → 1; `Tainted.toc` drop oUF_TargetIndicator.
- B (step 2): bump → 2; `indicators.lua` gates.
- C (step 3): `indicators.lua` quest check.
- D (step 4): `raid.lua` capability check.
- E (step 5): `power.lua`.
- F (step 6): bump → 3; `auras.lua`, `core.lua`.
- Optional G: remove `libs/oUF_TargetIndicator` submodule (`.gitmodules`, gitlink) — only if decided.
- Docs: `docs/compatibility.md` "oUF variants" / "Decisions" lines updated with the step that changes them.

Execution protocol: before step 1 you create the oUF_Classic branch; then one step at a time → one question if needed, wait → implement → `mise exec -- make check`
→ commit message as text → stop until "committed". No git/gh write commands.

## 6. Needs confirmation

1. oUF_Classic branch name (e.g. `mirror-retail`; created by you when implementation starts) and whether it later merges into `classic`.
2. Remove the `libs/oUF_TargetIndicator` submodule after step 1, or keep it for other users.
3. Step 6: full rename (removes RunTest dual write; touches every oUF_Classic element) vs. only setting
   `frame.__unit` alongside `frame.unit` (2 lines, removes only `auras.lua:17`) vs. skip. Recommend full rename.
   Also `id` (string) → `__unitIndex` (number)? Tainted doesn't read either.
4. Quest: absent + `UnitIsQuestBoss` check (recommended) vs stub.
5. Leave `nameplate.lua:187-255` as the one remaining oUF-variant branch (recommended) vs. moving it into
   a toc-tagged `units/nameplate_mainline.lua` pair. No separate compat file for one item.
6. Skip the adapter ports (castbar, curves, range, Auras shim) — recommended.
7. Phase indicator on `player` never shows: keep as is (behavior preserved) or move to party/raid
   (design change, out of scope unless asked).
