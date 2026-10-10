# Tainted rebuild plan

A living roadmap. Start a session with: "Continue with the next item in the Tainted rebuild plan."
Principles and workflow live in [CLAUDE.md](../CLAUDE.md); client facts in
[compatibility.md](compatibility.md). This file only records order, status and decisions.

Legend: **Observed** = seen in the code · **Recommended** = proposal, not yet agreed ·
**Decided** = agreed, don't re-litigate.

## 1. Current state

- Revived after a long maintenance gap. TOC, references and settings have been cleaned up.
- **Observed:** on Retail and Forever, only core, unit frames, maps (minimap/worldmap), chat and datatexts
  load, plus tooltips, auras and action bars. Bags are tagged `classic`. Blizzard and
  miscellaneous only load on Classic and MoP.
- **Observed:** working: unit frames (most mature), minimap, chat and datatexts on all clients; action bars on Classic (Retail/Forever pending verification). Classic-only,
  not verified on Retail: Blizzard tweaks. Stub/WIP:
  bags (only the bag-slot bar loads).
- Constraints: one TOC for 6 clients; Retail oUF is read-only; Midnight secret values
  (see compatibility.md).

## 2. Rebuild principles

See CLAUDE.md → Philosophy and Changing code. These are the ones specific to the rebuild:

- Rebuild one subsystem at a time, in the order below. Fix code outside the current item only
  if it blocks this item.
- Keep the existing visual design ([design.md](design.md)). Prefer targeted fixes to rewrites.
- A subsystem that others anchor to must leave named, stable anchors when it's done.
- Enable a module on a new client only after it is verified there in-game.

## 3. Rebuild order

### 0. Core contract

**Status:** Done · **Priority:** Critical · **Depends on:** —

**Objective:** settle what client flags mean and who owns startup side effects.

**Done when:**
- Flag meanings (game vs API family vs oUF variant) are documented in compatibility.md.
- Leaked or undefined globals reported by luacheck are fixed.
- Nothing else changes yet; affected call sites are fixed as each later item touches them.

### 1. Minimap

**Status:** Done, pending in-game verification · **Priority:** High · **Depends on:** 0

**Objective:** finalize the minimap as the anchor for auras, datatexts and Blizzard tweaks.

**Done when:**
- Looks the same on all 6 clients and matches design.md.
- `Minimap` and the minimap datatext strip are stable anchors.
- The strip is not an empty bar on clients without datatexts.
- No redundant updates.

**Known limitation:** on Forever, toggling `rotateMinimap` re-applies Blizzard's round mask
(`Blizzard_Minimap/Camelot/Skin.lua`) until `/reload`.

### 2. Chat

**Status:** Done · **Priority:** High · **Depends on:** 0

**Objective:** chat panels on every client. They are the anchor for the left/right datatexts.

**Done when:**
- Loads on all clients with stable panel and datatext anchors.
- The first-run reset is owned by the chat module, not core.
- Chat history is preserved.

**Observed:** Blizzard's chat code (`Blizzard_ChatFrameBase/Shared`, `ChatFrameUtil`, chat
mixins, Edit Mode-managed `ChatFrame1`) is the same on all 6 clients. Tainted's `ChatEdit_*`,
`ChatFrame_*` and `NUM_CHAT_WINDOWS` exist only via `Blizzard_DeprecatedChatInfo`
(`loadDeprecationFallbacks` CVar). One shared implementation, no per-client files.

**Decided:**
- Right chat = first undocked, non-temporary frame (ChatFrame2..max). No fixed ID, no saved state.
- `CHAT_CONFIG[3]` is the Voice window; keep it, left to Blizzard.
- Left/right datatext strips stay empty on mainline until item 3. Chat only provides the
  `TaintedChat{Left,Right}` and `…DataText` anchors; no datatext or action-bar dependency.
- Chat comes before DataTexts (3) and Action bars (4).

**Steps** (verify on Classic first, where chat loads today; `make check` after each):

1. **API migration** · Done, pending in-game verification · Depends on: —
   - Change: deprecated globals → `ChatFrameUtil.*`, frame methods, `Constants.ChatFrameConstants.MaxChatWindows` (chatframe, copy_url, history). Removed the global `ChatEdit_UpdateHeader` hook (dead; errors without fallbacks). History replay uses `ChatFrame1:MessageEventHandler` (`ChatFrame_MessageEventHandler` no longer exists on any client, so replay was silently failing).
   - Clients: Classic (Era, TBC, WotLK, MoP).
   - Test: `/reload` with `/console loadDeprecationFallbacks 0`; chat, tabs, history, URL links unchanged.
2. **Edit box header** · Done · Depends on: 1
   - Change: per-editbox `UpdateHeader` hook in `Style` (global hook already removed in step 1).
   - Clients: Classic.
   - Test: edit box border colour follows `/s`, `/p`, `/g`, `/w`, `/1`.
