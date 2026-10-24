# Retail bags: `UseContainerItem` forbidden in combat

Status: **resolved** (2026-10-23; fix: slots created while hidden out of combat, test 20). Not checked: TBC, WotLK, gold datatext Shift-click (test 9) with the fix; not covered: `/reload` or a bag size change in combat.

## 1. Summary

On Retail, right-clicking a usable item (potion, food) in Tainted's bag window during combat can fail with
`ADDON_ACTION_FORBIDDEN Tainted UseContainerItem()`. Whether it fails depends on how the window was **first opened
after `/reload`**. Once it fails, it keeps failing until the next `/reload`. Blizzard's default bags, with the same
addons loaded, work. The tainted read that causes it has not been found.

## 2. Environment & repro

- **Client:** Retail. Exact build was not captured (12.x; code read against `wow-ui-source` `live` 12.1.0).
- **Addons loaded:** Tainted, Filger, Shackled.
- **Module:** `modules/bags/bags.lua`. On Retail the window shows addon-created slots
  (`CreateFrame("ItemButton", …, bag, "ContainerFrameItemButtonTemplate")`, parent bag frame carries the bag ID via
  `SetID`). Blizzard's container frames are reparented to `E.Hider` by the `ContainerFrame_GenerateFrame` hook.
- **CVars:** the error happens with `taintLog = 0` and with `taintLog = 1`. `taintLog` **does work on Retail**
  (`/console taintLog 1` writes `Logs/taint.log`); setting it raises a Lua error in Blizzard's ZoneAbility (see §8),
  which can be dismissed. A level-11 log of the B repro is in `docs/taint.log`.

**Steps to reproduce:**

1. `/reload`.
2. Enter combat (a target dummy is enough).
3. Press `B` to open the bags. This is the first open since the reload.
4. Right-click a potion → `ADDON_ACTION_FORBIDDEN Tainted UseContainerItem()`.

Alternative repro: `/reload`, open the bags out of combat by Shift-clicking the gold datatext, enter combat, use a
potion.

## 3. Confirmed facts

Only directly observed results.

### Original report (`docs/issues/_retail_/bag.log`)

> I got this warning on Retail while in combat with raid boss and clicked `Deviate Fish` in bag
>
> `Tainted ADDON_ACTION_FORBIDDEN Tainted UseContainerItem()`

No stack trace exists: the failure only surfaces as the `ADDON_ACTION_FORBIDDEN` event.

### When it fails

| First open after `/reload`              | Then                                   | Result   |
|:----------------------------------------|:---------------------------------------|:---------|
| `B`, out of combat, left open           | enter combat, use item                 | OK       |
| `B`, out of combat, closed with `B`     | enter combat, `B`, use item            | OK       |
| `B`, in combat                          | use item                               | FORBIDDEN |
| `B`, in combat, close, `B` again        | use item (same combat)                 | FORBIDDEN |
| `B`, in combat (fails)                  | leave combat, re-enter, use item       | FORBIDDEN |
| gold datatext Shift-click, out of combat | enter combat, click backpack, use item | FORBIDDEN |
| `B`, in combat, no slot hovered        | `/click TaintedBag1Slot11 RightButton` | FORBIDDEN |
| Tainted bags disabled (Blizzard bags)   | `/reload`, combat, open, use potion    | OK       |
| `B`, in combat, Blizzard bags visible (test 12) | use item in Blizzard's bag     | OK       |

- Out of combat, using items never errors.
- Once in the failing state, it persists across leaving and re-entering combat, until `/reload`.
- The mouse is not involved: a secure `/click` (no OnEnter, no tooltip, button never hovered since reload) fails the
  same way (test 11). The click handler itself runs tainted.
- The error often fires 2–4 times per test (one or more clicks).
- The failing state is specific to Tainted's buttons: in the same failing combat, Blizzard's own container button
  uses the item through the same `ContainerFrameItemButton_OnClick` (test 12).

### `issecurevariable` at the moment of the error

A temporary handler (local, not committed) on `ADDON_ACTION_FORBIDDEN`/`ADDON_ACTION_BLOCKED` printed security of
values the click reads. Representative output (first open with `B` in combat):

