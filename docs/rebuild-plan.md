# Tainted rebuild plan

A living roadmap. Start a session with: "Continue with the next item in the Tainted rebuild plan."
Principles and workflow live in [CLAUDE.md](../CLAUDE.md); client facts in
[compatibility.md](compatibility.md). This file only records order, status and decisions.

Legend: **Observed** = seen in the code · **Recommended** = proposal, not yet agreed ·
**Decided** = agreed, don't re-litigate.

## 1. Current state

- Revived after a long maintenance gap. TOC, references and settings have been cleaned up.
- **Observed:** on Retail and Forever, only core, unit frames, maps (minimap/worldmap), chat and datatexts
  load, plus tooltips, auras, action bars, bags and the Blizzard tweaks (all clients; ghost and
  talking head where the frame exists). Miscellaneous only loads on Classic and MoP.
- **Observed:** working: minimap, chat and datatexts on all clients; action bars on Classic (Retail/Forever pending verification).
  Unit frames: item 9 done on all clients, one classic oUF (`libs\oUF_Classic`) on Era, TBC,
  WotLK and MoP; Retail auras, raid auras and drift fixes verified on Retail, the rest (secret
  values on Retail/Forever, threat borders, short values) pending in-game verification.
  Blizzard tweaks: item 7 done (UI widgets and the final all-client check pending in-game
  verification). Bags (window on all clients, bank and sort on
  Classic/MoP) pending in-game verification.
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

**Status:** Done, pending in-game verification · **Priority:** Low · **Depends on:** 1, 2

**Objective:** each tweak verified per client or dropped; mainline gets the ones that work there.

**Done when:** each tweak is either verified per client or explicitly dropped.

**Observed (code):**
- Loading: one TOC line per file (step 1). Untagged: core, durability, experience, framerate,
  mirror_timer, objective_tracker, queue_status, ui_widgets. `mainline`: talkinghead. `mainline, mists`:
  ghost. raid_utility has no line. `event_trace.lua` loads nowhere (item 11).
- Startup: `core.lua` creates the `Blizzard` registry module; its `Init` calls framerate and queue
  status, then each `self.X:Init()/Load()` the files set. One error stops the remaining tweaks.
  `experience.lua` is separate: own frame, `PLAYER_LOGIN`.
- Settings: `C.blizzard.durability/ghost/mirrortimers/talkinghead/uiwidgets/raid_utility` (file-level early
  return). Experience keeps the selected bar in `TaintedDatabase` (`E:Get/SetExperienceBarIndex`).
- Shared code: only `core.lua`. Outside users: chat anchors the BN toast above
  `TaintedExperienceBar`; datatexts shift the left-strip tooltip while `TaintedExperienceBar` is shown
  (step 5).
- Action bars hide Blizzard's status tracking bars on all clients: Retail/Forever have no XP/rep bar today.
- The taxi/vehicle exit button (`modules/maps/minimap.lua`) uses the strip's own anchor
  (`Minimap` bottom, −3, 20 high) and covers the strip at a higher frame level.
- Unit frames already hide `CompactRaidFrameManager` (`UnitFrames:DisableBlizzard`, reparent to
  `E.Hider`), like ElvUI and Tukui. Its `UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")` is dead on
  Retail (no handler in `Blizzard_UIParent`); unit frames' concern.
- Objective tracker history: no recorded issue (`fc50f39`, `e52a320`; `docs/issues` empty).

**Observed (Blizzard source / API docs: Retail 12.1, Forever 1.60, MoP 5.5.4, Titan 3.80, TBC 2.5.6, Era 1.15.9):**

| Tweak | Retail · Forever | Era · TBC · Wrath · MoP | Edit Mode / secrets |
|:--|:--|:--|:--|
| Experience | XP/rep/honor APIs present; `GetPetExperience` not referenced in Retail UI source (unverified); Retail path calls `C_Reputation:GetWatchedFactionData()` with a colon | works today | no secret returns on XP/rep/honor; `UnitHonorLevel` `SecretWhenUnitIdentityRestricted` |
| Azerite / Artifact / Anima | `C_ArtifactUI`, `C_CovenantSanctumUI`, `AzeriteUtil` only here; Retail can have data (Blizzard still ships Artifact and Azerite bars); Forever has APIs, no content | `C_AzeriteItem` documented but no item, `AzeriteUtil` missing; no artifact/anima APIs | our bars skip Blizzard's visibility rules (artifact disabled/maxed, azerite enabled/max); `Item` + closure per event |
| House favor | Blizzard `HouseFavorBar`: shown while `C_Housing.GetTrackedHouseGuid()`; `C_Housing.GetCurrentHouseLevelFavor(guid)` → `HOUSE_LEVEL_FAVOR_UPDATED` (`houseGUID`, `houseLevel`, `houseFavor`); bounds `GetHouseLevelFavorForLevel(level)`/`(level + 1)`, max `GetMaxHouseLevel()` | `C_Housing` documented on every client (content Retail only) | no secret returns |
| Mirror timers | `MirrorTimerContainer:SetupTimer`; our branch is `E.isStandard`, so Forever hooks the nil `MirrorTimer_Show` → error | `MirrorTimer1..3`, `MirrorTimer_Show` | Edit Mode `TimerBars`; we only skin |
| Objective tracker | `ObjectiveTrackerFrame` (Edit Mode system, right-managed). Ours writes `ignoreFramePositionManager` (Edit Mode resets it); default-position height = right container height + anchor Y offset, so our offset-0 anchor makes it full height; hook skips combat; quest item clicks call protected `UseQuestLogSpecialItem` (taint symptom) | `QuestWatchFrame` (Era/TBC), `WatchFrame` (Wrath/MoP), right-managed; `SetPoint` hook re-anchors | ElvUI leaves Retail's to Edit Mode |
| Queue status | `QueueStatusButton` (parent `MicroMenuContainer`, `UpdatePosition`); `QueueStatusFrame` anchored to the button on show | no button (eye is `LFGMinimapFrame`/`MiniMapLFGFrame`, minimap_classic); `QueueStatusFrame` re-anchored to the eye on show; our holder is empty | MicroMenu layout |
| Durability | Edit Mode system + right-managed on all 6, `layoutIndex` 9 (top of the right container); container `TOPRIGHT` of UIParent, x = −(right bars width) − 5, y = −260 → ~29px below our strip (ends ~231) | same, y = −192 → overlaps our strip (ends ~213) by ~21px | our override never fires (nothing anchors to `MinimapCluster`) and replaces `SetPoint` on a Blizzard frame (taint). Offsets computed, unverified in game |
| Framerate | `FramerateFrame` (`Label`, `FramerateText`, `UpdatePosition`) | `FramerateLabel/Text` | — |
| Ghost | `GhostFrame` (`secureMixin` button); Retail re-anchors it on `Blizzard_UIWidgets` `ADDON_LOADED` | MoP only; none on Era/TBC/Wrath | ours `SetScript`s 4 handlers |
| Talking head | `TalkingHeadFrame` | none | Edit Mode system |
| Raid utility | `GetRaidTargetIndex` `SecretReturns` (compared → error); `Place/ClearRaidMarker` protected (our `ClearRaidMarker()` call is blocked); `SetRaidTarget`, `DoReadyCheck`, `DoCountdown`, `SetEveryoneIsAssistant`, `SetRestrictPings` `HasRestrictions` (meaning unverified) | `RestrictPings` missing | Blizzard covers it: secure `/wm` `/cwm` (macros, also in combat), `/tm`, `/readycheck`, `/countdown`, `RAIDTARGET1..8` keybinds on all 6 |
| Widgets | power bar container lives in `EncounterBar` (Edit Mode, bottom-managed); reparenting breaks that layout; Torghast is legacy | no power bar container (`Blizzard_UIWidgetPowerBarFrame` is tagged `mainline` in every TOC), no `EncounterBar` | `UIWidgetTemplateStatusBarMixin:Setup` on all 6; `C_UIWidgetManager` has no secret returns |

**Decided:**
- Feature detection first (`if C_Housing and C_Housing.GetTrackedHouseGuid then`, `if _G.MirrorTimerContainer then`);
  a client flag (`E.isStandard`, `E.isMainline`, …) only where nothing can be tested.
- Experience keeps every bar that can show data on some client: Azerite, Artifact and Anima stay on
  Retail, fixed. A house favor bar is added (Retail).
- Objective tracker: retry a Tainted anchor on mainline (step 12); Edit Mode is the fallback.
- Durability: re-anchored below the minimap strip on all clients, `C.blizzard.durability` (code
  constant, default `true`) turns it off.
- Raid utility dropped, no replacement (Blizzard slash commands and keybinds). The raid manager stays
  hidden by unit frames.
- Ghost: on every client that has it (Retail, Forever, MoP), on the taxi button's anchor (covers the strip).

**Recommended steps** (`make check` after each; Classic regressions checked on Era first):

1. **TOC lines instead of XML** · Done (verified on MoP) · Depends on: —
   - Change: one TOC line per file, current order, `core.lua` first, tagged
     `[AllowLoadGameType classic]` (= the union of the two identical XMLs). ghost, talkinghead and
     raid_utility get no line yet. Delete `init.xml`, `init_classic.xml`, `init_mists.xml`. Later steps
     change the tag per file; `core.lua` is untagged by the first step that enables a tweak on mainline.
   - Clients: Era, TBC, Wrath, MoP (no behavior change).
   - Test: `/reload`; every tweak unchanged; no errors.
2. **Isolated tweak init** · Done · Depends on: 1
   - Change: `core.lua` calls each tweak through `E:Call` (`core/core.lua`), framerate and queue status
     included, so one failing tweak doesn't stop the rest.
   - Clients: Classic.
   - Test: same as step 1.
3. **Framerate + talking head on mainline** · Done (verified on Retail) · Depends on: 2
   - Change: untag `framerate.lua` and `core.lua`; add `talkinghead.lua` (`if TalkingHeadFrame`). No
     code change expected.
   - Clients: Retail, Forever.
   - Test: Ctrl+R counter bottom-centre in Tainted font, also after Edit Mode exit; quest talking heads
     don't appear; Edit Mode open/close without errors.
4. **Mirror timers** · Done · Depends on: 2
   - Change: branch on `MirrorTimerContainer` existing instead of `E.isStandard` (fixes Forever); untag.
   - Clients: all 6.
   - Test: breath, fatigue, feign death bars skinned and colored; Edit Mode Timer Bars still movable.
5. **Experience cleanup** · Done · Depends on: 1
   - Change: rep call `C_Reputation.GetWatchedFactionData()`; pet bar only for hunters where
     `GetPetExperience` exists, updated on `UNIT_PET_EXPERIENCE` (unfiltered) and pet `UNIT_LEVEL` (MoP:
     pet levels with the player); `CVAR_UPDATE` dropped; each event updates only the bars it affects;
     base `SetTooltip` debug `E:print` removed; datatext tooltip offset checks `TaintedExperienceBar` (any bar), not `TaintedExperience`.
   - Clients: Classic.
   - Test: XP/rested, rep and pet XP (hunter) bars and tooltips; right-click switches bars and survives
     `/reload`; max level switches to rep; left-strip tooltip above the bar.
