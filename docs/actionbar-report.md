# Action bars — feasibility study (rebuild-plan §4)

Sources: Tainted `modules/actionbars/*`, `core/core.lua`, `core/install.lua`, `core/init.lua`;
`wow-ui-source` live 12.1.0, forever 1.60.1, classic 5.5.4, classic_titan 3.80.2,
classic_anniversary 2.5.6, classic_era 1.15.9 (`Blizzard_ActionBar`, `Blizzard_ActionBarController`,
`Blizzard_EditMode`, `Blizzard_SettingsDefinitions_Frame`, `Blizzard_RestrictedAddOnEnvironment`,
`Blizzard_APIDocumentationGenerated`); Tukui/ElvUI for comparison only.

## 1. Summary

**Single codebase, no compat layer, no split.** All six clients now load the same
`Blizzard_ActionBar/Shared` code: `MainActionBar`, `MultiBarBottomLeft…MultiBar7`, `StanceBar`,
`PetActionBar`, `ExtraActionBarFrame`, Edit Mode bar systems and the `PROXY_SHOW_ACTIONBAR_2..8`
settings. Button names are identical everywhere. The remaining differences are a few frames that may be
missing (handled by the existing nil guards) and wrong client flags. The real work is removing the
Classic-only global overrides, moving settings writes out of Core, and dropping writes to
Blizzard-owned fields. File layout stays the same; the TOC drops the `classic` tag.

## 2. Current structure

Module `ActionBars` (`E:CreateModule`, started by `E:InitModules` at `PLAYER_LOGIN`). Loaded via
`modules/actionbars/init.xml`, TOC line tagged `[AllowLoadGameType classic]`.