```
Tainted ADDON_ACTION_FORBIDDEN Tainted UseContainerItem()
Tainted focus TaintedBag1Slot11
Tainted button.OnClick secure
Tainted button.OnModifiedClick secure
Tainted button.GetBagID secure
Tainted button.bagID secure
Tainted insecure button:GetParent().numSlots Tainted
Tainted insecure button:GetParent().slots Tainted
Tainted insecure button:GetParent().dirty Tainted
Tainted insecure _G.GameTooltipTextRight7 Tainted
Tainted insecure _G.GameTooltipTextLeft7 Tainted
Tainted insecure _G.SLASH_RELOADUI1 Tainted
Tainted insecure _G.ClickCastFrames Tainted
Tainted insecure _G.ZoneMap Tainted
Tainted insecure _G.SLASH_TAINTED1 Tainted
Tainted insecure _G.LibDispel Tainted
Tainted insecure _G.CUF_PROFILE_ACTIVATE_PATCH_VERSION Tainted
Tainted insecure _G.LibStub Tainted
Tainted insecure _G.GetMinimapShape Tainted
(… Filger*/SLASH_FILGER1 tainted by Filger, SLASH_SHACKLED1 by Shackled …)
Tainted scan done, 37 insecure
Tainted ADDON_ACTION_FORBIDDEN Tainted UseContainerItem()
```

In the `/click` run (test 11, nothing hovered) the scan found 26 insecure, all addon globals (`Filger*`,
`SLASH_*`, `ClickCastFrames`, `ZoneMap`, `LibDispel`, `LibStub`, `CUF_PROFILE_ACTIVATE_PATCH_VERSION`,
`GetMinimapShape`); no `GameTooltipText*`. The tainted tooltip lines above come from hovering and are not the cause.

The gold-datatext repro additionally showed Blizzard's reagent container children tainted, and many more tooltip
lines:

```
Tainted insecure _G.ContainerFrame6Cooldown Tainted
Tainted insecure _G.ContainerFrame6IconQuestTexture Tainted
Tainted insecure _G.ContainerFrame6NormalTexture Tainted
Tainted insecure _G.ContainerFrame6Count Tainted
Tainted insecure _G.ContainerFrame6IconTexture Tainted
Tainted insecure _G.ContainerFrame6SearchOverlay Tainted
Tainted insecure _G.ContainerFrame6Stock Tainted
```

A full scan of the button (capped at 60 lines) showed the `ItemButtonMixin` keys tainted (`SetItem`, `SetAlpha`,
`PostOnShow`, `PostOnHide`, `PostOnEvent`, `UpdateItemContextMatching`, `GetItemLocationCallback`, `UpdateTooltip`,
`GetDebugReportInfo`, …) and Tainted's own writes (`hasItem`, `readable`, `Backdrop`, `Cooldown`, `IconQuestTexture`).

Scanned and **secure** in every failing run: all fields of `MerchantFrame`, `BankFrame`, `BankFrame.BankPanel`,
`StackSplitFrame`, `ItemLocation`, and every non-`Tainted*` global except those listed above.

### `taint.log`

**Level 1** (B repro, mouse right-click, scanner on; that log was overwritten by the level-11 one): the block entry
showed the click path (`ContainerFrame.lua:1442` ← `:1502`) with nothing from Tainted on it, and no tainted read on the
click path. Every other entry came from the scanner.

**Level 11** (`docs/taint.log`, 237 MB; B repro, `/click TaintedBag1Slot11 RightButton`, scanner off):

```
An action was blocked because of taint from Tainted - UseContainerItem()
    UseContainerItem()
    Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua:1442 ContainerFrameItemButton_OnClick()
    Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua:1502
    TaintedBag1Slot11:Click()
    Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua:739 ?()
```

- **Execution is already tainted when the handler starts.** The first entry under `TaintedBag1Slot11:Click()` is
  `ContainerFrame.lua:1386` reading `SetBagAndSlot` from the `ItemLocation` that line has just created. Its fields are
  tainted only because the click's execution already was. Nothing is logged for the code before it
  (`ContainerFrameItemButtonMixin:OnClick` from line 1482: `IsModifiedClick`, `MerchantFrame:IsShown`, `GetBagID`).
  All later click-path entries are reads and writes of that same `ItemLocation`.