6. **Experience on mainline** · Done (verified on Retail) · Depends on: 5
   - Change: untag `experience.lua`. Bars are created from feature flags instead of `E.isStandard`. Before,
     `BarOrders[BarsEnum.X]` indexed an insertion-ordered array, so Artifact and Azerite read each other's row.
     Flags: honor `UnitHonorMax`; artifact `ArtifactBarGetNumArtifactTraitsPurchasableFromXP` (Blizzard Lua,
     mainline only; `C_ArtifactUI` is documented on every client); azerite `C_AzeriteItem` + `AzeriteUtil`;
     anima `C_CovenantSanctumUI`. Rep's paragon/renown/friendship branch keys on `C_MajorFactions`, and max
     level on `E.isMainline`, so Forever takes the mainline paths too. `HasData()` follows Blizzard's
     `CanShowBar`: artifact equipped, not maxed, not disabled; azerite equipped, enabled, not max; anima has
     currency info. Without data a bar resets to empty and skips the work (no artifact `Item` or closure).
     The right-click menu lists only bars with data, and a saved bar without data falls back to Experience at
     login. Fixes and cleanups:
     - Azerite: the missing `AzeriteUtil.IsAzeriteItemLocationBankBag` is gone (an equipped item can't be in the
       bank). The unlimited level is used when unlocked. `BAG_UPDATE` is dropped (`PLAYER_EQUIPMENT_CHANGED`
       covers an equipped item).
     - Events are registered only with their bar; `UNIT_INVENTORY_CHANGED` is a player unit event.
     - Percentages are set.
     - Renown: the paragon branch used `IsFactionParagon`, which is true for any faction with a paragon track,
       so a renown faction below max showed its reaction (5) and the paragon threshold (0 / 7500). It now uses
       `IsFactionParagonForCurrentPlayer` (paragon at max renown shows the renown level), and the renown
       progress is `renownReputationEarned` / `renownLevelThreshold` (full bar at `HasMaximumRenown`), as
       Blizzard's reputation frame shows it.
     - Friendship (e.g. Chromie): the rank number indexed the standard reputation names, so rank 1 showed a red
       "Hatred". The bar now shows the friendship rank name (`reaction`), plus `(current/max)` when the faction
       has ranks, and is always green, as Blizzard's reputation frame does.
     - Left-click on the reputation bar toggles the reputation tab (`ToggleCharacter("ReputationFrame")`,
       all 6 clients) to pick a watched faction; right-click keeps the bar menu.
     - Strings: `COVENANT_SANCTUM_TAB_RENOWN` gets a fallback. The honor prestige strings (unused by Blizzard,
       unverified) are replaced by `HONOR`.
   - Clients: Retail, Forever.
   - Test: XP, renown, paragon, friendship, honor; artifact/azerite/anima where a character has them,
     absent otherwise; no errors in instances/PvP.