3. **Positioning** · Done · Depends on: 1
   - Change: one `PositionChat` for left and right frames; one `hooksecurefunc(ChatFrame1, "SetPoint")` re-anchoring via `SetPointBase` replaces the stacked hook (`ApplySystemAnchor` alone misses Classic's `UIParentManageFramePositions`, which re-anchors ChatFrame1 via `SetToLayoutAnchor`); right frame by the stateless rule.
   - Clients: Classic (code is shared; mainline verified in step 7).
   - Test: chats stay in panels after Edit Mode open/close, `/reload`, UI scale change.
4. **Temporary windows + cleanup** · Done (verified on Era) · Depends on: 3
   - Change: on `FCF_OpenTemporaryWindow`, style any unstyled `CHAT_FRAMES` (the old hook used `FCF_GetCurrentChatFrame`, the dropdown's frame, not the new window); `Tab.SetAlpha` override → `FCFTab_UpdateAlpha` hook setting tab alphas to 1; `TabText.SetFont` overrides removed (no Blizzard Lua resets tab font); removed dead code and missing-texture `E.error`. Undocked popouts are styled but not placed in a panel.
   - Clients: Classic.
   - Test: whisper window styled; tabs stay visible and in Tainted font; no error spam on login.
5. **Reset ownership** · Done (verified on Era, TBC, MoP) · Depends on: 1, 3
   - Change: reset moves from `core/core.lua` into the chat module (same `db.chat` flag, set only once the reset completes; triggered once on the first `PLAYER_ENTERING_WORLD`); configure frames returned by `FCF_OpenNewWindow`; undock only `Others`; window 3 left to Blizzard; bounded retry (10 × 1 s, then retried next login). General tab gets the server channels on every client (was Retail only, so Classic's General tab was empty); channels stay joined across `FCF_ResetChatWindows`, so no `/join`.
   - Clients: Classic.
   - Test: `/tainted reset` → tabs `G, S & W | Combat Log | All NPCs | General` left, `Others` right, channel colours.
6. **History, copy, URL** · Done · Depends on: 1
   - Change: history skips payloads with `hasanysecretvalues` (exists on all clients); copy button opens an edit box 30px above the selected chat's panel (2× panel height, own scroll bar) with its text in chat colours, links and textures stripped, secret lines skipped; Ctrl+C or Esc closes it, instead of Blizzard copy mode — `CopyToClipboard` is restricted and `SetTextCopyable` from addon code taints that path, so releasing a selection was blocked; chat-frame OnEnter/OnLeave use `HookScript` (OnMouseWheel stays `SetScript`: it replaces Blizzard's 1-line scroll, hooking would scroll both); URL click via `LinkUtil.RegisterLinkHandler("url", …)`, which `SetItemRef` runs before Blizzard's link handling (replaces `ItemRefTooltip.SetHyperlink`). Sent-message Up/Down history: native edit-box history only answers Alt+Up/Down, so Tainted keeps a session-only list (32 lines, shared by all edit boxes) fed by a post-hook on `AddHistoryLine` and walked in `OnArrowPressed`; secure commands are left to the native Alt+Up history (recalling them from addon code would be blocked); autocomplete keeps the arrows while shown.
   - Clients: Classic (secret skip only matters on mainline).
   - Test: history survives `/reload`; copy button opens the box, Ctrl+C copies, Esc or the button closes; clicking a URL fills the edit box; item/player links unchanged; Up/Down walks sent messages, Down from newest gives empty input, gone after `/reload`.
7. **Enable on all clients** · Done · Depends on: 1–6
   - Change: dropped `[AllowLoadGameType classic]` from the 4 chat TOC lines; no chat code change (APIs present on Retail and Forever; Retail only runs message filters on accessible payloads, `canaccessvalue`). With the chat panels on mainline, DataTexts creates holders 1–6, whose elements mainline doesn't load: `SetupDataText` now skips a missing element silently instead of `E:error`, so the strips stay empty until item 3. Reset (step 5) takes the General tab's channels from `GetChannelList()` (joined channels) instead of `EnumerateServerChannels()`, which on Retail misses Trade/Services and lists unjoined channels.
   - Clients: Retail, Forever (new); recheck all 6.
   - Test: everything above on Retail and Forever; whisper popout on Retail; no errors after a boss/M+ (secret chat lockdown); taint log clean after combat and chat links.

### 3. DataTexts

**Status:** Done · **Priority:** Medium · **Depends on:** 1, 2

**Objective:** bring the framework to every client, then each element one at a time.
Started by item 1: holders have fixed indexes (left 1–3, right 4–6, minimap 7–8), and mainline
loads the framework with only the minimap elements (`init_mainline.xml`).

**Done when:**
- Datatexts look up their holders explicitly.
- A missing provider (keystone, bags, action bars) disables that element without errors.

**Steps:**
1. **Element / registration / holder / capability split** · Done · Depends on: —
   - Change: `C.datatexts.elements` keeps indexes 1–8; `core.lua` declares each holder's frame, index range and tooltip anchor (tooltips no longer branch on index). Like oUF's `EnableElement`, an element is active only if `Enable` returns `true`; a missing holder or element leaves its slot empty. One untagged `init.xml` loads every element on every client; `init_mainline.xml` and the dead `template.lua` are removed.
   - Mainline fixes (checked against Retail 12.1 / Forever 1.60 API docs): MicroMenu and Gold treat ActionBars/Containers as optional; MicroMenu skips `MainMenuMicroButton_SetNormal` where undefined (Forever); Character skips `PaperDollFrame_UpdateStats` on mainline and hides the stat sections while `C_Secrets.ShouldUnitStatsBeSecret()`. Meter removed on all clients (`COMBAT_LOG_EVENT_UNFILTERED` is restricted on mainline; `C_DamageMeter` notes in `docs/wiki/c-damagemeter.md`).
   - Clients: all 6.
   - Test: classic layout and tooltips unchanged; on Retail/Forever all 8 slots work (text, tooltip, click), Character tooltip in and out of combat/instances.
2. **Debug panel** · Done · Depends on: 1
   - Change: `C.datatexts.debug` (code constant, default `false`) adds a centered panel with one row per registered element (name + live slot, sorted), so elements beyond the 8 slots can be tested; an element that can't run on the client leaves its row empty.
   - Clients: all 6.
   - Test: `debug = true` shows the panel with every element and tooltips below it; `false` shows nothing.
3. **Guild tooltip** · Done · Depends on: 1
   - Change: loops the whole roster and keeps online members (online members aren't guaranteed first); adds to the passed tooltip; names via `Ambiguate(name, "guild")`. Realm repeated in Retail names (`docs/issues/_retail_/datatext-guild.png`) is unverified: check `/dump GetGuildRosterInfo(i)`.
   - Clients: all 6.
   - Test: Retail tooltip lists all online members, own-realm names short.

### 4. Action bars

**Status:** Done, pending in-game verification on Retail/Forever · **Priority:** High · **Depends on:** 0

**Objective:** working bars on Retail, including Edit Mode, without taint.

**Done when:**
- Loads on all clients.
- Core no longer touches action-bar settings.
- No global function overrides unless proven necessary.

Feasibility study: [actionbar-report.md](actionbar-report.md).

**Observed:**
- All 6 clients load the same `Blizzard_ActionBar/Shared` code: `MainActionBar`, `MultiBar*` (incl.
  `MultiBar5-7`), `StanceBar`, `PetActionBar`, `ExtraActionBarFrame`, Edit Mode bar systems. Button
  names are identical. Classic only adds the `MainMenuBar`/`MainMenuBarArtFrame` art frames.
- `MultiActionBar_Update` hides every multi-bar while `MainActionBar:IsShown()` is false.
- `showgrid` is a bit field of show reasons; Edit Mode's "Always show buttons" (off in Blizzard's
  Classic presets) clears bit 1.
- `GetActionBarToggles` can be stale before the server mirrors it; nothing re-runs
  `MultiActionBar_Update` after an addon's `SetActionBarToggles`, so a changed `C.actionbars.bar6/7/8`
  may need one more `/reload`.

**Decided:**
- `countdownForCooldowns` stays in Core install (affects every cooldown); `alwaysShowActionBars` removed
  (`GetCVar` returns nil).
- Bars 6–8 are created on every client and disabled by `C.actionbars.bar6/7/8 = false`.
- Bar backgrounds follow their Blizzard bar: disabling a bar in game options hides its background.
- Main-bar paging keeps Blizzard behavior (warrior stances, rogue stealth, druid forms page).

**Steps** (`make check` after each; verified on TBC unless noted):

1. **Bug fixes** · Done · Depends on: —
   - Change: extra/zone buttons styled (`StyleActionButton` was called with a colon); bar 1 uses
     `C_ActionBar.*` instead of deprecation fallbacks; bar 2 no longer clears its own anchor per button;
     dead frame names and `ActionButton_ShowGrid` removed. Classic Era: `MainActionBar` reparented to
     `E.Hider` (never `Hide()`d).
2. **Settings ownership** · Done · Depends on: 1
   - Change: Core's `SETTINGS_LOADED` `Settings.SetValue("PROXY_SHOW_ACTIONBAR_n")` and the
     `alwaysShowActionBars` CVar removed; the module calls `SetActionBarToggles` once per login,
     built from `GetActionBarToggles()`.
3. **No global overrides** · Done · Depends on: 2
   - Change: Classic no-ops of `MultiActionBar_Update`/`BeginActionBarTransition` removed;
     `ignoreFramePositionManager`/`ignoreInLayout` writes on bars, pet and stance removed. Empty slots use
     a Tainted-only `showgrid` reason (`0x100`) and are shown once at login. Bar 1 no longer resets
     `actionpage` to 1 after the page state driver. Backgrounds follow their Blizzard bar (`FollowBar`).
4. **Stance and extra cleanup** · Done (extra button seen styled on MoP) · Depends on: 3
   - Change: stance border via a `StanceBar.Update` method hook reading `GetChecked()` (no duplicated
     icon/cooldown/checked updates, no shapeshift API reads); global `ExtraActionBar_Update` hook and
     `ExtraAbilityContainer` field writes removed.
5. **All clients** · Done, pending Retail/Forever verification · Depends on: 4
   - Change: bars 6–8 created on every client; bar 7/8 hold `MultiBar6`/`MultiBar7` (both held
     `MultiBar5`); `modules\actionbars\init.xml` untagged in the TOC.
   - Test (Retail/Forever): no Lua errors; Blizzard main bar gone; bars 2–5 shown on a fresh character
     (login order); Edit Mode enter/exit keeps empty slots, sizes and hidden art; taint log clean for
     `ExtraAbilityContainer`, `ZoneAbilityFrame`, `MainActionBar`, `MultiBar*` in combat; zone ability
     changing in combat (`zone.lua` re-anchors its buttons without a combat check); paging in druid forms,
     stealth, vehicle/dragonriding.

**Open:**
- Forever paging: should druid/rogue use the Classic page strings (`E.isStandard` is false)? Untested,
  no Forever access.
- Bars 6–8 on Classic: action slots 145–180 keep a spell across `/reload` (unverified).
- Zone ability exists only on mainline (`ZoneAbilityFrame` isn't defined on Classic).

### 5. Auras (player buffs/debuffs)

**Status:** Done, pending in-game verification · **Priority:** Medium · **Depends on:** 1

**Done when:** works on all clients, secret-value safe on Retail, no leaked globals.

**Observed:**
- The secure aura header exists on all clients and still sets `index`, `filter` and `target-slot`
  on its children.
- `C_UnitAuras.GetAuraDataByIndex` is `SecretWhenUnitAuraRestricted` on Retail/Forever: the player's
  own stacks, duration, expiration and dispel type are secret in combat, encounters, M+ and PvP.
- `E.colors.debuff` only exists in Classic/MoP oUF; Retail oUF has `colors.dispel`.
- `GetAuraDuration`, `GetAuraApplicationDisplayCount`, `GetAuraDispelTypeColor`, curves, duration
  objects and `C_StringUtil.TruncateWhenZero` exist on all 6 clients.
- `GetWeaponEnchantInfo` only exists on Retail/Forever as a deprecation fallback;
  `C_PaperDollInfo.GetTemporaryEnchantmentInfo` exists only there.

**Decided:**
- Secret timers show raw seconds (`TruncateWhenZero`), like unit-frame auras; non-secret timers
  keep `E.FormatTime`.

**Steps** (`make check` after each; Classic regressions checked on Era first):

1. **Secret-safe aura content** · Done (verified on Era, TBC, MoP) · Depends on: —
   - Change: unit taken from the header (vehicle); duration object from `GetAuraDuration`; stacks from
     `GetAuraApplicationDisplayCount(unit, id, 2)`; debuff border from `colors.debuff`/`colors.dispel`,
     or `GetAuraDispelTypeColor` with `E.curves.auras.dispel` when `dispelName` is secret (curve x =
     dispel type ID, unverified). The timer keeps `E.FormatTime` and white/orange/red colors when the
     remaining time isn't secret; when secret, it shows raw seconds colored by `E.curves.auras.timer`.
     Removed the unused locals.
   - Clients: Classic (code is shared).
   - Test: stacks, timers and timer colors, debuff borders, tooltips, right-click cancel, vehicle.
2. **Temporary enchants** · Done (verified on Era, TBC, MoP) · Depends on: —
   - Change: `C_PaperDollInfo.GetTemporaryEnchantmentInfo` where it exists, otherwise `GetWeaponEnchantInfo`
     with offset `(slot - 16) * 4 + 1` (the ranged slot read off-hand data before).
   - Clients: Classic (mainline enchants are handled by the container, step 3).
   - Test: weapon oil/poison/imbue on main and off hand.
3. **Mainline aura containers** · Done, pending in-game verification · Depends on: 1, 2
   - Observed: `SecureAuraHeader.lua/.xml` load only for `classic` game types (Retail 12.1, Forever 1.60);
     `CreateFrame(..., "SecureAuraHeaderTemplate")` fails on mainline (`docs/issues/_retail_/secure-head-template.log`).
     Mainline uses `Blizzard_AuraContainer` (`CustomAuraContainerTemplate`), as Retail oUF does.
   - Change: `modules/auras/auras.lua` → `classic/aura.lua` (tagged `classic`); new `mainline/aura.lua`
     (tagged `mainline`): one container per filter at the same Minimap anchors, flow layout with the
     classic header's spacing/rows/columns, sort mapped from `C.auras.sort`, weapon enchants before the buffs.
     Buttons get the same backdrop, icon, count and duration text; Blizzard fills them (secret values
     included), the duration text uses Blizzard's default seconds formatter colored by
     `E.curves.auras.timer`, debuff borders via `AddDispelTypeTexture` with `E.colors.dispel`.
     Right-click cancels. Unit is always `player` (no vehicle switch).
   - Known limitation: buttons show Blizzard's forbidden `AuraButtonTooltip` (no addon access, no
     override); only its backdrop can be set (`AuraContainerInbound.SetTooltipBackdrop`, tooltips
     module), so there is no Spell ID line.
   - Clients: Retail, Forever.
   - Test: buffs/debuffs/enchants placed and sized like Classic; stacks, timers, debuff border colors,
     tooltips, right-click cancel; hidden in pet battles; Blizzard buff/debuff frames hidden; Edit Mode
     open/close; no errors or taint in combat, dungeon, M+, boss.

### 6. Tooltips

**Status:** Done, pending in-game verification · **Priority:** Medium · **Depends on:** 0

**Done when:** works on all clients, using the tooltip data post-calls on Retail.

**Observed:**
- `TooltipDataProcessor` post-calls fire only where GameTooltip mixes `TooltipDataHandlerMixin`
  (Retail, Forever). Era doesn't load `TooltipDataHandler.lua`; TBC/WotLK/MoP load it but no tooltip
  uses it, so post-calls never fire there. Branch on `GameTooltip.ProcessInfo`, not on
  `TooltipDataProcessor` existing. Classic keeps `OnTooltipSetUnit/Item/Spell`; mainline has none.
- Retail and Forever share the same secret flags on unit/health APIs (`UnitHealth`, `UnitClass`,
  `UnitGUID`, `UnitName`, `UnitPVPName`, `UnitIsAFK`, …); aura tooltip data is
  `SecretWhenUnitAuraRestricted`; line text can be secret. `GetGuildInfo` is undocumented on Retail
  (secret status unverified). Classic has no secret flags.
- Retail health bar value is a secret 0–1 percent (`UnitPercentHealthFromGUID`).
- `GameTooltip_ClearMoney` is only reached through `OnTooltipCleared` (all clients).
- Known bugs to fix: line scanning by text, `data.hiperlink` typo, `SpellButton_OnEnter` hooked
  with the wrong callback, pet-battle hooks concatenating a nil label, `kinds` missing
  `talent`/`item`/`macro`, double blank line on auras without a source, `HookScript("OnTooltipSet*")`
  also attempted on Forever (`not E.isStandard`).

**Decided:**
- Spell/aura IDs stay always-on. NPC ID stays Shift-only.
- Era vendor-price line stays.
- Comparison tooltips use Blizzard's anchoring (no copied anchoring code).
- No tooltip content beyond what Tainted has today; pet-battle, talent, recipe, azerite, conduit
  and totem ID hooks are dropped.

**Steps** (`make check` after each; Classic regressions checked on Era first):

1. **Skin + anchor cleanup** · Done · Depends on: —
   - Change: `TaintedTooltipAnchor` anchored to `TaintedChatRight` TOPRIGHT + `C.chat.margin` (same
     position as before); `UpdateAnchors` removed (moved Edit Mode containers from addon code);
     copied comparison anchoring removed; border/health-bar reset via `HookScript("OnTooltipCleared")`
     on each skinned tooltip instead of the `GameTooltip_ClearMoney` hook, health bar reset only for
     GameTooltip; Classic `ItemRefTooltip` gets the `OnTooltipSetItem` quality-border hook (chat links
     were always black).
   - Clients: Classic (Era, TBC, WotLK, MoP).
   - Test: tooltip above the right chat; border resets between hovers; Shift-compare beside the
     tooltip with quality borders; chat item link shows quality border; Edit Mode open/close (MoP).
2. **Classic entry-point cleanup** · Done · Depends on: 1
   - Change: Classic hooks (`Set*` methods and `OnTooltipSet*`) only when `not GameTooltip.ProcessInfo`,
     post-calls only when set; the SpellID line is added at most once per tooltip content (flag reset by
     `OnTooltipCleared`) instead of scanning line text; only spell IDs (`spell:` links, `spell` actions),
     so `kinds` is gone; `data.hyperlink` typo fixed; no double blank line on auras without a source.
     `SpellButton_OnEnter` hook removed: the global doesn't exist on Classic (`SpellButtonMixin`), and
     `SetSpellBookItem` already fires `OnTooltipSetSpell`. Pet-battle, talent, recipe, azerite, conduit
     and totem hooks dropped. Player aura buttons (`modules/auras`) get `UpdateTooltip`, like Blizzard's
     buff buttons, so a tooltip rebuilt after the first hover keeps its SpellID line. Era: temporary `print` in `HookScript(GameTooltip, "OnTooltipAddMoney")`
     to check whether Blizzard already shows a sell price away from a vendor (would duplicate Tainted's
     line); remove after checking.
   - Clients: Classic.
   - Test: same content as today, no duplicate ID lines; spellbook, action bar, player/target auras,
     chat spell link, reagent item; Era bag items away from a vendor (report the print).
3. **Unit tooltip on mainline** · Done · Depends on: 2
   - Change: one unit handler shared by the Unit post-call and `OnTooltipSetUnit`; mainline finds lines
     by `TooltipDataLineType` (`UnitName`, `UnitLevel`) + `lineIndex`, Classic keeps the text scan;
     `issecretvalue` guard before any compare, index or concatenation; NPC ID only with a non-secret GUID.
     Secret values fall back to Blizzard's text.
   - Clients: Retail, Forever (+ Classic regression).
   - Test: no errors in open world, dungeon, M+, PvP/arena; name/guild/level/target as on Classic when
     accessible.
4. **Health bar on mainline** · Done · Depends on: 3
   - Change: `OnValueChanged` ignores the (secret) bar value and skips secret unit tokens; text via
     `SetFormattedText("%s / %s", E.ShortValue(...))` (`AbbreviateNumbers` for secret health), no test or
     concatenation on health; `<Dead>` text is shown again after `OnTooltipCleared` hid it.
     Secret unit token (instances): border, bar and name colored by `GameTooltip_UnitColor("mouseover")`
     (plain `mouseover` reaction stays readable, verified on Retail); without a mouseover, Blizzard's
     name-line color is used (secret colors passed as is, white = no reaction keeps the cleared colors).
     Assumes the mouseover is the tooltip unit (can't compare a secret token).
   - Clients: Retail, Forever.
   - Test: bar and text update in and out of combat; taint log clean after combat; dungeon enemies
     red (bar, border, name) while switching targets. Verified on Retail.
5. **Item, spell and aura content on mainline** · Done, pending in-game verification · Depends on: 2
   - Change: Item post-call colors any skinned tooltip (ShoppingTooltips get their own post-call on
     mainline, so the `GameTooltip_ShowCompareItem` hook is Classic-only); reagent count only on
     GameTooltip/ItemRefTooltip; secret `hyperlink`/`guid` skipped (`C_Item` rejects secret args).
     Spell/PetAction post-call uses `data.id` (was `GetSpell()`, nil for PetAction) and now also covers
     ItemRefTooltip (chat spell links). Macro post-call: `GetActionInfo(slot)` from
     `processingInfo.getterArgs`, `"macro"` + subType `"spell"` gives the spell ID (as Blizzard's
     action buttons do). PetAction `data.id` being a spell ID is unverified (idTip assumes it).
     UnitAura post-call skips a secret `data.id` and the source lookup while
     `C_Secrets.ShouldAurasBeSecret()` (tainted `GetAuraDataByIndex` errored).
   - Clients: Retail, Forever.
   - Test: quality borders, reagent count, spell IDs on spells/actions/macros/auras; secret auras in
     combat show no ID and no error.
6. **Enable on all clients** · Done, pending in-game verification · Depends on: 1–5
   - Change: drop `[AllowLoadGameType classic]` from the tooltips TOC line; update compatibility.md.
   - Clients: all 6.
   - Test: steps 1–5 on Retail and Forever; no errors on any client.

### 7. Blizzard UI tweaks

**Status:** Classic/MoP only · **Priority:** Low · **Depends on:** 1, 2

Experience, mirror timers, objective tracker, queue status, durability, ghost, talking head,
raid utility, widgets.

**Done when:** each tweak is either verified per client or explicitly dropped.

### 8. Bags

**Status:** Planned · **Priority:** Low · **Depends on:** 3

**Objective:** one Tainted bag window on all 6 clients, plus a unified bank on Classic.

**Decided:**
- One shared implementation. Clients differ only in data: bag IDs (reagent bag on mainline,
  keyring when `GetKeyRingSize() > 0`), sort (Blizzard's `C_Container.SortBags` where it exists, Tainted's
  own on classic, step 5), bank and bag-slot strip (classic family).
- Slots are created from Blizzard's `ContainerFrameItemButtonTemplate` (`BankItemButtonGenericTemplate`
  for bank container `-1`) under a per-bag parent with `SetID(bagID)`. Blizzard handles use, drag, sell
  and tooltips. Nothing is secure, so the window can open and close in combat.
- Blizzard toggles are hooked (`hooksecurefunc`), never replaced. Blizzard bag/bank frames are disabled,
  not overwritten. The toggle follows Tainted's frame state.
- Updates: `BAG_UPDATE` marks a bag dirty → `BAG_UPDATE_DELAYED` refreshes only dirty bags. A relayout
  happens only when a bag's slot count changed. A hidden window updates nothing and refreshes dirty bags on show.
- Replaces the commented-out stubs (`core.lua`, `bags.lua`, `bank.lua`). Their fixed
  frame↔bag mapping and global overrides are wrong. `C.bags` stays as code constants.
- Non-goals: mainline bank/warband/reagent bank, item level, junk/new-item
  markers, categories/filters, gold or currencies in the window, movers, options.

**Steps:**
1. **Bag window** · Depends on: — · **Status:** implemented, awaiting in-game test
   - Change: unified frame for bags 0..`NUM_BAG_SLOTS` (bottom-right, `C.bags` columns). Hooks on
     `ToggleAllBags/OpenAllBags/CloseAllBags/ToggleBag/ToggleBackpack`. Blizzard container frames
     (and `ContainerFrameCombinedBags`) disabled. The `classic` TOC tag is removed. Stub files are deleted.
   - Done: `modules/bags/bags.lua` (loads after chat, anchors above `TaintedChatRight`). A
     `ContainerFrame_GenerateFrame` hook reparents Blizzard frames that hold a player bag to `E.Hider`.
     Their shown state is kept, and the window mirrors it after each toggle (`IsBagOpen(0..NUM_BAG_SLOTS)`),
     because on mainline with individual bags, `ToggleBackpack` calls `CloseAllBags` from inside the
     same call. The reagent bag, keyring and Classic bank bags stay in Blizzard frames until Steps 3/4.
     `containers.lua` stays `classic`-tagged until Step 3. Slots are empty until Step 2 (icons come from
     Blizzard's own frame updates); tooltips and clicks work.
   - Clients: all 6.
   - Test: B, backpack button and Gold click open/close only the Tainted window. Use, drag and split items,
     tooltips, sell at a vendor, use an item in combat without `ADDON_ACTION_BLOCKED`.
2. **Slot presentation and updates** · Depends on: 1 · **Status:** implemented, awaiting in-game test
   - Change: icon, count, quality border, cooldown, lock, quest marker. Dirty-bag updates. Free/total slot
     count in the window.
   - Done: Tainted fills the slots itself (no Blizzard update functions; classic ones address buttons by
     the container frame's name). Cropped icon, outlined count (`C.bags.font`), backdrop border colored by
     quality above common or yellow for quest items, quest-starter bang over the icon, desaturated when
     locked, dimmed while the cooldown is disabled. `BAG_UPDATE`/`BAG_CLOSED` mark a bag dirty,
     `BAG_UPDATE_DELAYED` refreshes dirty bags (relayout only on a slot-count change), `ITEM_LOCK_CHANGED`
     updates one slot, `BAG_UPDATE_COOLDOWN` updates cooldowns, `QUEST_ACCEPTED/REMOVED` mark all bags
     dirty. While hidden, events only mark state; `OnShow` catches up. Free/total (`free/total`) sits
     bottom-right in a footer row.
   - Clients: all 6.
   - Test: looting, moving and stacking items updates only the affected bag. Equipping a bigger bag
     re-lays out the window. Cooldowns sweep. The free count matches the Gold tooltip.
3. **Client extras** · Depends on: 2 · **Status:** implemented, awaiting in-game test
   - Change: search box on all clients (`C_Container.SetItemSearch` + `isFiltered`). Sort button and
     sort direction on mainline (moves the `isStandard` setup out of `core/core.lua`). Reagent bag on
     mainline. Keyring when present. On Classic the bag-slot strip (`containers.lua`) is attached to the
     window; Gold shift-click still toggles it.
   - Done: footer row with `BagSearchBoxTemplate` (left; clears on hide), sort button where
     `C_Container.SortBags` exists, free/total (right; bags 0..`NUM_BAG_SLOTS` only). Filtered slots show
     the template's `searchOverlay` (`INVENTORY_SEARCH_UPDATE`, caught up on show). Sort direction is set in
     the bags module on every load. Reagent bag and keyring (`GetKeyRingSize`; not on MoP, where Blizzard's keyring frame errors) are window bags, and their Blizzard
     frames are hidden too. The window stacks sections (bags, reagent bag, keyring, bag slots), 10px apart
     inside a 10px margin; sections shorter than a row sit on the right. Classic `CharacterBag0..3Slot` form
     the last section, shown by default and toggled by Gold shift-click (opens the window if closed); the
     rest of Classic's `BagsBar` (backpack and keyring buttons) is reparented to `E.Hider`, and a `SetPoint`
     hook on each bag slot anchors it back whenever `BagsBarMixin:Layout` moves it to the backpack button.
     `containers.lua` is removed.
   - Clients: all 6.
   - Test: search dims non-matches and clears on close. Retail/Forever sort works. The reagent bag shows on
     Retail/Forever. The keyring shows where it exists. Classic bag slots swap bags.
4. **Classic bank** · Depends on: 2 · **Status:** implemented, awaiting in-game test
   - Change: a unified bank window on `BANKFRAME_OPENED/CLOSED` with the bank container and bank bags.
     Blizzard `BankFrame` is hidden while the bank session stays open, and closing the window calls
     `CloseBankFrame()`. Bank bag slots and a purchase button use `CONFIRM_BUY_BANK_SLOT`.
     Mainline keeps Blizzard's bank.
   - Done: `modules/bags/bank.lua` (`classic`-tagged) builds `TaintedBank` with the bags window's code
     (`CreateWindow`, `AddSection/AddBag`, `CreateBagSlots`), anchored above `TaintedChatLeft`. One grid
     holds the bank container (`BankItemButtonGenericTemplate`, updated from `PLAYERBANKSLOTS_CHANGED`)
     and every bank bag. Blizzard's `BankSlotsFrame.Bag1..N` form the last section, updated with
     Blizzard's `BankFrameItemButton_Update`/`UpdateBagSlotStatus` (red when not bought). A footer button
     opens `CONFIRM_BUY_BANK_SLOT` while slots remain. `BankFrame` is reparented to `E.Hider`, so Blizzard
     still opens and closes it as a UIPanel and the session stays open. The window shows on
     `BANKFRAME_OPENED` with `OpenAllBags(window)`, and its `OnHide` (Escape via `UISpecialFrames`,
     `BANKFRAME_CLOSED`) calls `CloseAllBags(window)` and `CloseBankFrame()`. Bank-bag container frames go
     to the hider too. Free/total skips extra sections (reagent bag, keyring) instead of checking bag IDs.
     The bags window's search also dims bank slots.
   - Clients: Era, TBC, Wrath, MoP.
   - Test: the bank opens with the bags and shows every bank bag in one grid. Items move both ways. Buying a
     slot works. Walking away closes both windows. On Retail/Forever the Blizzard bank is unchanged.
5. **Classic sort** · Depends on: 3, 4 · **Status:** implemented, awaiting in-game test
   - Change: add sorting to the classic bags. These clients have no `C_Container.SortBags`, so Tainted
     moves the items itself (`C_Container.PickupContainerItem`), one move at a time, waiting for the
     locks to clear between moves. The sort button sits in the same footer spot as on mainline.
     Background: [classic-bags-sorting.md](classic-bags-sorting.md) (SortBags analysis); same idea,
     smaller and API-driven instead of item-ID lists and tooltip scans.
   - Decided:
     - Order (close to Blizzard's): hearthstone first, then `classID`, `subClassID` (descending, as retail
       sorts food > flask > potion), `itemEquipLoc`,
       quality (high first), name, itemID, then full stacks before the remainder. Items fill from bag 0
       slot 1 (top-left); junk (`Poor`) fills backwards from the last slot, like mainline with
       `SetSortBagsRightToLeft(true)`. Free slots end up between them.
     - Data without `GetItemInfo`: `C_Container.GetContainerItemInfo` (`itemID`, `stackCount`,
       `quality`, `itemName`, `isLocked`), `C_Item.GetItemInfoInstant` (class, subclass, equip loc),
       `C_Item.GetItemMaxStackSizeByID`. A nil value (uncached item, unverified whether it happens)
       waits a frame and retries.
     - Special bags: `C_Container.GetContainerNumFreeSlots` → `bagFamily`, `C_Item.GetItemFamily`.
       An item fits when `bagFamily == 0` or `bit.band(itemFamily, bagFamily) ~= 0`. Special bags are
       filled first with the items that fit them, then normal bags take the rest. Bags (`Container`,
       `Quiver` class) count as family 0: their own family is the one they hold.
     - Combat aborts: no start under `InCombatLockdown()`, `PLAYER_REGEN_DISABLED` stops a running sort.
     - One sort button, in the bags window. With the code constant `C.bags.sort_bank` (default `true`)
       and the bank open, it also sorts bank container `-1` and the bank bags, after the bags and
       separately (items never cross). `BANKFRAME_CLOSED` stops a running sort.
     - Keyring is never sorted. A second click while a sort runs does nothing.
   - Done: `modules/bags/sort.lua` (`classic`-tagged, after `bank.lua`) adds `MODULE:Sort()` and one
     hidden driver frame. Each frame (`OnUpdate`): a leftover cursor item is cleared; all slots are re-read
     (any locked slot or missing item data → wait); the target layout is rebuilt from the item totals, so
     loot mid-sort is picked up; the first slot not matching its target gets one move: swap the target
     item in (preferring a stack of the right size, only from a slot that accepts what is displaced),
     top up from a misplaced stack, split off an excess (`SplitContainerItem`), or move the wrong item out
     to an empty slot. No possible move → that group is done. Gives up after 300 frames of waiting or
     3 moves per slot. `bags.lua` creates the sort button when `C_Container.SortBags` or `MODULE.Sort`
     exists; the click calls the native sort or `MODULE:Sort()`.
   - Clients: Era, TBC, Wrath, MoP.
   - Test: sorting a messy bag gives a stable order, and a second click moves nothing. Hearthstone is
     top-left, junk at the end. Stacks are merged and nothing is lost or left on the cursor. Clicking while
     a sort is running, or entering combat during one, does no harm. Retail/Forever still use Blizzard's
     sort. Arrows go to the quiver (Era/TBC), shards to a soul bag, herbs to a herb bag. With the bank open
     the button sorts the bank too; with `sort_bank = false` it sorts the bags only.

**Done when:** every step passes `/reload` testing on Retail, Forever, Era, TBC, Wrath (Titan)
and MoP, with no Lua errors or taint messages.

### 9. Miscellaneous

**Status:** Classic/MoP only · **Priority:** Low · **Depends on:** 0

**Done when:** each feature has a keep/drop decision and a verified status per client.

### 10. Final compatibility audit

**Done when:**
- Every module loads on every client it's meant for.
- `make check` is clean of real bugs.
- This plan is up to date.

Unit frames continue in parallel as a leaf. Only item 0 touches them.

## 4. Known architectural risks (observed)

- **Ambiguous client flags.** Renamed in item 0 (`isRetail` → `isStandard`, `isClassic` →
  `isVanilla`, `isMoP` → `isMists`, `isForever` → `isCamelot`), and family flags
  `isMainline`/`isClassic` added. Call sites still use game flags where a family is meant, so
  Forever and TBC/WotLK/MoP can take wrong paths until each item moves them to family flags.
- **Implicit dependencies.** Modules find each other's frames by global name and rely on TOC
  order (chat/minimap → datatexts).
- **Core does module work.** It triggers the chat reset (action-bar settings moved out in item 4).
- **Two startup models.** Some modules use the registry `Init`. About 15 others create their own
  frame and initialize on login. Errors in the second group aren't isolated.
- **Secret values / restricted APIs on Midnight.** Most likely to affect auras, tags, the combat
  log and tooltips.
- **Pixel scale timing.** It is computed at file load, before UI scale is applied at login.
  Unverified.

## 5. Deferred work (don't fix early)

- Unit-frame raid-holder healer repositioning: currently dead machinery. Revisit with unit frames.
- Dead stubs (party unit, `development.lua`, `event_trace.lua`): remove during
  item 10.
- Settings with no effect (`C.blizzard.ghost/talkinghead/raid_utility`, `C.bags.*`): resolve
  with their items.
- Mainline-only Blizzard/misc files are kept but unverified on 12.x. Leave them until items 7/9.
- Combat-log based dispels/interrupts on Retail. Check the API docs before reviving (item 9).
- Duplicate client detection inside the dispels/screenshots mini-addons. Handle with item 9.
- Visual refinements outside design.md.

## 6. Decisions

**Decided:**
- One TOC with per-line tags; no `Tainted_*.toc`.
- No in-game configuration.
- Retail oUF is read-only.
- Item 1: datatexts are brought forward to Retail/Forever for the minimap strip, instead of
  hiding the strip.
- Item 1: minimap size stays per family: 198 on mainline (Blizzard default), 180 on classic.
- Item 1: Maps and Minimap stay two registry modules; `UpdateModules` is kept.

**Needs confirmation:**
- Item 0: one startup model for all modules, or keep both and document them?
- Item 2 vs 4: which comes first on Retail, chat or action bars?
- Item 8: bags scope. Bag-slot bar only, or real bag/bank frames (new code)?
- Item 9: keep or drop each misc feature on Midnight.

## Completed

- [x] TOC/client compatibility consolidation
- [x] Reference repository documentation
- [x] Configuration/settings audit
- [x] Architecture audit
- [x] 0. Core contract
- [x] 1. Minimap (pending in-game verification)
- [x] 2. Chat
  - [x] 1. API migration
  - [x] 2. Edit box header
  - [x] 3. Positioning
  - [x] 4. Temporary windows + cleanup
  - [x] 5. Reset ownership
  - [x] 6. History, copy, URL
  - [x] 7. Enable on all clients
- [x] 3. DataTexts
  - [x] 1. Element / registration / holder / capability split
  - [x] 2. Debug panel
  - [x] 3. Guild tooltip
- [x] 4. Action bars (pending in-game verification on Retail/Forever)
  - [x] 1. Bug fixes
  - [x] 2. Settings ownership
  - [x] 3. No global overrides
  - [x] 4. Stance and extra cleanup
  - [x] 5. All clients (pending Retail/Forever verification)
- [x] 5. Auras (player buffs/debuffs) (pending in-game verification)
  - [x] 1. Secret-safe aura content
  - [x] 2. Temporary enchants
  - [x] 3. Mainline aura containers (pending in-game verification)
- [x] 6. Tooltips (pending in-game verification)
- [ ] 7. Blizzard UI tweaks
- [ ] 8. Bags
- [ ] 9. Miscellaneous
- [ ] 10. Final compatibility audit