- Level 11 logs reads and writes only, no `SetScript`/`HookScript`, so it doesn't show what makes the handler
  tainted.
- No chat edit box entry precedes the click (Tainted only `HookScript`s `OnArrowPressed`/`OnEditFocusLost` on it).
  Mouse clicks fail the same way, so the `/click` path is not the source.
- During the first open in combat, most `modules/bags` entries come from slot creation and styling inside the
  `ContainerFrame_GenerateFrame` hook (`window:Show()` → `OnShow` → `Refresh` → `Layout` → `CreateSlot` →
  `StyleSlot`).

### Retail click path (from Blizzard source)

`Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`: template `<OnClick method="OnClick"/>` →
`ContainerFrameItemButtonMixin:OnClick` → `ContainerFrameItemButton_OnClick` → right button:
`C_Container.UseContainerItem(self:GetBagID(), self:GetID(), nil, BankFrame:GetActiveBankType(), false)`.
On `self` it only calls `GetBagID` (`self.bagID or self:GetParent():GetID()`) and the built-in `GetID`. It calls no
`ItemButtonMixin` method. The `ItemButton` intrinsic defines only `OnShow`/`OnHide`/`OnEvent` postcalls, no click
script. `UseContainerItem` is declared `SecretArguments = "AllowedWhenUntainted"`.

## 4. What we tested