7. **House favor bar** · Done (drawing and tooltip verified on Retail; tracked-house data unverified, no Midnight) · Depends on: 6
   - Change: new bar where `C_Housing.GetTrackedHouseGuid` exists (documented on all 6 clients), listed
     while a house is tracked (`HasData`). On show it requests `GetCurrentHouseLevelFavor(guid)`
     (`CreateBar` now sets `OnShow`); `HOUSE_LEVEL_FAVOR_UPDATED` for the tracked GUID stores level and
     favor; `Update` renders only the stored payload (requesting there would loop): bounds
     `GetHouseLevelFavorForLevel(level/level + 1)`, absolute like Blizzard; full at `GetMaxHouseLevel()` or a
     0 next bound. `TRACKED_HOUSE_CHANGED` clears it and re-requests when shown. Tooltip:
     `HOUSING_DASHBOARD_HOUSE_LEVEL` + `HOUSING_DASHBOARD_NEIGHBORHOOD_FAVOR` (at max
     `HOUSING_HOUSE_EXPERIENCE_FORMAT`), as the housing dashboard; string contents unverified, so fallbacks.
     Color: `BarColors` entry, artifact-power gold (Blizzard's fill). Unverified: whether
     `GetTrackedHouseGuid` is ready at `PLAYER_LOGIN` (else a saved house bar falls back to Experience).
   - Clients: Retail (no tracked house → not in the menu).
   - Test: with a house: bar fills and levels; tooltip values match the housing dashboard; selected bar
     survives `/reload`; without a house it isn't in the menu; no errors on Forever/Classic.
8. **Queue status** · Done (verified on Era and Retail) · Depends on: 3
   - Change: holder and button move only where `QueueStatusButton` exists; Classic keeps only the
     `QueueStatusFrame` skin. Untag.
     - The 0.65 scale moved from the button to the holder (45×45, ≈29px as before): Retail Edit Mode
       MicroMenu "Eye Size" (`MicroMenu:SetQueueStatusScale`) and Forever's Group Finder size call
       `SetScale` on the button and replaced ours; they now multiply on top of it.
     - The `SetPoint` hook clears points before `SetAllPoints(holder)`: Blizzard's
       `UpdatePosition`/`UpdateDefaultAnchor` point stayed and conflicted.
     - Our `QueueStatusFrame` anchor is dropped: Blizzard re-anchors it to the eye on every client
       (Retail `UpdatePosition`, Forever `OnEnter`, Classic `Update` to `LFGMinimapFrame`).
   - Clients: all 6.
   - Test: Retail/Forever eye bottom-left of the minimap, scaled, stays after Edit Mode/MicroMenu
     changes; tooltip skinned; Classic LFG eye unchanged, tooltip skinned.
9. **Ghost** · Done (verified on Retail and MoP) · Depends on: 2
   - Change: add `ghost.lua` tagged `mainline, mists`, guarded `if GhostFrame`; the taxi button's anchor
     (`Minimap` bottom, −3, 20 high, MEDIUM, strip level + 3, over the strip); unused locals and the
     global `TaintedGhost` frame removed.
     - Textures killed (`StripTextures(true)`), not cleared: the template's `OnMouseDown/Up` set them again.
       That makes the old mouse handlers unnecessary. `SkinButton` hooks `OnEnter/OnLeave`, as on the taxi
       button. The 4 `SetScript`s are gone. Icon killed; text centred in the maps font.
     - No re-anchor: Blizzard anchors it on `Blizzard_UIWidgets` `ADDON_LOADED` (Retail, Forever, MoP).
       That addon isn't LoadOnDemand, so it loads before Tainted (source).
   - Clients: Retail, Forever, MoP.
   - Test: die and release: button over the strip, skinned, returns to graveyard; no
     `ADDON_ACTION_BLOCKED` in an instance.
10. **UI widgets** · Done, pending in-game verification · Depends on: 2
    - Change: keep the status-bar skin hook (`UIWidgetTemplateStatusBarMixin:Setup`, all 6). Untag.
      - Power bar reparent and holder removed: `UIWidgetPowerBarContainerFrame` is defined only by
        `Blizzard_UIWidgetPowerBarFrame.xml`, tagged `mainline` on every client, with
        `parent="EncounterBar"`. It never existed on Classic (the reparent was dead) and exists only
        inside `EncounterBar` on mainline, so "only where `EncounterBar` doesn't exist" leaves nothing.
      - Torghast branch removed (`IsInJailersTower`, container re-anchor, kept atlas).
      - The flat texture is set on every `Setup`, not only the first: Blizzard's `UpdateBarFill` sets the
        fill atlas when it changes (`lastFillAtlas`), so a pooled bar reused for another texture kit
        showed Blizzard's fill.
      - Global `TaintedUIWidgets` frame replaced by a plain table; unused locals removed.
    - Clients: all 6.
    - Test: widget bars skinned (BG capture, world events, encounter power); Retail Encounter Bar
      movable in Edit Mode.
11. **Durability** · Done (verified on MoP) · Depends on: 2
    - Change: method override replaced by `hooksecurefunc(DurabilityFrame, "SetPoint")` re-anchoring via
      `ClearAllPointsBase`/`SetPointBase` (chat step 3 pattern) to `TOPRIGHT` of `TaintedMinimapDataText`
      `BOTTOMRIGHT`, 0, −5; also applied once at init (gear damaged at login). `C.blizzard.durability`
      (default `true`; `false` leaves Blizzard's place). Untag.
      - Source (all 6): `DurabilityFrame` inherits `EditModeDurabilityFrameSystemTemplate`, so
        `OnSystemLoad` keeps `SetPointBase`/`ClearAllPointsBase`. The right container's `Layout` and Edit
        Mode's `ApplySystemAnchor` call the `SetPoint` override, so the hook fires on every placement; the
        `*Base` calls don't re-enter it.
    - Risk: the hook runs inside Blizzard's `ManageFramePositions`; the frame keeps its slot in the right
      container (pushes vehicle seat/quest timer/arena frames down one slot); can't be moved in Edit Mode.
    - Clients: all 6.
    - Test: damaged gear: figure below the strip on Era and Retail, also after Edit Mode and combat;
      `false` leaves Blizzard's place; taint log clean.
12. **Objective tracker anchor on mainline (attempt)** · Done (verified on MoP, Retail and Era) · Depends on: 2
    - Change: Mainline: `ignoreFramePositionManager` write and override `SetPoint` calls removed;
      `hooksecurefunc(ObjectiveTrackerFrame, "SetPoint")` re-anchors via `ClearAllPointsBase`/`SetPointBase`
      (chat step 3 pattern): TOP/LEFT/RIGHT to `TaintedObjectiveTrackerContainer`, BOTTOM to
      `TaintedChatRight` TOP + `C.chat.margin`, so the height comes from the anchors, not `UpdateHeight`
      (unverified); also once at load. In combat the hook only registers `PLAYER_REGEN_ENABLED`, which
      re-anchors once and unregisters. Untag.
      - Classic: `WatchFrame` (Wrath/MoP) reparented to `UIParent` at load. It was a layout child of
        `UIParentRightManagedFrameContainer` (`layoutIndex` 10), so every container `Layout()` moved it, also
        in combat where our hook skips. Not the holder: `WatchFrame_Update` sizes it down to its parent's
        bottom. `QuestWatchFrame` (Era/TBC) is a managed frame and would be reparented back; it holds only
        font strings, so the hook's combat skip now applies only to protected frames (`IsProtected`) and
        Era/TBC re-anchor in combat too.
    - Fails if: quest item click gives `ADDON_ACTION_BLOCKED`/taint (`UseQuestLogSpecialItem`), in or out
      of combat; Edit Mode enter/exit/reset errors or jumps; contents clipped or overlapping the right
      chat/bags; not back at our anchor after combat.
    - Fallback: remove the mainline branch (hook, mainline holder), tag the file `classic`; Edit Mode
      places it.
    - Clients: all 6.
    - Test: the failure list, on Retail and Forever; Classic tracker unchanged (with Questie too).
13. **Raid utility** · Done · Depends on: 1
    - Change: remove `raid_utility.lua`, `C.blizzard.raid_utility`, `/tainted raid` and its README line.
    - Clients: all 6 (not loaded today).
    - Test: `/tainted` no longer lists `raid`; no errors.
14. **Done** · Done, pending in-game verification · Depends on: 3–13
    - Change: compatibility.md current status; §1 and §5 of this plan (`C.blizzard` settings).
    - Test: `/reload` on all 6 clients; taint log clean after combat and Edit Mode.

### 8. Bags

**Status:** Done, pending in-game verification · **Priority:** Low · **Depends on:** 3

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
     Their shown state is kept, and after each toggle the window follows the backpack
     (`IsBagOpen(BACKPACK_CONTAINER)`), because on mainline with individual bags, `ToggleBackpack` calls
     `CloseAllBags` from inside the same call. Closing the backpack closes the window's other bags
     (Blizzard's close leaves the keyring open), and `ToggleBag` on one window bag opens or closes all of
     them (one closed bag made B reopen the bags). The reagent bag, keyring and Classic bank bags stay in Blizzard frames until Steps 3/4.
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
     Retail/Forever. The keyring shows where it exists. Classic bag slots swap bags. Escape and B close the
     keyring and reagent bag with the window.
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
     to the hider too. At the bank, B (`ToggleAllBags`) closes the bank bags Blizzard would reopen with the
     bags; a bank bag slot click closes the hidden Blizzard frame it opens, and its open-bag highlight is
     hidden. Free/total skips extra sections (reagent bag, keyring) instead of checking bag IDs.
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

### 9. Unit frames

**Status:** Done, pending in-game verification · **Priority:** High · **Depends on:** 0, 5 (AuraContainer, curves, duration
objects), 6 (unit tooltip)

**Objective:** unit frames, raid frames and nameplates on every client, secret-safe on Retail, with
one classic oUF.

**Done when:**
- Unit frames, raid frames and nameplates work on all 6 clients; no secret-value errors on
  Retail/Forever in combat, encounters, M+ and PvP.
- One classic oUF serves Era, TBC, WotLK and MoP.
- The healer raid position works on every client.

**Observed (code):**
- Loading: `modules/unitframes` (core, tags, 15 elements, 13 classes, 11 units) is untagged. Plugins:
  `oUF_Atonement`, `oUF_Tempest` (`mainline`); `oUF_AuraTrack`, `oUF_RaidDebuffs`,
  `oUF_TargetIndicator` (`classic`). Retail oUF has its own `TargetIndicator` element;
  oUF_TargetIndicator calls `PostUpdate(isTarget)` like it.
- oUF per client (TOC tags; every client knows every game-type token, so only one copy loads;
  runtime unverified): Retail and Forever `libs\oUF`; Era, TBC, WotLK and MoP `libs\oUF_Classic`
  (one classic oUF since step 10; oUF_Merge from step 4 and oUF_Mists on MoP before).
- Per-oUF branching used `isRetailOUF = E.isStandard or E.isCamelot` (`core.lua`, `health.lua`):
  header visibility, nameplate spawn and callbacks, health prediction. Since step 7: `E.isMainline`
  (Retail oUF loads on the `mainline` family).
- Game flags where a family or the oUF variant is meant: AdditionalPower, PowerPrediction, Phase,
  PvPClassification, Quest and Summon indicators, Totems, Atonement, nameplate health `UpdateColor`
  and max distance, raid spec event, `CompactRaidFrameManager_SetSetting` (`E.isStandard`, so Forever
  gets nothing or a dead element); AlternativePower (`isStandard or isMists`, misses Forever);
  health `colorTapping` (`E.isVanilla`); rune colors (`E.isCata`, dead).
- Raid holder: healer repositioning is dead (`isHealer = false`, hard-coded `groupThreshold = 40`,
  talent events only registered after the first combat). `core/talents.lua` is `classic`-tagged, so
  `Talents` is nil on mainline. Global `GetSpecialization` is a deprecation fallback on every client;
  `C_SpecializationInfo.GetSpecialization`/`GetSpecializationInfo` (→ `role`) are documented (role
  return on Classic unverified). Era/TBC/WotLK infer the role from talent points; `/tainted tank`
  stores `E.db.tank` per character.
- 42 of the repo's luacheck warnings are in `modules/unitframes` (unused locals, dead code). Also a
  `frame.Heatlth` typo (`indicators.lua`), a debug `print` in `shaman.lua` (Tempest).

**Observed (Retail oUF, `libs/oUF` 8f37c36):**
- Auras is a meta element: `frame:CreateAuras()` + `:AddGroup(filter, options)` on a Blizzard aura
  container. There is no `Buffs`/`Debuffs` element, so Tainted's unit-frame auras are empty on
  Retail/Forever.
- `AddGroup` passes the filter string to Blizzard (`AuraUtil.AuraFilters`; filtering runs in secure
  code, secret-safe): `RAID`, `RAID_PLAYER_DISPELLABLE`, `DISPELLABLE`, `IMPORTANT`, `CROWD_CONTROL`,
  `BIG_DEFENSIVE`, `EXTERNAL_DEFENSIVE`, `RAID_IN_COMBAT`, `PLAYER`, `!` negation. Groups are added in
  order and are not exclusive (each checks every aura), so later groups need negations.
  `candidateFilters.isBossAura` selects or excludes boss auras. Spell-ID candidate filters are ignored
  for debuffs on friendly units (`AuraContainerUtil.lua`), so spell-list raid debuffs can't work on
  Retail. The flow layout draws groups in the order added; whether `IMPORTANT` applies to
  debuffs is unverified.
- ClassPower `PostUpdate` gained `hasCurChanged` (`cur, max, hasCurChanged, hasMaxChanged,
  powerType, ...`); Tainted uses the Classic order, so Retail resizes on the wrong flag and skips
  Maelstrom.
- `frame.unit` is no longer set (only `__unit`): oUF_Atonement, oUF_AuraTrack and oUF_RaidDebuffs
  return early. `colors.roles` removed (`[rolecolor]` errors, unused);
  `colors.debuff` is `colors.dispel`.
- Health `Over*Indicator` sub-widgets are Textures (Tainted creates StatusBars, never drawn). Totems
  icon mode passes a duration object to `SetCooldown`. `CustomTimeText`, `AlternativePower.__barID`,
  PvP `Banner` (now `Badge`), `HealthPrediction`/`PowerPrediction` are gone (inert in Tainted).
- Blizzard's nameplate cast bar is `UnitFrame.CastBarsContainer.castBar` on all 6 clients; Tainted's
  target callback anchors to the nil `UnitFrame.castBar`.

**Observed (secret values, Retail = Forever flags):**

| Element / tag | API (flag) | Tainted risk |
|:--|:--|:--|
| Unit-frame auras | AuraData (`SecretWhenUnitAuraRestricted`: combat, encounter, M+, PvP) | none once on aura containers |
| `nameshort`, `namemedium`, `namelong` | `UnitName` (`SecretWhenUnitNameIdentityRestricted`) | concatenation, `E.UTF8Sub` |
| `curhp`, `curpp` | `UnitHealth` (`SecretReturns`), `UnitPower` | oUF formats them; no abbreviation |
| Castbar color | `UnitChannelInfo` (`SecretWhenUnitSpellCastRestricted`; `castBarID` `NeverSecret`) | truth test on `name` |
| Nameplate health color | `UnitClass` (identity) | `colors.class[class]` unguarded |
| Nameplate creature role | `UnitGUID` (identity) via LibMobs | truth test before `issecretvalue` |
| AlternativePower | `UnitPower` (`SecretWhenUnitPowerRestricted`) | percent arithmetic |
| Atonement | AuraData `spellId` | table index |

`perhp`, `raidcolor`, `level` are guarded by oUF; `namecolor`, `hostility`, `difficulty`,
`classification`, `dead`, `healthcolor` use APIs without secret flags. Which Lua operations error
on secrets, and which contexts enable the unit-based predicates, is unverified.

**Observed (nameplate artwork on Era, TBC, MoP; `docs/issues/mop-nameplates.png`):** oUF_Classic and
oUF_Mists hide Blizzard's plate from a post-hook on `NamePlateDriverFrame.AcquireUnitFrame`. The hook
runs before `NamePlateBaseMixin:AcquireUnitFrame` assigns `self.UnitFrame` (and `ReleaseUnitFrame`
clears it), so `frame.UnitFrame` is always nil and nothing is hidden (the hook also receives the
driver, not the plate, as `frame`). Retail oUF hides it on
`NAME_PLATE_UNIT_ADDED`. Tainted's target callback also moves the widget container back into the
hidden Blizzard frame.

**Observed (oUF_Classic vs oUF_Mists):**
- Identical: colors, combatevents, events, factory, finalize, init, health, portrait, all indicators.
- Mists only: additionalpower, alternativepower, runes, stagger; chi/holy power/shards/arcane class
  power and tags, arena preparation, boss container, alt-power table, absorb and range events.
- Classic only: combo points on the target (`COMBO_TARGET_CHANGED`), castbar
  `CastingBarFrame_SetUnit` fallback, nameplate `UNIT_FACTION`, `GetAddOnMetadata` fallback, ping
  attribute; 5 totem slots (Mists 4).
- Mists `power.lua` reads the missing `Private.unitSelectionType` (only with `colorSelection`).
- Classic API docs (Era, TBC, Titan, MoP) are nearly identical: client differences are game content
  and undocumented globals (`GetArenaOpponentSpec`, `GetInspectSpecialization`,
  `PlayerVehicleHasComboPoints`, `GetRuneType`). `C_Ping` only has `IsPingSystemEnabled`;
  `PingableUnitFrameTemplate` is an empty stub.
- WotLK DKs: Tainted creates `frame.Runes`, but oUF_Classic had no Runes element (live since step 9).

**Observed (oUF_Classic vs Retail oUF API):**

| Element | Classic → Retail | Tainted call sites | Verdict |
|:--|:--|:--|:--|
| Health | `PostUpdateColor(unit, r, g, b)` → `(unit, color)` | MoP nameplate callback (`nameplate.lua`); `health.lua` already takes `(unit, color)` and ignores it | mirror |
| HealthPrediction | separate element → inside Health (`HealingAll`, `HealingPlayer`, `HealingOther`, `DamageAbsorb`, `HealAbsorb`, `Over*Indicator`, `UpdatePredictionSize`) | `CreateHealthPrediction` branch | mirror: `CreateUnitHealPredictionCalculator`, `UnitGetDetailedHealPrediction` documented on all 4 Classic clients (runtime unverified) |
| Power | `PostUpdateColor(unit, r, g, b, atlas)` → `(unit, color, altR, altG, altB)`; `GetDisplayPower()` → `(unit)` | none | mirror |
| PowerPrediction | separate element → `Power.CostPrediction`/`AdditionalPower.CostPrediction` | `CreatePowerPrediction` branch; `Power.CostPrediction` already built (inert on Classic) | mirror: Classic already uses `UnitCastingInfo` + `C_Spell.GetSpellPowerCost` |
| AdditionalPower | `PostUpdateColor(r, g, b)` → `(color)`; no CostPrediction. Inert on Classic: no Classic client defines `ALT_POWER_BAR_PAIR_DISPLAY_INFO`, the `private.lua` fallback has Retail pairs | `CreateAdditionalPower` `E.isMainline` gate | mirror |
| AlternativePower | `PostUpdateColor(unit, r, g, b)` → `(unit, color)`; Classic sets `__barID` | `PostUpdate` already falls back to `UnitPowerBarID` | mirror |
| Castbar | `PostCastStart/Interruptible/Update(unit)` → `(unit, spellID, notInterruptible, …)`; `PostCastStop(unit, spellID)`; no `PostCastInterrupted`/`PostCastGlobal`; `UpdatePips(numStages)` → `(stages)`; Retail times with duration objects | `element.notInterruptible` fallback (`castbar.lua`) | args: mirror. Timer: keep `CustomTimeText`/`CustomDelayText` |
| ClassPower | `PostUpdate` already Retail order; no charged points; `PreUpdate(event)` → `(unit)` | none | done; charged points are Retail content |
| Runes | `PostUpdateColor(r, g, b)` → `(color)`; spec colors only, no rune types (all runes `colors.power.RUNES` gray on WotLK/MoP with `colorSpec = false`) | none | mirror + rune types |
| Stagger | no `PostVisibility(isVisible)` | none | mirror |
| ThreatIndicator | `PostUpdate(unit, status, r, g, b)` → `(unit, status, color)` | none yet | mirror |
| Totems | `PostUpdate(slot, haveTotem, name, start, duration, icon)` → `(slot, haveTotem, name, icon, duration)` | none (`Override(event, slot)` is equal) | mirror |
| Range | `PostUpdate(object, inRange, checkedRange, isConnected)` → `(object, inRange, isEligible)` | none | mirror |
| PvPIndicator | `PostUpdate(unit, status)` → `(unit)` | none | mirror |
| Auras | button elements → `CreateAuras` + `AddGroup` on Blizzard's AuraContainer | `auras.lua` / `auras_mainline.lua`, `raid.lua` | impossible: AuraContainer on Classic unverified; AuraTrack/RaidDebuffs need Classic auras |
| Indicators, portrait, tags | equal callbacks | none | nothing to do |
| Retail-only elements (Phase, PvPClassification, Quest, Summon, FocusIndicator, MasterLooter, PrivateAuras, Happiness) | game content | `E.isMainline` gates stay | not ported; oUF_TargetIndicator already matches Retail |
| colors | `debuff` → `dispel` | Classic auras (`modules/auras/classic/aura.lua`, `elements/auras.lua`); `core/curves.lua` guard (then also builds the dispel curve on Classic, harmless) | mirror `dispel` |
| `SpawnHeader` | `(name, template, visibility, …)` → `(name, template, …)` + `header:SetVisibility` | `SpawnHeader` wrapper (`core.lua`) | mirror; keep `PetBattleFrameHider` |
| `SpawnNamePlates` | `(prefix, callback, cvars)` → driver with `SetAddedCallback`/`SetRemovedCallback`/`SetTargetCallback`/`SetSize`/`SetCVars`/`Set*Interactible` | `NameplateCallback` + spawn branch (`core.lua`) | mirror: `C_NamePlate.SetNamePlateSize`, `C_NamePlateManager.SetNamePlateHitTestInsets` documented on all 4; keep Classic `DisableNamePlate` and widget reparenting; dead `UNIT_FACTION` branch (never registered) goes |

Game-content branches stay: `E.isMists` Stagger anchor, MoP nameplate tank colors, AlternativePower
gate, indicator gates, raid aura split.

**Observed (rune types, WotLK and MoP):** Blizzard's rune frame (`RuneFrame_Shared.lua`, wrath/cata/
mists) reads `GetRuneType(rune)` (undocumented global) and handles `RUNE_TYPE_UPDATE(runeIndex)`
(documented); display order 1, 2, 5, 6, 3, 4 (MoP `RuneFrame.xml`, WotLK `RuneFrame_FixRunes`).
Its constants say 2 = frost, 3 = unholy; its combat text and pre-Legion oUF (`39071ca^`, colors
blood `1, 0, 0`, unholy `0, .5, 0`, frost `0, 1, 1`, death `.9, .1, 1`) say 2 = unholy.
Tainted's `oUF.colors.runes` (olive unholy, unused gray `[5]`) is unchanged since the initial
commit; oUF's spec colors are blood `247, 65, 57`, frost `148, 203, 247`, unholy `173, 235, 66`.

**Observed (number abbreviation):** `AbbreviateNumbers(number, options)` and
`CreateAbbreviateConfig(breakpoints)` are C functions on all 6 clients; Retail/Forever accept
secret numbers (`AllowedWhenTainted`) and return a secret string, which Retail oUF tags display.
`E.ShortValue` uses Lua rounding (`18.2m`) for plain values but Blizzard's default (`18M`) for
secret ones, so Retail's format changes in combat. Output under 1000, for fractions, and what
`RequiresRestrictedAbbreviationBreakpoints` allows on Classic are unverified (ElvUI's custom
breakpoints work on Retail/Forever).

**Decided:**
- Retail and Forever use `libs\oUF`, read-only; work around it in Tainted.
- One classic oUF for Era, TBC, WotLK and MoP: Mists changes were ported in `libs/oUF_Merge`
  (branch `classic-unified`), loaded on Era/TBC/WotLK from step 4 and on MoP from step 10, then
  squash-merged into `classic`. `libs/oUF_Classic` serves all four; oUF_Merge and oUF_Mists are
  removed. ClassPower `PostUpdate` uses the Retail oUF signature.
- oUF_Atonement, oUF_AuraTrack, oUF_RaidDebuffs and oUF_TargetIndicator may be edited. oUF_Tempest is
  out of scope (possibly dropped). The Atonement bar is dropped on Retail (step 5).
- Retail raid frames: oUF `Auras` groups with Blizzard filters replace oUF_AuraTrack and
  oUF_RaidDebuffs. Classic keeps both plugins and has no oUF `Auras` on raid frames.
  - Buffs, in order: `HELPFUL|BIG_DEFENSIVE`; `HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE`;
    `HELPFUL|PLAYER|RAID_IN_COMBAT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE` (own HoTs).
  - Debuffs, in order: `HARMFUL|RAID_PLAYER_DISPELLABLE`; boss debuffs; crowd control; important.
- Classic-family nameplate artwork is fixed in oUF_Classic and oUF_Mists (submodule edits), not in
  Tainted.
- `C_Ping` and other client-specific functions: feature detection per function.
- Healer raid position: `C.unitframes.raid.healer = { position = true, threshold = 20 }` (code
  constants). With a healer role and a group of at most `threshold` members, the raid frames move to
  the centre. `/tainted healer`, `/tainted tank` and `/tainted dps` set a per-character role
  override (`E.db.role`; `/tainted auto` clears it), e.g. where a healer spec can't be
  detected (Era, TBC).

**Recommended steps** (`make check` after each; Classic regressions checked on Era first):

1. **Nameplate artwork (classic family)** · Done · Depends on: —
   - Change: oUF_Classic and oUF_Mists drop the `AcquireUnitFrame` post-hook and call
     `DisableNamePlate(nameplate)` on `NAME_PLATE_UNIT_ADDED` (skips forbidden plates); its
     one-time `OnShow` hide is keyed by the unit frame (Blizzard pools them across plates). Edits
     stay uncommitted in the submodules. Tainted's target callback anchors to
     `CastBarsContainer.castBar` and leaves `WidgetContainer` on oUF's frame; the duplicate
     re-parent and ×2 scale are removed. Relies on Blizzard's driver handling the event first
     (unverified).
   - Clients: Era, TBC, WotLK, MoP.
   - Test: no Blizzard health bar, level, name or border under Tainted plates; target switching;
     widget plates; friendly forbidden plates in instances unaffected.
2. **Retail unit-frame auras** · Done (verified on Retail) · Depends on: —
   - Change: `elements/auras.lua` tagged `classic` (unchanged); new `elements/auras_mainline.lua`
     (`mainline`): `CreateBuffs`/`CreateDebuffs` build `frame:CreateAuras{...}` with
     `AddGroup("HELPFUL")`/`AddGroup("HARMFUL")` (`HELPFUL|PLAYER` with `buffs.selfBuffs`,
     `HARMFUL|PLAYER` on nameplates), size, spacing, count and anchors as Classic;
     `PostCreateButton` adds the Tainted backdrop; centered timer colored by
     `E.curves.auras.duration` (the Classic unit-frame curve, not `timer`), count, debuff border with
     `colors.dispel`, stealable border in `colors.stealable` (dispel-type textures as
     `modules/auras/mainline`).
   - Differences from Classic (they need aura data that is secret on Retail): every debuff gets a
     type border (Classic: only on friendly units); no desaturated foreign debuffs; no dispellable
     flash. Raid frames are step 3. Whether the flow layout resizes the container is unverified
     (the element keeps a fixed one-row size).
   - Aura buttons (here and the player auras, item 5) draw the Tainted backdrop with textures
     (`CreateTextureBackdrop`): Blizzard's backdrop mixin errors in the button initializer when a
     button batch is created while auras are secret (frost mage, many buffs). Fix pending in-game
     verification.
   - Nothing may anchor to an AuraContainer (`SetPoint` errors: "dependent object would inherit
     forbidden aspects: UntrustedLayoutScriptExecution"), so Debuffs are offset from the unit frame
     by one buff row instead of anchoring to Buffs.
   - Clients: Retail, Forever.
   - Test: target, focus, pet, boss, arena and nameplate auras placed as on Classic; timers, stacks,
     borders, tooltips; no errors in combat, dungeon, M+, PvP.
3. **Retail raid auras** · Done (verified on Retail) · Depends on: 2
   - Change: `raid.lua` calls `CreateRaidAuras` (`auras_mainline.lua`) on mainline instead of the
     classic plugins. Buffs (with `auratrack.enabled`): AuraTrack-style top row (same size and
     place), groups `HELPFUL|BIG_DEFENSIVE` (1), `HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE` (1),
     own HoTs `HELPFUL|PLAYER|RAID_IN_COMBAT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE` (4). Debuffs: a
     row centred on the health bar, one icon per group in order: `HARMFUL|RAID_PLAYER_DISPELLABLE`
     (`UnitFrameDebuff` sort, `ProcessAura` policy so `debuffType` is set);
     `HARMFUL|!RAID_PLAYER_DISPELLABLE` + `isBossAura = true`; `CROWD_CONTROL` and `IMPORTANT`
     (negating the earlier filters) + `isBossAura = false`. `C.unitframes.raid.debuffs` is now
     `{ enabled, num = 3, size = 27 }`: `num` = how many groups (icons) are shown. One large icon is
     `num = 1, size = 36`, dispellable only (groups can't pick the best across categories).
   - Group options are built per frame: oUF's `AddGroup` stores an element-bound closure in them.
     Icons are left-aligned inside the centred row. The flow layout draws groups in the order
     added (`AnchorUtil.ApplyFlowLayout`, `ipairs`). `RAID_PLAYER_DISPELLABLE` means dispellable by
     the group: a Magic debuff on a warrior with only Brann (delve) is not shown.
   - Clients: Retail, Forever (Classic: only `debuffs.enabled` check).
   - Test: dispellable debuff first, boss debuff, crowd control; defensives, externals and own HoTs
     on raid members; in combat, raid boss, M+, arena. Era: RaidDebuffs/AuraTrack unchanged.
4. **Retail drift fixes** · Done (verified on Retail) · Depends on: —
   - Change: TOC `vanilla, tbc, wrath` line loads `libs\oUF_Merge`. ClassPower `PostUpdate` takes
     the Retail order `(cur, max, hasCurChanged, hasMaxChanged, powerType)`; oUF_Merge now passes
     it too (tracks `__cur`), and an `E.isMists` adapter forwards oUF_Mists' old order. Nameplate
     `UpdateColor` uses `C_ClassColor.GetClassColor` for a secret class (as Retail oUF); castbar
     treats a non-nil `castBarID` (`NeverSecret`) or a non-secret name as a channel;
     `Over*Indicator` are Textures (5 px wide; never drawn before); totem icons via
     `SetCooldownFromDurationObject`; AlternativePower clears the percent when `cur`/`max` is
     secret; `[nameshort]` wraps a secret name with `C_StringUtil.WrapString` (no truncation;
     `E.UTF8Sub` already skips secrets); `[rolecolor]` removed (unused); LibMobs `UnitRole`
     checks `issecretvalue` before testing the GUID (submodule edit, uncommitted).
   - Maelstrom timers need `C_UnitAuras.GetAuraDuration`, which errors for tainted code while
     auras are secret: skipped when `C_Secrets.ShouldAurasBeSecret()`, segments then show the
     stacks without a timer (fix pending in-game verification).
   - Unverified: whether `castBarID` is set for every channel; secret `C_ClassColor` colors in
     `SetStatusBarColor`; `OverHealAbsorbIndicator` sits left of the health bar (oUF's anchor).
   - Clients: Retail, Forever (Era/TBC/WotLK: oUF_Merge load and class power; MoP: class power).
   - Test: combo points, holy power, Maelstrom; enemy channel colors; PvP nameplate class colors;
     names in M+; boss alt power; taint log clean.
5. **Plugins** · Done, pending in-game verification · Depends on: —
   - Change: oUF_AuraTrack, oUF_RaidDebuffs use `self.__unit or self.unit`; RaidDebuffs reads
     `colors.debuff or colors.dispel`. Edits stay uncommitted in the submodules.
   - AuraTrack and RaidDebuffs only load on Classic, where oUF still sets `unit` and `colors.debuff`.
     Their edits prepare for oUF_Merge following the Retail API.
   - oUF_Atonement: `self.__unit or self.unit`; skips a secret `spellId`; incremental updates use
     `updatedAuraInstanceIDs`/`removedAuraInstanceIDs` + `GetAuraDataByAuraInstanceID` (the
     misspelled keys and missing API left only a per-event `GetPlayerAuraBySpellID` fallback,
     removed).
   - Atonement dropped on Retail: `CreateAtonement` returns nil when `E.isStandard`. Its aura data
     is secret in combat unless the spell is `NeverSecret` (unverified), and the spell-ID lookups
     (`GetPlayerAuraBySpellID`, `GetUnitAuraBySpellID`: `RequiresNonSecretAura`) return nothing
     then, so the bar would miss every in-combat application and refresh. The priest hook still
     creates it only on `E.isStandard`, so it reaches no client until step 7 moves that flag
     (Forever).
   - Clients: Retail (no Atonement bar); Classic regression (AuraTrack, RaidDebuffs).
   - Test: Retail Discipline priest frame loads without the bar and without errors; Classic raid
     HoT tracking and raid debuffs unchanged.
6. **Healer raid position** · Done · Depends on: —
   - Change: `core/talents.lua` untagged; Retail, Forever and MoP read the role from
     `C_SpecializationInfo.GetSpecialization` + `GetSpecializationInfo` (`PLAYER_SPECIALIZATION_CHANGED`);
     Era/TBC/WotLK keep the talent-point heuristic (`PLAYER_TALENT_UPDATE`,
     `CHARACTER_POINTS_CHANGED`; druid Restoration is tab 3 there, was 4). The deprecated global
     `GetSpecialization`/`GetSpecializationRole` and the dead Cata branch are gone. Talents calls
     `OnRoleChanged(role)` (one callback field) only when the role changes. The raid holder applies
     the Decided rule (`C.unitframes.raid.healer`), re-checks on `GROUP_ROSTER_UPDATE`, and in combat
     waits for `PLAYER_REGEN_ENABLED` once; with `healer.position = false` it registers nothing.
     Commented code and the per-combat event (un)registering are removed.
   - Role override (replaces the Decided `/tainted healer` toggle and `E.db.tank`):
     `/tainted healer`, `/tainted tank`, `/tainted dps` store `E.db.role` per character; `/tainted auto`
     clears it. Old `E.db.tank` values are no longer read. Commands listed in
     README.md.
   - Unverified: the spec role return on Forever; whether the heuristic events fire on talent
     changes on Era/TBC/WotLK.
   - Clients: all 6.
   - Test: spec change moves the frames (after combat if in combat); `/tainted healer|tank|dps`
     on every client, `auto` clears; position kept after `/reload`; `healer.position = false`
     never moves; a group above `healer.threshold` uses the default position.
7. **Forever and family flags** · Done · Depends on: 2, 4
   - Change: the `isRetailOUF` locals are gone; oUF-variant and family branches use `E.isMainline`
     (Retail + Forever): AdditionalPower, AlternativePower (`or E.isMists`), PowerPrediction (not
     created), Phase, PvPClassification, Quest and Summon indicators, Totems (guard moved into
     `CreateTotems`; Classic is step 16), nameplate health `UpdateColor`,
     `CompactRaidFrameManager_SetSetting`, the `CreateAtonement` drop. The priest hook always calls
     `CreateAtonement`, so Classic priests get the bar without the `mainline`-only oUF_Atonement
     plugin (no updates; unverified in-game). Unit-frame health `colorTapping` is on for every
     client (was `E.isVanilla`; nameplates already were). Dead `E.isCata` rune color removed.
   - Forever API docs/source have every API these use (`UnitPhaseReason`, `UnitPvpClassification`,
     `UnitIsQuestBoss`, `C_IncomingSummon`, `GetUnitPowerBarInfo`, `GetTotemDuration`,
     `ALT_POWER_BAR_PAIR_DISPLAY_INFO`, `UnitInPartyIsAI`, `C_ClassColor`, raid manager `IsShown`).
   - Atonement is dropped on Forever too: `GetPlayerAuraBySpellID` has the same
     `RequiresNonSecretAura` flag there, and Forever's UI source has no Atonement. The bar is now
     created on no client.
   - Unchanged (game content): `nameplateMaxDistance` 61 only on Retail (Classic caps at 41;
     Forever's cap unverified), `showPet` on Era, the MoP `E.isMists` adapters, Tempest.
   - Clients: Forever (+ Retail regression; tapped color on all 6).
   - Test: Forever player frame (indicators, totems, alt power), nameplate colors, raid.
8. **Cleanup** · Done · Depends on: 1–7
   - Change: `Heatlth` typo fixed (the player raid role icon anchored to the frame, now to the
     health bar); dead nameplate `power_proto` (never mixed in) and the power element's
     `isHidden`/`PostUpdateNameplatePower` (undefined) branch removed; `threat.lua`
     (`CreateThreatIndicator` never called) deleted with its TOC line; unused locals removed.
     Unit-frame luacheck warnings 34 → 1 (Tempest's empty `if`; `shaman.lua` untouched).
   - Party frames: the never-called `party.lua` stub is now wired to a party header behind
     `C.unitframes.party.enabled` (default `false`: the raid frames show the party, as before).
     When enabled: a vertical column (`TOP`, `yOffset` 35 for the aura row) at the left edge,
     centred vertically, shown in a party outside a raid, including the player; unit frames with
     compact auras, leader, ready check, resurrect and range; the raid header drops its party
     clause. Fixed position (no healer move).
   - Kept: castbar `CustomTimeText`/`CustomDelayText`. Retail oUF ignores them, but oUF_Classic,
     oUF_Merge and oUF_Mists call them, so they still format the Classic/MoP timer text.
   - Clients: all 6.
   - Test: `/reload` on each; frames unchanged; raid role icon above the health bar; nameplate
     power bars; Classic castbar timer `cur / max`; boss and arena frames; with
     `party.enabled = true`: party column in a party (joins/leaves, in combat), raid frames in a
     raid, no Blizzard party frames.
9. **oUF_Merge: Era, TBC, WotLK** · Done · Depends on: 8
   - Change: oUF_Mists ported into `libs/oUF_Merge` (submodule edits, uncommitted): AdditionalPower,
     AlternativePower, Runes, Stagger elements; alt-power table in `private.lua` (used by
     PowerPrediction); chi, holy power, soul shards and arcane charges in ClassPower; `arcanecharges`,
     `arenaspec`, `chi`, `holypower` tags, battle-pet `level`, `faction` on
     `NEUTRAL_FACTION_SELECT_RESULT`; arena preparation; boss container; Blizzard arena frames hidden;
     absorb (HealthPrediction) and `UNIT_IN_RANGE_UPDATE` (Range) events; Power `colorPowerAtlas`;
     nameplate widgets ignore parent alpha. Kept Classic-only: combo points on target, castbar
     `CastingBarFrame_SetUnit` fallback, nameplate `UNIT_FACTION`, `GetAddOnMetadata` fallback,
     `ping-receiver`, aura `auraIndex` on Era, Retail ClassPower `PostUpdate` order.
   - The four Mists class powers are gated by `oUF.isMoP` (game content). Arcane charges compare
     `RequireSpec` with `C_SpecializationInfo.GetSpecialization()` (Mists compared the spec index with
     `GetInspectSpecialization`'s spec ID, so the bar never showed). Tags use
     `C_SpecializationInfo.GetSpecialization()` (the global is a deprecation fallback).
   - Feature detection: `GetArenaOpponentSpec` (arena preparation, `arenaspec`, `raidcolor`),
     `PlayerVehicleHasComboPoints`, `BossTargetFrameContainer` (else per-frame boss hiding),
     `Arena_LoadUI`, the `showArenaEnemyFrames` CVar (`C_CVar`). `GetInspectSpecialization` is no longer
     used; `GetRuneType` and `C_Ping` functions are not called by oUF_Merge. Totems already use the
     layout's slot count. Step 1's nameplate fix and the `unitSelectionType` fix were already in.
   - WotLK DKs: Tainted's `frame.Runes` is now live (one color, `colors.power.RUNES`; no rune types).
   - Verified: Era rogue combo points (target switch, kill). Druid untested.
   - Unverified: arena preparation on TBC/WotLK (`GetArenaOpponentSpec` presence);
     `BossTargetFrameContainer` on Era/TBC/WotLK.
   - Clients: Era, TBC, WotLK.
   - Test: combo points on target (Era/TBC), totems, aura tooltips, WotLK DK runes, arena (TBC/WotLK)
     without errors, nameplates.
   - Rollback: TOC line back to `libs\oUF_Classic`.
10. **oUF_Merge: MoP** · Done · Depends on: 9
    - Change: oUF_Merge TOC line tagged `classic`; oUF_Mists line removed (submodule kept). The
      `E.isMists` ClassPower `PostUpdate` adapter (oUF_Mists' old order) is removed: oUF_Merge
      passes the Retail order on MoP too.
    - Combo points: on MoP `UnitPower(unit, ComboPoints)` kept the previous target's points after
      a target switch. oUF_Merge ClassPower now reads `GetComboPoints(unit, 'target')` (submodule
      edit, uncommitted), as Blizzard's `ComboFrame` on Era, TBC, WotLK and MoP (undocumented
      global, used by Blizzard on all four). Target switches already update through
      `PLAYER_TARGET_CHANGED` → `VisibilityPath`. Applies to Era/TBC/WotLK too (Era regression).
    - Callback signatures Tainted uses are otherwise equal in oUF_Mists and oUF_Merge (Power
      `PostUpdateColor` gains a trailing `atlas`; AlternativePower still sets `__barID`). Kept
      `E.isMists` branches: Stagger anchored above ClassPower (layout), nameplate
      `PostUpdateColor(unit, r, g, b)`, AlternativePower gate (oUF_Merge has the element on
      Era/TBC/WotLK too; not enabled there).
    - Clients: MoP (combo points: Era, TBC, WotLK too).
    - Test: chi, holy power, shards, arcane charges, stagger, runes, alt power, arena preparation,
      boss frames, nameplates, castbar; combo points cleared on a target switch and restored when
      switching back (MoP), Era combo points unchanged.
    - Then (maintainer): `classic-unified` squash-merged into `classic`; the TOC loads
      `libs\oUF_Classic` (`classic`) on Era, TBC, WotLK and MoP; oUF_Merge and oUF_Mists submodules
      removed. Game loads on Era and MoP.
11. **Short values** · Done, pending in-game verification · Depends on: 4
    - Change: `E.ShortValue` formats every value, secret or not, with
      `AbbreviateNumbers(value, SHORT)`; `SHORT` is built once in `core/utils.lua` with
      `CreateAbbreviateConfig` (`1e9` → `b`, `1e6` → `m`, `1e3` → `k`, one decimal,
      `abbreviationIsGlobal = false`): `1.5b`, `18.2m`, `1.5k` in and out of combat. `tags.lua`
      re-enables `curhp`/`curpp` as `E.ShortValue(UnitHealth(u))`/`E.ShortValue(UnitPower(u))`
      with their `events` entries (the registration loop would otherwise clear oUF's). Player,
      target, ToT and arena keep `[curhp]` (now short); boss becomes
      `[healthcolor][curhp] - [perhp]%|r`; focus, focustarget, pet, nameplate and party keep
      `[perhp]%`. Tooltip health and Stagger text use the same format. design.md gains `1.5b`.
    - Truncates like Blizzard (`1999` → `1.9k`, was `2k`; `999999` → `999.9k`, was `1m`).
    - Unverified: `CreateAbbreviateConfig` with these breakpoints on Classic; output under 1000
      and for fractions (round plain values first if it keeps decimals); `1000` → `1k` or
      `1.0k`.
    - Commits: no submodule commit. Parent: `core/utils.lua`, `modules/unitframes/tags.lua`,
      `config/settings.lua`, `docs/design.md`.
    - Clients: all 6.
    - Test: player/target/ToT/arena text out of combat, in combat, raid boss and M+ on
      Retail/Forever (no secret errors, same format when combat starts); boss frames
      `cur - pct%` in an encounter; focus/pet/party/nameplates still percent; values 0, 999,
      1000, 1500, 18.2m, ≥ 1e9; rage/energy ≤ 100; low-level character; tooltip health; Monk
      stagger (MoP, Retail).
12. **DK rune types** · Done · Depends on: 10
    - Change: oUF_Classic Runes (submodule edits, uncommitted) restores the pre-Legion behavior
      when `GetRuneType` exists: runemap `{1, 2, 5, 6, 3, 4}`, no sorting, each rune colored by
      its type (fallback `colors.power.RUNES`), `RUNE_TYPE_UPDATE(runeIndex)` (unitless)
      recolors only that rune, `PostUpdateColor(color, rune)` per rune. `colors.runes` keeps
      the spec meaning (1 blood, 2 frost, 3 unholy) plus `[4]` death `0.9, 0.1, 1`; the element
      maps the rune type to that index if the game's order differs. Without `GetRuneType` it
      behaves as now. Tainted: `core/colors.lua` drops its `oUF.colors.runes` override;
      `elements/runes.lua` sets `colorSpec = true` (Retail/Forever color by spec; on WotLK/MoP
      the rune type wins).
    - Rune type order follows the combat text and pre-Legion oUF (1 blood, 2 unholy, 3 frost,
      4 death): `runeTypeColor = {1, 3, 2, 4}`. If frost and unholy show swapped colors in-game,
      it becomes `{1, 2, 3, 4}` (Blizzard's `RUNETYPE_*` constants). No extra login event: oUF
      updates all elements on `PLAYER_ENTERING_WORLD`. Retail/Forever runes change from gray to
      oUF's spec colors.
    - Unverified: rune type order (Blizzard's constants vs its combat text); WotLK slot types.
    - Commits: oUF_Classic (`classic`): `elements/runes.lua`, `colors.lua`. Parent: submodule
      pointer, `core/colors.lua`, `modules/unitframes/elements/runes.lua`.
    - Clients: WotLK, MoP, Retail, Forever.
    - Test: `/run for i=1,6 do print(i, GetRuneType(i)) end` on a fresh DK; two runes each of
      blood, frost, unholy in Blizzard's order; Death runes (Blood Tap, Death Rune Mastery /
      Blood Rites) recolor and revert; cooldown fill; vehicle hides; `/reload`, zoning, dungeon
      in combat; Retail/Forever spec colors, also after a spec change.
13. **oUF_Classic: Retail callbacks, colors and factory** · Done ·
    Depends on: 10, 12
    - Change: oUF_Classic (submodule edits, uncommitted) passes Retail arguments: color objects
      to `PostUpdateColor` (Health `(unit, color)`, Power `(unit, color, altR, altG, altB)`,
      AdditionalPower `(color)`, AlternativePower `(unit, color)`, Runes `(color)`) and
      ThreatIndicator `PostUpdate(unit, status, color)`; Castbar `PostCastStart(unit, spellID,
      notInterruptible, name, texture, isTradeSkill)`, `PostCastInterruptible(unit, spellID,
      notInterruptible)`, `PostCastUpdate(unit, spellID)` (no duration objects);
      `PostCastStop(unit, spellID)` was already equal; Totems `PostUpdate(slot, haveTotem, name,
      icon, duration)` with `GetTotemDuration(slot)` (duration object, documented on all 4);
      Range `PostUpdate(object, inRange, isEligible)` (`isEligible` = connected and range
      checked); Stagger `PostVisibility(isVisible)`; `colors.dispel` replaces `colors.debuff`
      (entries and the `none`/`''` aliases kept). oUF_Classic's `SetRGBA` defaults alpha to 1
      like `ColorMixin` (a nil alpha made `ColorCurve:AddPoint` reject the dispel colors on
      MoP). Gradient colors pass one cached color object
      per element (`Private.SmoothColor`); Power passes alt components only without a color
      object, as Retail. Factory: `SpawnHeader(name, template, …)` + `header:SetVisibility`;
      `SpawnNamePlates(prefix)` returns Retail's driver (`Set*Callback`, `SetSize`,
      `Set*Interactible`, `SetCVars`; size, hit-test insets and cvars on login), keeping
      `PetBattleFrameHider`, `DisableNamePlate` (step 1) and the widget/soft-target reparenting.
      The target callback only runs with a plate (as Retail); the dead `UNIT_FACTION` branch is
      gone. No widgets-only pause (oUF_Classic has no `PauseAllElements`).
    - PvPIndicator unchanged: Classic's `(unit, status)` already matches Retail's call
      (`unit, status, info`) positionally.
    - Tainted: MoP nameplate `PostUpdateColor(unit)`; castbar drops the
      `element.notInterruptible` fallback; Classic auras (`elements/auras.lua`,
      `modules/auras/classic/aura.lua`) read `E.colors.dispel`; `core/colors.lua` and
      `core/curves.lua` lose their `colors.dispel` guards (the dispel curve now also exists on
      Classic, used only for secret dispel names); `core.lua` loses the `SpawnHeader` wrapper and
      `NameplateCallback` (Retail spawn code on every client).
    - Kept: Castbar `CustomTimeText`/`CustomDelayText` (Classic times are numbers), Classic
      `Buffs`/`Debuffs`, game-content gates.
    - Change on Classic: plates get Retail's `SetSize(200, 20)` and hit-test insets
      (`C_NamePlate.SetNamePlateSize`, `C_NamePlateManager.SetNamePlateHitTestInsets`,
      `Enum.NamePlateType` documented on all 4; Blizzard's Classic nameplate driver matches
      Retail's).
    - Unverified: hit-test insets on Classic (clickable area of plates); `GetTotemDuration` at
      runtime on Classic.
    - Commits: oUF_Classic (`classic`): `ouf.lua`, `colors.lua`, `private.lua`,
      `elements/{auras,health,power,additionalpower,alternativepower,runes,threatindicator,
      castbar,totems,range,stagger}.lua`. Parent: submodule pointer, `core/colors.lua`,
      `core/curves.lua`, `modules/unitframes/core.lua`, `units/nameplate.lua`,
      `elements/castbar.lua`, `elements/auras.lua`, `modules/auras/classic/aura.lua`,
      `docs/rebuild-plan.md`.
    - Clients: Era, TBC, WotLK, MoP (Retail/Forever: `core.lua` regression).
    - Test: castbar colors (cast, channel, not interruptible) in a dungeon; MoP tank nameplate
      colors; dispel-type aura borders (unit frames, player auras, RaidDebuffs in a raid); boss
      alt power (MoP); totems; raid range fading; DK runes; raid/raid40/party headers on
      joining/leaving groups, in and out of combat, pet battles (MoP); nameplates: step 1 tests
      again, clicking/targeting plates, widget plates, target switch, friendly plates in
      instances, cvars after `/reload`.
14. **Classic AdditionalPower** · Done · Depends on: 13
    - Change: oUF_Classic (submodule edits, uncommitted): the `private.lua` display pairs
      follow Blizzard's `Wrath/AlternatePowerBar.lua` (TOC `wrath, cata, mists`): WotLK and MoP
      druid Rage/Energy → mana; MoP monk Energy → mana; no pairs on Era/TBC (Blizzard has no bar
      there). The Retail pairs and the `_G.ALT_POWER_BAR_PAIR_DISPLAY_INFO` lookup (no Classic
      client defines it) are gone. AdditionalPower adds Blizzard's monk `specRestriction`:
      shown only when `C_SpecializationInfo.GetSpecialization() == SPEC_MONK_MISTWEAVER`,
      re-checked on `PLAYER_SPECIALIZATION_CHANGED` (registered for MoP monks only). Tainted:
      `CreateAdditionalPower` drops its `E.isMainline` gate.
    - Side effects: Classic PowerPrediction now gets its `altBar` (mana cost while in a druid
      form; `HasAltPowerBar` reads the same pairs, no spec check, but the bar's parent is hidden
      for other monk specs).
    - `Power.CostPrediction` and `AdditionalPower.CostPrediction` are hidden at creation: only
      Retail oUF sizes and shows them. On Classic the main power bar drew a wide overlay (no
      width, `TOP` centres it, 0/0 range draws full; seen on MoP, pre-existing). Step 15 wires
      them on Classic.
    - Verified: MoP Mistweaver shows the mana bar beside its power bar (`UnitPowerType` →
      `3 ENERGY`); spec changes show/hide it; mana cost prediction on it.
    - Commits: oUF_Classic (`classic`): `private.lua`, `elements/additionalpower.lua`. Parent:
      submodule pointer, `modules/unitframes/elements/power.lua`.
    - Clients: WotLK, MoP (Era/TBC: created, never shown).
    - Test: druid in Bear/Cat shows the mana bar, hidden in caster form and Moonkin; updates in
      combat; MoP Mistweaver in Fierce Tiger stance shows it, Windwalker/Brewmaster don't; spec
      change; vehicles; Era/TBC druid: no bar, no errors.
15. **oUF_Classic: Retail prediction** · Done · Depends on: 14
    - Change: oUF_Classic (submodule edits, uncommitted) moves HealthPrediction into Health:
      Retail sub-widgets (`HealingAll`, `HealingPlayer`, `HealingOther`, `DamageAbsorb`,
      `HealAbsorb`, `Over*Indicator` via `SetAlphaFromBoolean`), options (`*ClampMode`,
      `healAbsorbMode`, `incomingHealOverflow`), `element.values` calculator,
      `UpdatePredictionSize`; prediction events registered only for present sub-widgets.
      PowerPrediction moves into `Power.CostPrediction` (player only, `UNIT_SPELLCAST_*`) and
      `AdditionalPower.CostPrediction` (registered while the bar is enabled). Both old elements,
      their `oUF.xml` lines and the now unused `Private.HasAltPowerBar` are removed. Tainted:
      `CreateHealthPrediction` is the former mainline builder on every client (Classic bars
      deleted); `CreatePowerPrediction` and the player's `PowerPrediction` are gone; the two
      `CostPrediction` bars are no longer hidden at creation (both oUFs hide them on enable).
    - Classic Health keeps `UnitHealth`/`UnitHealthMax` for the main bar (Retail reads the
      calculator) and calls `UnitGetDetailedHealPrediction` only when a prediction sub-widget
      exists: bad calculator data on a Classic client can only break the prediction bars.
      All calculator APIs, `SetAlphaFromBoolean` and the three prediction events are documented
      on Era, TBC, WotLK and MoP; no Blizzard Classic UI calls the calculator.
    - Looks different on Classic (Retail layout): incoming heals and absorbs start at the health edge
      and overlap (were chained my → other → absorb); heal overflow 1.05 (was 1); 5 px
      over-heal/over-absorb indicators.
    - Verified: health prediction on Era and TBC. MoP probe (`core/development.lua`): the
      calculator's health and incoming heals match `UnitHealth`/`UnitGetIncomingHeals`; heals
      past max health are capped at 1.05 × max with `clamped = true` (priest: raw 7895 →
      290.35 at full health). The overflow stays at 1.05 (Retail oUF's and Blizzard's default),
      so an over-heal draws up to 5% past the bar edge with the over-heal indicator. Small bars
      on large health pools are expected (Soothing Mist tick 2812 of 472k); Surging Mist cast
      during Soothing Mist is instant and has no prediction.
    - Unverified: absorbs and heal absorbs on MoP/WotLK.
    - Commits: oUF_Classic (`classic`): `elements/health.lua`, `elements/power.lua`,
      `elements/additionalpower.lua`, `private.lua`, `oUF.xml`, remove
      `elements/healthprediction.lua` and `elements/powerprediction.lua`. Parent: submodule
      pointer, `modules/unitframes/elements/health.lua`, `modules/unitframes/elements/power.lua`,
      `modules/unitframes/units/player.lua`, `docs/rebuild-plan.md`.
    - Clients: Era, TBC, WotLK, MoP.
    - Test: incoming heals (own, others) on player and raid frames in combat; absorbs (WotLK
      Power Word: Shield, MoP); heal absorbs (MoP); overheal indicators; mana cost on cast
      (player, druid in form on WotLK/MoP).
16. **Classic totems** · Done · Depends on: 10
    - Change: `CreateTotems` also builds the bar on Classic (its `E.isMainline` guard is gone).
      oUF_Classic has a Totems element that calls `Totems.Override(self, event, slot)` like Retail
      oUF; Classic API docs (Era, TBC, Titan, MoP) have `GetTotemInfo`, `GetTotemDuration`,
      `SetTimerDuration`, `SetCooldownFromDurationObject`, `C_StringUtil.TruncateWhenZero`,
      `Enum.StatusBarInterpolation`/`StatusBarTimerDirection` and the duration-object methods;
      `MAX_TOTEMS` is 4 with both priority tables; `TotemFrame` (unregistered by oUF_Classic) and
      `GameTooltip:SetTotem` exist on all four. `E.curves.auras.duration` and `oUF.colors.totems`
      load on every client.
    - `shaman.lua` unchanged: `CreateTempest` already anchors below `frame.Totems` when present,
      and its call is commented out (no Maelstrom bar on any client).
    - Bar timers use `E.FormatTime` (`15m`, was `890`); a secret remaining time (Retail,
      `SecretWhenTotemSlotSecret`) keeps `C_StringUtil.TruncateWhenZero` (raw seconds).
    - Unverified: `GetTotemDuration` at runtime on Classic (nil for an empty slot, as Retail).
    - Commits: parent: `modules/unitframes/elements/totems.lua`, `docs/rebuild-plan.md`.
    - Clients: Era, TBC, WotLK, MoP.
    - Test: shaman totem bar (bars and icon mode, timers, tooltips, right-click), other MoP classes
      with totem slots, totems after `/reload` and zoning.
17. **Threat indicator** · Done, pending in-game verification · Depends on: 13, 16
    - Change: raid (raid, raid40) and party frames get oUF's `ThreatIndicator` as an empty Frame
      (`elements/threatindicator.lua`, new TOC line): oUF only shows/hides it, `PostUpdate(unit,
      status, color)` stores `color` (`colors.threat[status]`, nil at status 0) and recolors the
      border only when it changed. `UnitFrames:UpdateBorderColor(frame)` (`targetindicator.lua`)
      picks the border: target highlight > threat color > `C.general.border.color`. The
      TargetIndicator `PostUpdate` stores `isTargeted` and calls it (nameplates unchanged; a
      secret `isTargeted` still returns early). Not a restore of the old `threat.lua`.
    - `UnitThreatSituation(unit)` (one token, no `feedbackUnit`): the
      `SecretWhenUnitThreatStateRestricted` predicate says single-token queries are generally not
      secret. Retail oUF compares `status > 0` itself, so a secret status would error inside oUF
      (fallback then: an `Override` with `issecretvalue`). Unverified.
    - Both oUFs call `PostUpdate(unit, status, color)` after step 13, so no client branch.
      design.md: raid/party cell border line.
    - Commits: parent: `Tainted.toc`, `modules/unitframes/elements/threatindicator.lua`,
      `modules/unitframes/elements/targetindicator.lua`, `modules/unitframes/units/raid.lua`,
      `modules/unitframes/units/party.lua`, `docs/design.md`, `docs/rebuild-plan.md`.
    - Clients: all 6.
    - Test: raid/party member border yellow/orange/red with threat (group, tanking, pulling off the
      tank), black on drop and after combat; targeted member keeps the highlight and shows threat
      again after a target change; `party.enabled = true` party column; nameplate target
      highlight unchanged; no secret-value errors in encounters and M+ on Retail/Forever.
18. **Done** · Done, pending in-game verification · Depends on: 1–17
    - Change: §1 and §4 of this plan (compatibility.md and the classic oUF merge are done, step 10).
    - Test: `/reload` on all 6; taint log clean after combat.

**Unverified (needs in-game checks):** which oUF loads at runtime on Forever and WotLK; every
secret-value row; Blizzard's event order for step 1; the Classic `GetSpecializationInfo` role return;
WotLK spec behavior in oUF_Classic; `IMPORTANT` on debuffs; rune type order (step 12);
number abbreviation on Classic (step 11); Classic absorbs and heal absorbs on WotLK/MoP (step 15);
secret `UnitThreatSituation` on raid units (step 17).

### 10. Miscellaneous

**Status:** In progress (Classic/MoP only) · **Priority:** Low · **Depends on:** 0, 3 (threat bar anchor)

**Objective:** each mini-addon loads on every client where it can work, without the deprecation fallbacks, secret-safe on Retail.

**Done when:** each feature has a keep/drop decision and a verified status per client.

**Observed (code):**

| Feature | Files | Loaded today | Startup | `C.*` | Events · frames · APIs |
|:--|:--|:--|:--|:--|:--|
| Dispel announcer | `dispels/` (git submodule, standalone addon) `init.lua`, `dispels.lua` | Classic (4) | own frame; `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`; CLEU only in party/raid instances | — | `C_CombatLog.GetCurrentEventInfo/DoesObjectMatchFilter`, `GetInstanceInfo`, `C_Spell.GetSpellLink`, `SendChatMessage` |
| Interrupt announcer | `interrupts/` (submodule) `interrupts.lua` | Classic | own frame; CLEU always from `PLAYER_LOGIN` | — (local `cfg`) | same, plus `IsInGroup/IsInRaid` |
| Screenshots | `screenshots/` (submodule) `init.lua`, `screenshots.lua`; `settings.lua` bridge | Classic | own frame `PLAYER_LOGIN`; `settings.lua` merges `C` at file load | `screenshots.*` | `Screenshot`, `BOSS_KILL`, `ENCOUNTER_START/END`, `ACHIEVEMENT_EARNED`, `CHALLENGE_MODE_COMPLETED`, `PLAYER_LEVEL_UP`, `PLAYER_DEAD`, `SCREENSHOT_*`; `GetAchievementInfo`, `GetDifficultyInfo` |
| Merchant (auto repair, sell junk) | `merchant.lua` | Classic | own frame `MERCHANT_SHOW` | — | `CanMerchantRepair`, `GetRepairAllCost`, `RepairAllItems`; `C_MerchantFrame.*` behind `E.isStandard`; `C_Container.*`; `_G.GetItemInfo` |
| Threat bar | `threatbar.lua` | Classic | own frame `PLAYER_LOGIN`; anchor on `PLAYER_ENTERING_WORLD` | `threatbar`, `font`, `texture`, `general.background.multiplier` | `UnitDetailedThreatSituation`, `UnitAffectingCombat`, `UnitName`; 0.75 s `OnUpdate` poll in combat; covers `TaintedChatRightDataText`; parent `E.PetHider` |
| Auto keystone | `auto_keystone.lua` | nowhere | own frame `ADDON_LOADED` (`Blizzard_ChallengesUI`) | `mythic.autokeystone` | `ChallengesKeystoneFrame` `OnShow` hook; `C_Container.*`; `C_Item.GetItemInfo` (12th return) |
| Dungeon portals | `dungeon_portals.lua` | nowhere | own frame `ADDON_LOADED` | `mythic.portals`, `font` | `hooksecurefunc(ChallengesFrame, "Update")`, `ChallengesFrame.maps`; secure macro buttons; `C_ChallengeMode.GetMapUIInfo`, `C_MythicPlus.GetSeasonBestForMap`, `IsSpellKnown`, `C_Spell.GetSpellCooldown/GetSpellName` |
| Skyriding race | `skyriding_race.lua` | nowhere | own frame `PLAYER_LOGIN`; player `UNIT_AURA` | `skyriding_race`, `font`, `texture` | `C_UnitAuras.GetAuraSlots/GetAuraDataBySlot/GetAuraDataByAuraInstanceID` |

- Independence: all eight are independent of each other. Shared code is limited to `settings.lua`
  (screenshots bridge) and `C.miscellaneous.font/texture`. Outside dependencies:
  - threat bar: datatexts (`TaintedChatRightDataText`, looked up at `PLAYER_ENTERING_WORLD`) and core
    (`E.PetHider`, `E.colors.threat`);
  - merchant: locales (`L.merchant`, `L.gold/silver/copper`);
  - auto keystone: repeats the bag scan of `core/keystone.lua` (`GetKeystone`/`IsKeystone`).

  No feature depends on minimap, chat, bags or action bars.
- Submodules: `dispels`, `interrupts`, `screenshots` are git submodules (lua-wow/*) and standalone
  addons with their own TOC. luacheck excludes them. Fixes there are upstream commits plus a
  pointer bump in Tainted (both are the maintainer's git operations).
- Duplicate client detection: `dispels/init.lua` and `screenshots/init.lua` set `isRetail/isClassic/isTBC/
  isWrath/isCata/isMoP` from `WOW_PROJECT_ID`. Screenshots reads none of them. Dispels reads only
  `isRetail`, for M+ affix data that is dead (CLEU can't be read on Retail, below).
- Leaked globals and dead code:
  - Named frames `TaintedThreatBar`, `TaintedRaceTracker` and `TaintedAutoKeystone` (the last needs no
    name). `ns.Interrupts = Interrupts` reads an undefined global (always nil, unused).
  - Dead code:
    - dispels: `Dispels.debuffs`, `LE_EXPANSION_*`, `band/tinsert/tremove/GetSpellInfo/GetSpellName`;
    - screenshots: the debug `print` in `OnAchievementEarned`, `Disable`;
    - skyriding: `FilterAura`, `Start_StopWatch/Pause_StopWatch`, `oUF`, `changed`;
    - threat bar: `UnitIsDead`;
    - misc: `init.xml` and the commented TOC line.
  - luacheck: 4 warnings (merchant shadowed `itemLink`; skyriding `oUF`, `changed`; threat bar `UnitIsDead`).
- Settings with no effect: `screenshots.messages.tracer`. `HookEvent` stores `pcall`'s status (always
  `true`), not the condition's result, so "Screenshot Taken/Failed" is always printed.
- Other bugs:
  - screenshots: `"Time: " .. encounterTime` errors when `ENCOUNTER_START` was missed (`/reload`
    mid-fight); `math.ceil` minutes (90 s → "2 minutes 30 seconds").
  - interrupts: the chat channel is only recomputed on `PLAYER_ENTERING_WORLD`, not on group changes.
  - portals: `CreateButton` creates secure buttons from a `ChallengesFrame:Update` hook with no combat
    check.
- Game flag where a family/feature is meant: merchant `E.isStandard` (Forever has
  `C_MerchantFrame.SellAllJunkItems` but takes the bag loop). The submodules' own flags are covered
  above. No other misc flags.

**Observed (API docs / Blizzard source, 6 clients):**

| Feature | Retail · Forever | Era · TBC · Wrath · MoP | Secrets / restrictions / Edit Mode |
|:--|:--|:--|:--|
| Dispels, interrupts | **Can't work.** Public `C_CombatLog` has no `GetCurrentEventInfo`. It exists only in `C_CombatLogSecure` (`SecureOnly`) and `C_CombatLogInternal`. CLEU is `HasRestrictions`. `C_DamageMeter` has `Interrupts`/`Dispels` types, but they are aggregates per source and spell (`SecretWhenInCombat`), with no target, no interrupted/dispelled spell and no per-event signal, so it can't replace the announcer. Blizzard's damage meter already counts both. | Work today (`C_CombatLog.GetCurrentEventInfo` public). Dispels has data only for MoP instances (and unsupported Cata), so on Era/TBC/Wrath it listens to CLEU in every instance and never announces. | `SendChatMessage` comes only from `Blizzard_DeprecatedChatInfo` (guarded by `loadDeprecationFallbacks`) on all 6, so it errors with the fallbacks off. `C_ChatInfo.SendChatMessage` is documented on all 6. |
| Screenshots | All events and APIs documented; encounter payloads, `Screenshot` have no secret flags | same; achievements gated to Wrath+, challenge mode to MoP+ | none; no Edit Mode |
| Merchant | repair globals in Blizzard `MerchantFrame` on both; `C_MerchantFrame.SellAllJunkItems` on both (Blizzard only has a button, no auto) | repair globals present; no `C_MerchantFrame` | `_G.GetItemInfo` is a deprecation fallback on all 6 (`C_Item.GetItemInfo` exists everywhere) |
| Threat bar | `UnitDetailedThreatSituation` `SecretWhenUnitThreatValuesRestricted`; predicate `C_Secrets.ShouldUnitThreatValuesBeSecret(unit, mob)` on both. Ours tests `status` and does arithmetic, so it errors when secret. ElvUI hides its bar when `status` is secret. Anchor frame exists (datatexts on all clients). | works today | — |
| Auto keystone | Retail only: `Blizzard_ChallengesUI` loads for `standard, mists` (not Forever). Blizzard never auto-slots (drag/click → `C_ChallengeMode.SlotKeystone`). `C_Container.UseContainerItem` has no restriction flag. | MoP ChallengesUI has no keystone frame; Era/TBC/Wrath none | auto-slotting through `UseContainerItem` on 12.x is unverified |
| Dungeon portals | Retail: `ChallengesFrameMixin:Update` and `.maps` exist; Retail ChallengesUI has no teleport buttons (spellbook flyouts only). Forever: no ChallengesUI. | MoP: `ChallengesFrame` has no `Update` method (different UI); MoP challenge-mode teleports exist but aren't proposed | `IsSpellKnown` is a deprecation fallback (`C_SpellBook.IsSpellKnown`); `C_Spell.GetSpellCooldown` `SecretWhenCooldownsRestricted` (`info.isEnabled` test); data is TWW S3, Midnight dungeons missing (map IDs unverified) |
| Skyriding race | Retail content only (Forever has none). Data is TWW races only. | none | `C_UnitAuras.*` `SecretWhenUnitAuraRestricted`: `RACES[data.spellId]` indexes with a secret in combat in instances and PvP (UNIT_AURA is always processed). Whether Blizzard's race widget already shows the gold-time countdown is unverified. |

`[AllowLoadGameType standard]` loads only on Retail. Every client's Blizzard TOCs use the
`standard` token, so all 6 recognize it.

Unverifiable without the game: CLEU announcements on Classic after the chat-API change; the threat
predicate on Retail in open world vs instances; keystone auto-slot on 12.x; Midnight portal map IDs and
spells; Blizzard race widget content; MoP dispel instance IDs.

**Recommended (per feature):**

| Feature | Recommendation | Risk |
|:--|:--|:--|
| Merchant | fix + enable on all 6 | low; Classic sells via `UseContainerItem` out of combat (unchanged) |
| Screenshots | fix + enable on all 6 | low |
| Threat bar | fix (secret-safe, event-driven) + enable on all 6 | medium on Retail (secret predicate unverified in-game) |
| Auto keystone | fix + enable on Retail (`standard`) | low |
| Dungeon portals | fix + enable on Retail (`standard`) | medium: secure buttons, data upkeep per season |
| Interrupts | keep Classic-only, fix chat API | Retail/Forever impossible, no replacement (Blizzard damage meter counts interrupts, doesn't announce) |
| Dispels | keep Classic-only, fix chat API; scope on Era/TBC/Wrath is a decision | same as interrupts |
| Skyriding race | fix + enable on Retail, or drop (decision) | data upkeep each expansion; Blizzard overlap unverified |

Nothing is a forced drop. No Blizzard entry point is removed by any step.

**Loading and startup:**
- Per-line TOC tags replace all three misc XMLs. The submodules keep their own `init.xml`: it is their
  standalone entry point, and the TOC includes it. Their duplicate client flags are deleted upstream,
  not replaced: no reader is left. Step 1, first in the order.
- Startup: all eight use their own frames. Each feature is its own frame with its own handler, so one
  failing feature doesn't stop the others (unlike Blizzard tweaks before item 7 step 2). No feature
  needs to move to the registry. The threat bar's only cross-module need (the datatext frame) is
  resolved at `PLAYER_ENTERING_WORLD`, after `InitModules`. File-level `C` reads remain an item 12 concern.

**Recommended steps** (`make check` after each; Classic regressions checked on Era first; submodule
steps = upstream commit + pointer bump by the maintainer):

1. **TOC lines instead of XML** · Done, pending in-game verification · Depends on: —
   - Change: replace the commented `init.xml` line and the `init_classic.xml`/`init_mists.xml` lines
     with one line per file in the current order, tagged `[AllowLoadGameType classic]` (the union):
     `dispels\init.xml`, `interrupts\init.xml`, `screenshots\init.xml`, `settings.lua`, `merchant.lua`,
     `threatbar.lua`. Delete the three misc XMLs. `auto_keystone`, `dungeon_portals` and
     `skyriding_race` get no line yet.
   - Clients: Era, TBC, Wrath, MoP (no behavior change).
   - Test: `/reload` on Era and MoP; merchant repairs/sells; threat bar in combat; a level-up or death
     screenshot; an interrupt in a group announces; no errors.
2. **Announcers: chat API and dead code** (submodules `dispels`, `interrupts`) · Done, pending in-game verification · Depends on: 1
   - Change: `C_ChatInfo.SendChatMessage`. Dispels: drop the `isRetail…isMoP` flags, the Retail
     `spells[0]` branch and unused locals/fields. Interrupts: drop `ns.Interrupts = Interrupts` and
     recompute the chat type on `GROUP_ROSTER_UPDATE`.
   - Clients: Era, TBC, Wrath, MoP.
   - Test: with `loadDeprecationFallbacks` off and on: interrupt in party (PARTY), raid (RAID), dungeon
     (SAY), pet interrupt (hunter/warlock), joining a group after zoning; MoP dungeon dispel of a listed
     aura announces; no errors.
3. **Screenshots: fixes, all clients** (submodule + TOC) · Done, pending in-game verification · Depends on: 1
   - Change: options are flat fields on `ns.ScreenShots` (oUF element style), read once at
     `PLAYER_LOGIN`; `SetOptions`, the merge, `Disable` and `enabled` removed, which also fixes the tracer
     condition. `settings.lua` sets the fields from a flat `C.miscellaneous.screenshots`. Nil-safe
     encounter time; `math.floor` minutes; drop the debug `print` and client flags. Submodule TOC
     Interface for all 6, `.luacheckrc` and `make check`. Retag `screenshots\init.xml` and
     `settings.lua` untagged.
   - Clients: all 6.
   - Test: level up (Era), death with `dead = true` (temporarily), boss kill outdoors (`BOSS_KILL`),
     dungeon boss kill and wipe (`ENCOUNTER_END`), `/reload` mid-encounter then kill (no error),
     achievement (Wrath+/Retail), M+ completion (Retail), no "Screenshot Taken" line with `tracer = false`.
4. **Merchant on all clients** · Done · Depends on: 1
   - Change: `C_Item.GetItemInfo`; `C_Container.*` without global fallbacks; sell-all-junk branch on
     `C_MerchantFrame and C_MerchantFrame.SellAllJunkItems` instead of `E.isStandard`; fix the
     shadowed `itemLink`. Untag `merchant.lua`.
   - Clients: all 6.
   - Test: merchant open with junk and damaged gear on Era (fallbacks off), MoP, Retail, Forever;
     not enough money message; merchant without repair; Retail with Blizzard's sell-all-junk disabled.
5. **Threat bar: events instead of polling** · Done, pending in-game verification · Depends on: 1
   - Change: update on `UNIT_THREAT_LIST_UPDATE`/`UNIT_THREAT_SITUATION_UPDATE`/`PLAYER_TARGET_CHANGED`
     while in combat instead of the 0.75 s `OnUpdate`; drop `UnitIsDead`; unnamed frame if nothing
     references `TaintedThreatBar` (none found).
   - Clients: Era, TBC, Wrath, MoP.
   - Test: solo and party combat; target switch mid-combat; pet battle (MoP, hidden); death and
     leaving combat hide it; covers the right datatext strip only in combat.
6. **Threat bar on mainline** · Done, pending in-game verification · Depends on: 5
   - Change: hide the bar when `C_Secrets.ShouldUnitThreatValuesBeSecret("player", "target")` is true
     (or `status` is secret), as ElvUI does; untag `threatbar.lua`.
   - Clients: Retail, Forever.
   - Test: open-world combat shows %, color and target name; dungeon, M+, raid boss and PvP: no
     secret-value errors (bar hidden where values are secret); Edit Mode open/close.
7. **Auto keystone on Retail** · Depends on: 1
   - Change: `C_Item.GetItemInfoInstant` (as `core/keystone.lua`); unnamed frame; TOC line
     `[AllowLoadGameType standard]`.
   - Clients: Retail.
   - Test: open the font of power with a key in bags (slotted), without a key (nothing), after
     `/reload` with the UI already loaded; no taint when starting the key.
8. **Dungeon portals on Retail** · Depends on: 1
   - Change: `C_SpellBook.IsSpellKnown`; create buttons only out of combat (defer to
     `PLAYER_REGEN_ENABLED`); secret-safe cooldown (skip when secret, or duration object; unverified
     which API applies); Midnight season dungeons in the table, missing-spell entries removed instead
     of printing; TOC line `[AllowLoadGameType standard]`.
   - Clients: Retail.
   - Test: Mythic+ tab opened out of combat and first opened in combat; click a known portal (casts),
     unknown portal (desaturated); cooldown sweep after use; sort by score; opening inside an M+ key.
9. **Skyriding race** (decision below) · Depends on: 1
   - Change (if kept): skip secret `spellId`, Midnight races added, dead stopwatch/`FilterAura`/`oUF`/`changed`
     removed, TOC line `[AllowLoadGameType standard]`. If dropped: delete the file and
     `C.miscellaneous.skyriding_race`.
   - Clients: Retail.
   - Test: start a TWW and a Midnight race (Normal, Advanced, Reverse), finish, fail, leave the start
     area; combat in a dungeon with the tracker loaded (no secret errors).
10. **Done** · Depends on: 1–9
    - Change: §1, §4, §5, §6 and compatibility.md "Current status" (miscellaneous per client).
    - Test: `/reload` on all 6 with `loadDeprecationFallbacks` off; taint log clean after combat on
      Retail and MoP.

**Needs confirmation:**
- Submodules: fix upstream and bump pointers (proposed), or vendor them into Tainted?
- Dispels on Era/TBC/Wrath: it never announces there (no data). Tag it `mists` only, add Classic
  data, or keep as is?
- Threat bar on Retail: hide while threat is secret (proposed), or render secret values (bar value
  and text accept them; color would need a curve)?
- Dungeon portals: accept the per-season data upkeep?
- Skyriding race: keep and maintain the race data, or drop?

### 11. Final compatibility audit

**Done when:**
- Every module loads on every client it's meant for.
- `make check` is clean of real bugs.
- This plan is up to date.

### 12. Extension by other addons

**Status:** Not started · **Priority:** Low · **Depends on:** 11

**Objective:** a separate addon with `## Dependencies: Tainted` can customize Tainted in code (like a
Tukui edit addon) and could later provide an in-game configuration. Tainted itself stays
configuration-free; any options UI or SavedVariables would live in that other addon.

**Done when:** an edit addon can change `C` settings and restyle or move Tainted frames without
editing Tainted's files, and this contract is documented.

**Observed (code):**
- Only the engine is global: `core/init.lua` sets `_G[addon] = frame` (`Tainted` = `E`). `C`, `A`, `L`
  and `P` exist only in the private `ns`, so an outside addon can't read or change settings.
  Tukui exports its whole namespace (`Tukui = Engine`, `Tukui:unpack()` → T, C, L, …,
  `Core/Init.lua`).
- A dependent addon's files run after all of Tainted's files and before `PLAYER_LOGIN`
  (`E:InitModules`). A `C` change made then reaches code that reads `C` in `Init` or later, but not
  file-level reads: the early returns (`if not C.x then return end`) in tooltips, maps, chat history,
  Blizzard tweaks and miscellaneous modules, plus any `C` values copied into file locals.
- `E:CreateModule`/`E:GetModule`/`E:Call` already work through `_G.Tainted`; a dependent module is
  initialized and isolated by `E:InitModules`.

**Needs confirmation:**
- Export `C`/`A`/`L` (and `P`?) through `_G.Tainted`, Tukui-style, or only `C`?
- Which `C` reads move from file load to `Init` so an edit addon can change them; every one, or only
  the documented ones?
- Is an in-game configuration addon compatible with §6 "No in-game configuration" when it's a
  separate, optional addon?

## 4. Known architectural risks (observed)

- **Ambiguous client flags.** Renamed in item 0 (`isRetail` → `isStandard`, `isClassic` →
  `isVanilla`, `isMoP` → `isMists`, `isForever` → `isCamelot`), and family flags
  `isMainline`/`isClassic` added. Items 1–9 moved their call sites to family flags or feature
  detection; the game flags left in unit frames are game content (nameplate max distance,
  `showPet` on Era, MoP layout and colors). Item 10: only merchant (`E.isStandard` for a feature
  check), step 4.
- **Implicit dependencies.** Modules find each other's frames by global name and rely on TOC
  order (chat/minimap → datatexts).
- **Core does module work.** It triggers the chat reset (action-bar settings moved out in item 4).
- **Two startup models.** Some modules use the registry `Init`. About 15 others create their own
  frame and initialize on login. Errors in the second group aren't isolated.
- **Secret values / restricted APIs on Midnight.** Auras (item 5), tooltips (item 6) and unit-frame
  tags and elements (item 9) are handled. The combat log (CLEU) isn't readable by addons on
  Retail/Forever, so dispels/interrupts stay Classic-only; threat bar and skyriding race are item 10
  steps 6 and 9. Open unit-frame
  cases are in item 9's Unverified list.
- **Pixel scale timing.** It is computed at file load, before UI scale is applied at login.
  Unverified.

## 5. Deferred work (don't fix early)

- Dead stubs (`development.lua`, `event_trace.lua`): remove during
  item 11.
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
- Item 8: real bag frames on all clients, plus a bank window and sort on Classic/MoP (see item 8 → Decided).

**Needs confirmation:**
- Item 0: one startup model for all modules, or keep both and document them?
- Item 2 vs 4: which comes first on Retail, chat or action bars?
- Item 10: submodules, dispels scope, threat bar on Retail, portals upkeep, skyriding race (see item 10).
- Item 12: what to export, when `C` is read, and whether a separate in-game configuration addon is allowed (see item 12).

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
- [x] 7. Blizzard UI tweaks (pending in-game verification)
  - [x] 1. TOC lines instead of XML
  - [x] 2. Isolated tweak init
  - [x] 3. Framerate + talking head on mainline
  - [x] 4. Mirror timers
  - [x] 5. Experience cleanup
  - [x] 6. Experience on mainline
  - [x] 7. House favor bar (tracked-house data unverified)
  - [x] 8. Queue status
  - [x] 9. Ghost
  - [x] 10. UI widgets (pending in-game verification)
  - [x] 11. Durability (verified on MoP)
  - [x] 12. Objective tracker anchor on mainline (verified on MoP, Retail and Era)
  - [x] 13. Raid utility
  - [x] 14. Done (pending in-game verification)
- [x] 8. Bags (pending in-game verification)
  - [x] 1. Bag window
  - [x] 2. Slot presentation and updates
  - [x] 3. Client extras
  - [x] 4. Classic bank
  - [x] 5. Classic sort
- [x] 9. Unit frames (pending in-game verification)
  - [x] 1. Nameplate artwork (classic family)
  - [x] 2. Retail unit-frame auras (verified on Retail)
  - [x] 3. Retail raid auras (verified on Retail)
  - [x] 4. Retail drift fixes (verified on Retail)
  - [x] 5. Plugins (pending in-game verification)
  - [x] 6. Healer raid position
  - [x] 7. Forever and family flags
  - [x] 8. Cleanup
  - [x] 9. oUF_Merge: Era, TBC, WotLK
  - [x] 10. oUF_Merge: MoP
  - [x] 11. Short values
  - [x] 12. DK rune types
  - [x] 13. oUF_Classic: Retail callbacks, colors and factory
  - [x] 14. Classic AdditionalPower
  - [x] 15. oUF_Classic: Retail prediction
  - [x] 16. Classic totems
  - [x] 17. Threat indicator (pending in-game verification)
  - [x] 18. Done (pending in-game verification)
- [ ] 10. Miscellaneous
  - [x] 1. TOC lines instead of XML (pending in-game verification)
  - [x] 2. Announcers: chat API and dead code (pending in-game verification)
  - [x] 3. Screenshots: fixes, all clients (pending in-game verification)
  - [x] 4. Merchant on all clients
  - [x] 5. Threat bar: events instead of polling (pending in-game verification)
  - [x] 6. Threat bar on mainline (pending in-game verification)
  - [ ] 7. Auto keystone on Retail
  - [ ] 8. Dungeon portals on Retail
  - [ ] 9. Skyriding race
  - [ ] 10. Done
- [ ] 11. Final compatibility audit
- [ ] 12. Extension by other addons
