# Bags fixes (issue #10, branch `issues/10-bag-combat-taint`)

Status: committed (`b1281b6`). Classic done; Retail errors were unrelated (below).

## Problem
Classic (Era, TBC, WotLK, MoP): Tainted's bag slots were addon-created `ContainerFrameItemButtonTemplate`
buttons. The template's inline XML `OnClick` runs tainted, so `UseContainerItem` is blocked in combat:
items in the bags couldn't be used in combat.

## What changed
- `modules/bags/bags.lua`
  - Classic bags are *holders*: Blizzard's `ContainerFrame<N>` is parented to the Tainted window as an
    invisible frame (`SetupHolder`: regions alpha 0, non-item children to `E.Hider`, no mouse), and its
    `Item<M>` buttons become the bag's slots (`Hold`; Blizzard gives item `i` the slot `size - i + 1`).
  - Blizzard keeps the content of those buttons updated. Tainted styles them once (`StyleSlot`, split out
    of `CreateSlot`) and sets only the border (`UpdateBorder`/`UpdateBorders`, from a
    `ContainerFrame_Update` hook and on quest events).
  - Refresh, cooldowns, search and `ITEM_LOCK_CHANGED` skip holder bags.
  - `BackpackTokenFrame`/`BagItemSearchBox` reparented into a holder by Blizzard go to `E.Hider`.
  - `ToggleAllBags`/`ToggleBag` at the bank keep the bank bags open (`bank:OpenBags`); `AnyBagOpen` removed.
  - Mainline unchanged: Blizzard frames stay hidden, Tainted's own slots.
- `modules/bags/bank.lua`: Classic bank bags open/close through `OpenBag`/`CloseBag`
  (`bank_proto:OpenBags`/`CloseBags`), also after buying or placing a bag. `OpenAllBags`/`CloseAllBags`
  are read from `_G` at call time because `MODULE:Init` hooks them after the file loads.
- `docs/compatibility.md`: bags entry describes the Classic holder approach.
- `docs/limitations.md`: limitation narrowed to the Classic bank's own slots (not bank bags).
- `modules/miscellaneous/taint.lua`: prints `ADDON_ACTION_*`/`MACRO_ACTION_*` (`BLOCKED`, `FORBIDDEN`).

## Tested in-game
- Classic Era: OK
- MoP: OK
- TBC: OK

Items in bags usable in combat, also when Tainted's code opened the bags (gold datatext
`ToggleAllBags`, shift-click `OpenAllBags`, bank `OpenBag`). A one-off "Interface action failed" with a
bandage on TBC did not reproduce.

Not tested: WotLK (`classic_titan`), Forever.

## Known limitation
Classic bank container slots (the bank itself, not bank bags) are still Tainted buttons and can't be
used in combat.

## Retail: Lua errors (resolved, unrelated to bags)
Cause: `taintLog` set to non-zero on Retail (known Blizzard issue), not the bag changes. Fixed in
`22b19c4` (#13: never enable `taintLog` on Retail).

Every login and `/reload` (not only after `/tainted reset`), Tainted only enabled. Logs:
`docs/issues/_retail_/1..6.log`, `1-8.log`. All are `attempt to call a nil value`, with no file prefix and
no Tainted frame in the stack:

1. `Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua:585` `ResetChatType`: `ChatFrame1EditBox:UpdateHeader()`
2. `Blizzard_SharedXML/LayoutFrame.lua:347` `LayoutChildren` (`RightManagedFrameContainer`, child 1):
   `UIWidgetBelowMinimapContainerFrame:SetPoint()`. Reached from Durability `SetAlerts`, StanceBar,
   PetActionBar, ActionBarController and ObjectiveTracker updates.
3. `Blizzard_ZoneAbility/ZoneAbility.lua:56` `Clean`: `ZoneAbilityFrame:UpdateDisplayedZoneAbilities()`
   (count 77/86)
4. `Blizzard_BNet/Mainline/BNet.lua:46` `OnEvent` (`BN_FRIEND_ACCOUNT_ONLINE`): `BNToastFrame:AddToast()`

## Next
- [x] Retail errors: `taintLog`, fixed in `22b19c4` (#13).
- [ ] Test Forever.
- WotLK (`classic_titan`): can't be tested, no client currently available.
- [x] Taint prints moved to `modules/miscellaneous/taint.lua` (blocked/forbidden actions, gated on
  `C.general.taintLog ~= 0`); `core/development.lua` back to its empty template.
- [x] Commit (`b1281b6`): `Classic bags: show Blizzard's container item buttons so items work in combat (#10)`