| # | Change / action | Result |
|:--|:----------------|:-------|
| 1 | Dungeon, bags already open before combat: Algari Healing Potion, Umbral Essentia, Deviate Fish | No error |
| 2 | Dummy: enter combat, open bags, click potion | FORBIDDEN; `button.UpdateTooltip`, `button.hasItem` tainted |
| 3 | A1: `/reload`, `B` open out of combat, keep open, combat, use | No error |
| 4 | A2: `/reload`, `B` open + close out of combat, combat, `B`, use | No error |
| 5 | B: `/reload`, combat, `B` (first open), use | FORBIDDEN |
| 6 | Code: create slots while hidden (`UpdateSize()` on `BAG_UPDATE_DELAYED`, since reverted); B repro | FORBIDDEN. `TaintedBag1Slot11` existed before first open |
| 7 | B, then close and reopen in the same combat, use | FORBIDDEN |
| 8 | B, leave combat, re-enter without reload, use | FORBIDDEN |
| 9 | `/reload`, gold datatext Shift-click (out of combat), combat, click backpack, use | FORBIDDEN; `ContainerFrame6*` tainted |
| 10 | `config/settings.lua` `bags.enabled = false` (Blizzard bags): `/reload`, combat, open, use | No error |
| 11 | B repro without hovering any slot, then `/click TaintedBag1Slot11 RightButton`; then hover + right-click | FORBIDDEN both times; no tooltip globals tainted |
| — | `/console taintLog 1`, B repro, right-click | FORBIDDEN; no tainted read logged on the click path |
| 12 | Code: `ContainerFrame_GenerateFrame` hook body skipped (Blizzard bags show beside Tainted's window, since reverted); B repro, mouse right-click and `/click` on a Tainted slot, then mouse right-click in Blizzard's bag | Tainted's slot FORBIDDEN (both ways); Blizzard's slot OK, same combat |
| 13 | `/console taintLog 11`, scanner off, B repro, `/click TaintedBag1Slot11 RightButton` (`docs/taint.log`) | FORBIDDEN; execution already tainted at handler entry |
| 14 | `/reload`, out of combat `/run CreateFrame("ItemButton", nil, UIParent, "ContainerFrameItemButtonTemplate")` before any open, `B` open + close, combat, `B`, use | No error |
| 15 | Code: toggle hooks in `MODULE:Init` skipped on Retail (since reverted); B repro, `/click TaintedBag1Slot11 RightButton`, then hover + right-click | FORBIDDEN |
| 16 | `/reload`, out of combat `/run TaintedBags:Show()` + `/run TaintedBags:Hide()` (no `B`), combat, `B`, `/click TaintedBag1Slot11 RightButton`, then hover + right-click | No error |
| 17 | `/reload`, out of combat `/run TaintedBags:Refresh()` (no `B`), combat, `B`, `/click TaintedBag1Slot11 RightButton`, then hover + right-click | No error (the potion was used; the second click got "Item not ready yet", its cooldown) |
| 18 | `/reload`, out of combat set each bag's `numSlots` + `/run TaintedBags:Layout()` (no `B`), combat, `B` (runs only `UpdateSlot`), `/click TaintedBag1Slot11 RightButton` | No error |
| 19 | `/reload`, out of combat `CreateSlot` for every slot from `/run` (`numSlots` left at 0, no `B`), combat, `B` (runs `Layout` with existing buttons + `UpdateSlot`), `/click TaintedBag1Slot11 RightButton` | No error |
| 20 | Fix: `UpdateSize()` on `BAG_UPDATE_DELAYED` while hidden out of combat; `/reload`, combat, `B` (first open), `/click` on a potion slot, then hover + right-click | No error |
| 20b | Fix on MoP and Era: bags and bank open, slots and layout | Unchanged |

## 5. Ruled out

- **A tainted click-path global or Blizzard frame field.** Every scanned global and field of `MerchantFrame`,
  `BankFrame`, `BankFrame.BankPanel`, `StackSplitFrame` and `ItemLocation` was secure at the time of the error.
- **The handler resolving to a tainted method.** `OnClick`, `OnModifiedClick`, `GetBagID` are secure; `bagID` is
  unset.
- **Another addon.** Same addon set with Blizzard bags works (test 10), and the taint is attributed to Tainted.
- **A hidden `ItemButton` click script.** The intrinsic has no `OnClick`.
- **Tainted ItemButtonMixin keys alone.** They are tainted in the working runs too (tests 3–4 use the same buttons).
- **Taint entering through the mouse path (OnEnter/tooltip).** Test 11: secure `/click` on a never-hovered button fails.
- **The `ContainerFrame_GenerateFrame` hook body.** Test 12: skipped entirely, the B repro still fails.
- **The toggle hooks in `MODULE:Init`.** Test 15: skipped entirely, the B repro still fails. Neither of Tainted's
  Blizzard hooks is the source.
- **Shared click-path state.** Test 12: in the same failing combat, a Blizzard button using the same `OnClick`,
  `C_Container.UseContainerItem` and `BankFrame:GetActiveBankType()` works. Whatever is tainted belongs to Tainted's
  buttons or their parent bag frames.
- **The first `ContainerFrameItemButtonTemplate` instance built by addon code.** Test 14: an instance built from
  `/run` before any open, then the sequence that normally works, gave no error.
- **`button:UpdateTooltip()` in `UpdateSlot`.** It only runs when `GameTooltip` is owned by the button, which never
  happened in test 11, and it still failed.

## 6. Open hypotheses (unverified)

The `OnClick` handler starting tainted is confirmed (test 13). The open question is why the handler on Tainted's
buttons is attributed to Tainted after a first open in combat, when the same buttons are clean after a first open out
of combat (tests 3–4).

- **Per-button state set on the first show in combat.** Test 12 narrows the taint to Tainted's buttons or their bag
  frames. Something that runs on the window's first show (`OnShow` → `Refresh`/`UpdateSlot`, the `ItemButton`
  `PostOnShow`, `SetID` on the bag frame) may leave a value the click reads, or the button's script state, attributed
  to Tainted when it first runs in combat. Which value is not known; the scan found the read values secure. Ranked
  first now that both hooks are ruled out (tests 12, 15). Test 16: showing Tainted's window once out of combat, even
  from `/run` and without Blizzard's bags, is enough to keep it clean. Test 6 (slots created while hidden) fails, so
  what matters is the first *show* in combat, not slot creation. That show runs two things: the window's `OnShow` →
  `Refresh` (`Layout`/`UpdateSlot`), and each button's first `OnShow` scripts (Blizzard's `ItemButton` `PostOnShow`,
  `EnchantingItemButtonAnimMixin`). Test 17 rules out the buttons' `OnShow`: with `Refresh` done out of combat, the
  first show in combat is clean. The source is `Refresh` running in combat on the first show: `Layout`
  (`CreateSlot`/`StyleSlot`, `SetPoint`, `Show`) or the first `UpdateSlot` of each button. Test 6 (slots created and
  laid out while hidden, then failed) pointed at `UpdateSlot`, but test 18 rules it out: with `Layout` done out of
  combat, the first `UpdateSlot` in combat is clean. **The source is `Layout` running in combat on the first show:**
  `CreateSlot` (`CreateFrame` with `ContainerFrameItemButtonTemplate`, `SetID`, `StyleSlot`) or placing the buttons
  (`ClearAllPoints`, `SetPoint`, `Show`). Test 6 conflicts with this unless `Layout` ran again in combat there; its
  code is gone, so test 6 is not reliable for this split. Test 19 rules out placement: slots created out of combat,
  placed and filled in combat, are clean. **The source is `CreateSlot` running in combat**, i.e. creating a
  `ContainerFrameItemButtonTemplate` button (or its `SetID`/`StyleSlot`) while in combat. Why combat makes the new
  button's click handler run tainted is unknown; it's observed, not explained by the Blizzard source read so far.