| File | Role |
|:--|:--|
| `core.lua` | Module creation; `StyleActionButton(button)` (field function: icon, count, cooldown timer font, hotkey text + `UpdateHotkeys` method hook, hides Blizzard art); `MODULE:Hide(obj, events)` (hide + reparent to `E.Hider` + unregister); `DisableBlizzard()` (hides `MainMenuBar`, `MainMenuBarArtFrame`, `OverrideActionBar`, `PossessBarFrame`, `ShapeshiftBar*`, status-tracking bars; on non-`isStandard` **replaces globals** `MultiActionBar_Update` and `BeginActionBarTransition` with no-ops; parks `MicroMenu`/`BagsBar`); `ToggleMicroMenu()`, `ToggleBagsBar()`; `Init()` (`SetCVar("alwaysShowActionBars")` on Classic, `SetActionBarToggles(...)`, creates bars 1–5, 6–8 only on `isStandard`, extra/zone holders if not `isVanilla`, pet, stance). |
| `bars.lua` | `actionbar_proto` (prototype style) + `ActionBars:CreateActionBar(name, proto)`: a `SecureHandlerStateTemplate` frame under `E.PetHider`, background, `PostCreate` hook, `UpdateButtons` (styles, sizes, anchors Blizzard buttons; reparents `ActionButton`/`StanceButton`/`PetActionButton`; sets `showgrid`), visibility via `RegisterStateDriver`. |
| `bar1.lua` | Main bar: reparents `ActionButton1-12`; paging with `RegisterStateDriver(page)` + `_onstate-page` setting `actionpage` on each button; per-class bonus-bar strings (`E.isStandard`/`E.isMists`); `OnEvent` re-sets icons for slots ≥120 with `GetActionTexture` (Issue #5). |
| `bar2.lua`–`bar8.lua` | Multi-bars. Each reparents the Blizzard bar frame (`MultiBarBottomLeft`, `MultiBarBottomRight`, `MultiBarRight`, `MultiBarLeft`, `MultiBar5/6/7`) into its Tainted frame (buttons keep `useparent-actionpage`); sets `ignoreFramePositionManager`/`ignoreInLayout`; bar2 split left/right of bar1; bar3 fades out in combat; 6–8 gated by `C.actionbars.bar6/7/8`. |
| `petbar.lua` | Reparents `PetActionBar` (or `PetActionBarFrame`) and its buttons. |
| `stancebar.lua` | Styles `StanceButton1-10`; `hooksecurefunc(StanceBar, "UpdateGridLayout")` → `Update()` re-sets icon, cooldown, checked, and border color (duplicates Blizzard). Event branch keyed on `_G.StanceBarFrame`. |
| `extra.lua` | Reparents `ExtraActionBarFrame` to a holder; writes `ExtraAbilityContainer` fields; `SetParent` method hook; **global** `hooksecurefunc("ExtraActionBar_Update")` on `isStandard`. |
| `zone.lua` | Reparents `ZoneAbilityFrame`; method hooks `SetParent`, `UpdateDisplayedZoneAbilities`, `SpellButtonContainer.SetSize`. |
| `bindings.lua` | `/tainted keybindings` command: `SetBinding` set + `SaveBindings`. |

**Public API used outside the module:** `ActionBars:ToggleMicroMenu()` (datatexts `micromenu.lua`),
`ActionBars:ToggleBagsBar()` (datatexts `gold.lua`); both already treat the module as optional.
`MODULE.ActionBar1..8/PetBar/StanceBar` are only read inside the module.

**Action-bar settings outside the module (Core):**
- `core/core.lua` `E:SETTINGS_LOADED` (Retail only): `Settings.SetValue("PROXY_SHOW_ACTIONBAR_2..5", true)`.
- `core/install.lua` CVars on first install: `alwaysShowActionBars = 1`, `countdownForCooldowns = 1`.
- `core/init.lua` `E.PetHider` (`[petbattle] hide`): a shared anchor, not a setting. Stays.

**Existing bugs found (unrelated to the client):**
- `extra.lua`/`zone.lua` call `MODULE:StyleActionButton(button)` with a colon, but it's a field
  function, so `button` = `MODULE`. The extra/zone buttons are never styled, and `MODULE.__styled`
  gets set.
- `stancebar.lua`: `_G.StanceBarFrame` doesn't exist on any client, so the form-change events are
  never registered. The active-form border only updates when the grid layout changes.
- `bar2.lua` `UpdateButtonPosition` calls `element:ClearAllPoints()` on the bar itself for every
  button. Harmless only because the buttons anchor to `Left`/`Right`.
- `ActionButton_ShowGrid` doesn't exist on any client (guarded, dead).
- `GetActionTexture` (bar1) is a deprecation fallback on **all** clients (`Blizzard_DeprecatedActionBar`).
  It errors with `loadDeprecationFallbacks 0`. `C_ActionBar.GetActionTexture` exists on all six.

## 3. Retail vs Classic differences

"Mainline" = Retail + Forever; "Classic" = Era, TBC, WotLK (Titan), MoP. Verified in each worktree
unless marked.

| Area | Mainline (Retail 12.1, Forever 1.60) | Classic (Era/TBC/WotLK/MoP) | Impact on Tainted |
|:--|:--|:--|:--|
| Main bar frame | `MainActionBar` (Edit Mode system) | `MainActionBar` **and** `MainMenuBar`/`MainMenuBarArtFrame` (art/end caps, shown by `Classic/MainActionBarOverrides.lua`) | Same main bar on both. Classic only has extra art frames to hide (`Hide` already nil-safe). `MainActionBar` is never hidden today on any client. |
| Button names | `ActionButton`, `MultiBarBottomLeftButton`, …, `MultiBar5-7Button`, `StanceButton`, `PetActionButton`, `PossessButton` | identical (same `Shared/ActionBar.lua`) | Shared. |
| Button templates | `ActionBarButtonTemplate` (Mainline xml) | `ActionBarButtonTemplate` (Classic xml) | Art regions differ (`SlotArt`, `IconMask`, …). `StyleActionButton` already checks each field. |
| Multi-bars 6–8 | exist, `PROXY_SHOW_ACTIONBAR_6..8` | exist in the shared XML and Era settings | Gate on `E.isStandard` is wrong: it excludes Forever. Action slots 145–180 on Classic are unverified. |
| Multi-bar visibility | `MultiActionBar_Update` → `IsMultibarVisible` → `Settings.GetValue(PROXY_…)` → `GetActionBarToggles`; hides all multi-bars unless `MainActionBar:IsShown()` | same code | Classic no-op override only needed because the main frame was hidden. Now it's enough to never `Hide()` `MainActionBar`. |
| Paging/bonus bars | `ActionBarController` sets `actionpage` on `MainActionBar`; restricted env has `HasVehicleActionBar`, `GetOverrideBarIndex`, … | same controller and restricted env | Tainted's own state driver works on both. Per-class strings are game content (`isStandard`/`isMists`). Forever takes the non-Standard path (unverified if correct). |
| Override/vehicle | `OverrideActionBar` + `BeginActionBarTransition` | same | Classic no-op of `BeginActionBarTransition` isn't needed if `OverrideActionBar` stays parented to `E.Hider`. |
| Possess | `PossessActionBar` | same (`PossessBarFrame` gone everywhere) | `PossessBarFrame` / `ShapeshiftBar*` entries are dead on every client. |
| Stance | `StanceBar` (`UpdateState` sets icon/cooldown/checked) | same `Shared/StanceBar.lua` | Shared. `StanceBarFrame` gone everywhere. |
| Pet | `PetActionBar` | same | `PetActionBarFrame` fallback is dead. |
| Extra action | `ExtraActionBarFrame` inside `ExtraAbilityContainer` (BottomManagedFrame + Edit Mode system) | same files loaded | Shared. The `not E.isVanilla` gate is game content. |
| Zone ability | `ZoneAbilityFrame` | absent | Existing `if not frame then return`. |
| Totem bar | — (Forever XML has it; load unverified) | `MultiCastActionBarFrame` on Wrath only | Not handled today; out of scope. |
| Edit Mode | full, user-editable layouts | `Blizzard_EditMode` also loaded, bars are `EditModeActionBarTemplate` | Edit Mode behavior is the same family-wide. Preset layouts differ (unverified per client). |
| `alwaysShowActionBars` CVar | no Lua reference in Blizzard source | no Lua reference | Obsolete: `GetCVar` returns `nil` in-game (replaced by Edit Mode "Always show buttons"). |
| `SetActionBarToggles` / `GetActionBarToggles` | undocumented, used by Blizzard settings | same | Exists on all (used by `Blizzard_SettingsDefinitions_Frame` in every worktree). Protection status unverified. |
| `GetShapeshiftFormInfo/Cooldown` | undocumented, used by Blizzard `StanceBar` | same | Secret status on Retail unverified (not in generated docs). |
| `C_ActionBar.GetActionCooldown` | `SecretWhenCooldownsRestricted` | not secret | Tainted never reads action cooldowns; Blizzard renders them. |
| Cooldown countdown text | `Cooldown:GetCountdownFontString()` documented | documented | `E.API.GetCooldownTimer` (region scan) can return nil if the font string isn't created yet. Unverified. |

## 4. Taint risks (Retail touchpoints)

| # | Touchpoint | Risk | Mitigation (no global overrides) |
|:--|:--|:--|:--|
| 1 | `core.lua E:SETTINGS_LOADED` → `Settings.SetValue("PROXY_SHOW_ACTIONBAR_n")` | Runs Blizzard's proxy `SetValue` from addon code. It writes the local `ActionBarSettingsTogglesCache` and fires `MultiActionBar_Update`, `StatusTrackingBarManager:UpdateBarTicks` and `EventRegistry` callbacks, all in tainted execution. `MultiActionBar_Update` also writes `VIEWABLE_ACTION_BAR_PAGES`, which `ActionBar_PageUp/Down` later read. | Remove from Core. In the module's `Init` (out of combat, `PLAYER_LOGIN`), call `SetActionBarToggles` once per login, built from `GetActionBarToggles()` (as Blizzard's settings panel does). No change detection: Blizzard notes `GetActionBarToggles` can be stale before the server mirrors it (done in step 2). Blizzard's own `SETTINGS_LOADED` handler then calls `MultiActionBar_Update` securely. Whether login order makes this enough is unverified (see §7). |
| 2 | Reparenting Edit Mode systems (`MultiBar*`, `StanceBar`, `PetActionBar`, `MainActionBar`) | `SetParent` on protected frames is blocked in combat. Edit Mode later runs `ClearAllPoints/SetPoint/SetScale` on them from secure code. Tainted doesn't hook those, so no taint is added. | Keep doing it only in `Init` (login, out of combat). Never hook Edit Mode methods. Buttons anchor to Tainted frames, so Blizzard re-anchoring the (invisible) bar frame doesn't matter. |
| 3 | Field writes on Blizzard frames: `ignoreFramePositionManager`, `ignoreInLayout`, `ExtraAbilityContainer.spacing`, `SetFixedSize` | Tainted keys read by secure code (`ManagedFrameSystem`, `LayoutFrame:Layout`, `HorizontalLayoutFrame`). `ExtraAbilityContainer` is a bottom-managed frame laid out when an extra ability appears, often in combat. This is the most likely source of `ADDON_ACTION_BLOCKED`. | Drop the writes on bars (they aren't managed frames, and their new parent isn't a layout frame, so the writes do nothing). For extra/zone, keep only `SetParent` to the holder plus the `SetParent` **method** hooks (same pattern as ElvUI). Don't touch `ExtraAbilityContainer` fields. |
| 4 | `MODULE:Hide(MainActionBar)` (needed on Retail, currently missing) | `Hide()` makes `IsNormalActionBarState()` false, so `MultiActionBar_Update` hides every multi-bar. That's why Classic had the no-op override. | Reparent `MainActionBar` to `E.Hider` **without** `Hide()`/`UnregisterAllEvents` (`ValidateActionBarTransition` calls `MainActionBar:Show()` itself). This also removes the Classic overrides of `MultiActionBar_Update`/`BeginActionBarTransition`. |
| 5 | `OverrideActionBar` hidden + unregistered | `BeginActionBarTransition` still calls `Show()` and plays `slideOut`. Edit Mode reads its `IsShown()`/`xpBar` to offset Blizzard bars only. | Keep parented to `E.Hider` (hidden by parent). No override needed. Verify vehicle enter/exit doesn't leave `ActionBarBusy()` stuck. |
| 6 | Main-bar paging (`SecureHandlerStateTemplate`, `RegisterStateDriver`, `_onstate-page`, `SetFrameRef`, `Execute`) | Secure by design. The restricted env functions used exist on Retail and Era. | Keep. Remove the nested `ChildUpdate` only if unused (no children listen). |
| 7 | `button:SetAttribute("showgrid", 1)` | On Retail `showgrid` is a reason bitfield (`CVAR=1, EVENT=2, SPELLCOLLECTION=4`). Edit Mode "Always show buttons" clears bit 1 from secure code. | Done in step 3: Tainted sets its own bit (`0x100`), which Blizzard never clears, so `GetShowGrid()` stays true and `UpdateShownButtons` keeps empty slots. No hook. Before step 3 the global overrides tainted that path, so Blizzard silently skipped the clear. |
| 8 | `hooksecurefunc("ExtraActionBar_Update")` (global hook) | Not a replacement, but the task forbids global hooks unless needed. | Drop it: `StyleActionButton` already parents `button.style` to `E.Hider`, so later `SetTexture` calls can't show. |
| 9 | Method hooks: `button.UpdateHotkeys`, `StanceBar.UpdateGridLayout`, `ZoneAbilityFrame.UpdateDisplayedZoneAbilities/SetParent`, `ExtraActionBarFrame.SetParent`, `SpellButtonContainer.SetSize` | Post-hooks run after secure code, and only change Tainted-owned or cosmetic state. Calling `SetParent`/`SetSize` inside them in combat is blocked. | Keep the `InCombatLockdown()` guards. For the stance border, switch to the `StanceBar.UpdateState` method hook (exists on all clients) and stop duplicating icon/cooldown/checked updates. |
| 10 | `StyleActionButton` cosmetics (`SetTexCoord`, `SetFont`, `SetNormalTexture(0)`, hiding art) | Cosmetic writes on secure buttons are allowed out of combat. Edit Mode "Hide bar art" calls `UpdateButtonArt` and may restore art. | Out of combat at login only. Verify art stays hidden after Edit Mode exit (§7). |
| 11 | Secret values | Tainted reads no action cooldown/charges. `GetShapeshiftFormCooldown` → `CooldownFrame_Set` in `stancebar.lua` is unverified on Retail. | Removing the duplicated stance update (row 9) removes the only potentially secret read. |
| 12 | Edit Mode per-bar settings (icon size → `container:SetScale`, num icons, visibility, padding, right-bar auto-scale) | Not taint, but they affect multi-bar buttons, which stay inside Blizzard containers. | No code first; test with the default preset (§7). If it breaks, the fallback is a `hooksecurefunc` on the bar's own method (e.g. `UpdateSystemSettingIconSize`), not a global. |

## 5. Module classification

| File | Class | Notes |
|:--|:--|:--|
| `core.lua` `StyleActionButton` | shared | Already field-guarded. Fix the colon callers. |
| `core.lua` `Hide`/`DisableBlizzard` | shared | One frame list for all clients (nil-safe). Add `MainActionBar` (reparent only). Drop the global overrides, dead names and field writes. |
| `core.lua` `Init` | shared | Owns `SetActionBarToggles` (once per login, no change detection). Bars 6–8 are created on every client (decided); `C.actionbars.bar6/7/8` only enable or disable them. |
| `core.lua` `ToggleMicroMenu/BagsBar` | shared | Frames exist on all clients. |
| `bars.lua` | shared | Drop the dead `ActionButton_ShowGrid` call. |
| `bar1.lua` | shared + game-content branches | `C_ActionBar.GetActionTexture`. Class page strings stay on game flags (content, not API). |
| `bar2.lua`–`bar8.lua` | shared | Drop the `not E.isStandard` `SetShown/EnableMouse` branch (Blizzard visibility is now the same everywhere) and the field writes. |
| `petbar.lua`, `stancebar.lua` | shared | Drop the dead fallbacks. Stance uses the `UpdateState` hook. |
| `extra.lua` | shared | Drop the global hook and the container field writes. |
| `zone.lua` | shared (frame only on mainline) | Existing nil guard. |
| `bindings.lua` | shared | Unknown binding commands (e.g. `PING*` on Classic) just fail. Unverified, harmless. |

No module needs a compat wrapper or a per-client file.

## 6. Proposed layout

Unchanged:

```
modules/actionbars/
  init.xml        (same order: core, bars, bar1–8, petbar, stancebar, extra, zone, bindings)
  core.lua  bars.lua  bar1.lua … bar8.lua
  petbar.lua  stancebar.lua  extra.lua  zone.lua  bindings.lua
```

TOC: `modules\actionbars\init.xml [AllowLoadGameType classic]` → `modules\actionbars\init.xml`
(untagged). Per CLAUDE.md, enable per client only after in-game verification. If Retail lags behind,
keep the tag as `classic` and add `mainline` once verified. No `Tainted_*.toc`, no new files.

Structural changes outside the module (needed to meet "Core no longer touches action-bar settings"):
- `core/core.lua`: remove `E:SETTINGS_LOADED` and its `RegisterEvent` (it only exists for action bars).
- `core/install.lua`: delete `alwaysShowActionBars` (obsolete, §7). `countdownForCooldowns` stays:
  it is a general cooldown CVar, not an action-bar setting.
- `modules/actionbars/core.lua` `Init`: delete `SetCVar("alwaysShowActionBars", 1)`.

Suggested implementation order (each `make check` + in-game, Classic first, then Retail/Forever):
1. Bug fixes with no behavior change elsewhere: colon calls, `C_ActionBar.GetActionTexture`, bar2
   `ClearAllPoints`, dead names.
2. Settings ownership: module-side `SetActionBarToggles` once per login; remove Core
   `SETTINGS_LOADED` and the CVar.
3. `MainActionBar` reparent; remove the `MultiActionBar_Update`/`BeginActionBarTransition` overrides
   and the field writes.
4. Stance `UpdateState` hook; extra/zone cleanup (drop global hook, container fields).
5. Bars 6–8 created on all clients (no client gate); untag the TOC line; Retail/Forever verification incl. Edit Mode.

## 7. Open questions / in-game tests

- **Login order:** does `SetActionBarToggles` in `Init` (`PLAYER_LOGIN`) take effect before Blizzard's
  `SETTINGS_LOADED` `MultiActionBar_Update`? Test a fresh character on Retail with bars 2–5 off.
  Expected: they show after one `/reload` at most.
- **Overrides removed (Classic):** vehicle (WotLK/MoP), possess/mind control, override bars (MoP
  quests), druid forms, pet battle (MoP/Retail). Multi-bars hide/show correctly and Blizzard's bar
  never reappears.
- **Taint log:** `/console taintLog 1` (or `C.general.taintLog`). Enter Edit Mode, change a non-bar
  system, exit, then enter combat and trigger an extra action button (Retail world quest/encounter).
  Expect no `ADDON_ACTION_BLOCKED` for `ExtraAbilityContainer`, `MainActionBar` or `MultiBar*`.
- **Edit Mode defaults per client:** "Always show buttons", icon size and "Hide bar art" in the
  default preset. Do empty slots, size and art stay as designed after entering/exiting Edit Mode?
  Does the right-bar auto-scale (`UpdateRightActionBarPositions`) shrink bars 4/5 at low UI scale?
- **Bars 6–8 on Classic** — decided: the code must support all bars on every client, and `C.actionbars.bar6/7/8` stay `false`. Test once by setting one to `true` on Era/TBC/WotLK/MoP: do action slots 145–180 exist and does the bar work? Then set it back.
- **Forever paging** — deferred (no Forever access yet): Forever druid/rogue/warrior take the Classic page strings (`isStandard` is false). Test forms/stealth/stances paging when Forever is available.
- **`alwaysShowActionBars`** — answered: `GetCVar` returns `nil` in-game. The CVar is gone; delete both uses.
- **`countdownForCooldowns`** — answered: stays in Core install (general cooldown CVar).
- **`GetShapeshiftFormCooldown` secret on Retail:** moot if the stance duplication is removed; otherwise test in M+/PvP.
- **Cooldown text:** does `E.API.GetCooldownTimer` return a font string on first style for every
  client, or should it use `Cooldown:GetCountdownFontString()` (documented on all)?
- **Edit Mode on Classic:** do Classic players see an Edit Mode entry, and do the same per-bar settings apply?