- **Test 9 may be a separate path.** The gold datatext Shift-click calls `ToggleAllBags()` from Tainted code
  (`modules/datatexts/elements/gold.lua:160`), so Blizzard's container code runs tainted (fits `ContainerFrame6*`
  tainted). It fails out of combat, unlike test 16.
- **Tainted state the scan can't see.** The scan did not cover file-local upvalues in Blizzard code or `C_*`/mixin
  tables. Test 12 makes shared state on the click path unlikely; per-button state the scan missed remains possible.

## 7. Next steps (ranked)

1. ~~`taintLog 11` without the scanner.~~ Done (test 13): the handler starts tainted; the log can't say why.
2. ~~Bisect Tainted's hooks.~~ Done (tests 12, 15): neither hook is the source.
3. ~~Pre-create a template instance.~~ Done (test 14): no error, first-instance hypothesis ruled out.
4. ~~First show without Blizzard's bags.~~ Done (test 16): a first show out of combat from `/run` keeps it clean.
   Test 17: `Refresh` out of combat, first show in combat → no error.
   Test 18: `Layout` out of combat, `UpdateSlot` in combat → no error.
   Test 19: slots created out of combat, placed in combat → no error. Source: `CreateSlot` in combat.
   **Fix (test 20: no error on Retail).** `Refresh`'s size part is now `element_proto:UpdateSize()`;
   on `BAG_UPDATE_DELAYED` a hidden window calls it out of combat, so slots are created and placed before the first
   show. Filling still waits for `OnShow`. Not covered: a `/reload` in combat or a bag size change in combat still
   creates slots in combat.
5. **Retail holder approach.** Show Blizzard's own (pooled, unnamed) container item buttons inside Tainted's window,
   like Classic does (`DisableBlizzard`/`SetupHolder`/`Hold`). Blizzard's buttons are known to work (test 10). Larger
   change; only if 1–4 don't lead to a targeted fix.
6. **Disable bags for retail** (fallback only): `config/settings.lua` `bags.enabled = E.isClassic`.

## 8. Side issue: ZoneAbility error when `taintLog` is set (not bags)

`/console taintLog 1` immediately raises, from Blizzard's queued update:

```
attempt to call a nil value
[Blizzard_ZoneAbility/ZoneAbility.lua]:56: in function 'Clean'   -- frame:UpdateDisplayedZoneAbilities()
```

`frame` is `ZoneAbilityFrame`. Tainted hooks that method (`modules/actionbars/zone.lua`,
`hooksecurefunc(frame, "UpdateDisplayedZoneAbilities", …)`), so Tainted is a suspect; why `taintLog` would make the key
nil is unknown. Unverified. Checks: `/dump ZoneAbilityFrame.UpdateDisplayedZoneAbilities` after setting `taintLog`;
repeat with Tainted disabled.
