# Compatibility

Authoritative for clients, TOC loading, oUF variants, secret values and decisions; other docs link here.

## Supported clients

One `Tainted.toc` (`## Interface: 11509, 20506, 38002, 50504, 120105, 16001`):

| Client          | Interface | Game type  | Family     | oUF                |
|:----------------|:----------|:-----------|:-----------|:-------------------|
| Retail/Midnight | `120105`  | `standard` | `mainline` | `libs\oUF`         |
| Classic Forever | `16001`   | `camelot`  | `mainline` | `libs\oUF`         |
| Classic Era     | `11509`   | `vanilla`  | `classic`  | `libs\oUF_Classic` |
| Classic TBC     | `20506`   | `tbc`      | `classic`  | `libs\oUF_Classic` |
| Classic WotLK   | `38002`   | `wrath`    | `classic`  | `libs\oUF_Classic` |
| Classic MoP     | `50504`   | `mists`    | `classic`  | `libs\oUF_Classic` |

- WotLK is Titan 3.80.x (`Wrath` flavor, `WOW_PROJECT_WRATH_CLASSIC`), not retired 3.4.x; don't assume
  3.4.x behavior. Cata is not supported.

## TOC rules

- No `Tainted_*.toc`: a suffixed TOC overrides `Tainted.toc` on its client.
- Shared files untagged; client-specific lines tagged `[AllowLoadGameType ...]` with a family
  (`mainline`, `classic`) or game types (`vanilla, tbc, wrath`, `mists`). One ordered list.
- Unrecognized condition tokens count as satisfied: a `camelot`-only line also needs
  `[ExcludeLoadGameType standard, classic]`.
- Per-game metadata (`## OptionalDeps`) uses the same suffix.
- `[Game]`/`[Family]` path variables work everywhere but are unused: variants are named files
  (`init_classic.xml`, `init_mists.xml`) split by oUF variant, and inline branches still need flags.

## Current status

Every module loads on all 6 clients except lines tagged in `Tainted.toc`. Non-obvious mechanisms:

- Tooltips: data post-calls where `GameTooltip.ProcessInfo` exists (Retail, Forever), `OnTooltipSet*`
  hooks elsewhere.
- Player auras: `SecureAuraHeaderTemplate` on Classic (`modules/auras/classic`); mainline uses Blizzard's
  `AuraContainer` (`modules/auras/mainline`), which renders secret values itself.
- Datatexts: an element's `Enable` returns `true` only if it can run on the client.
- Blizzard tweaks: feature detection (`MirrorTimerContainer`, `QueueStatusButton`, `C_Housing`,
  experience APIs). Frames are re-anchored from `SetPoint` hooks with `ClearAllPointsBase`/`SetPointBase`,
  never by replacing methods. Wrath/MoP `WatchFrame` is reparented to `UIParent` to leave the right
  managed container.
- Threat bar hides while threat values are secret (Retail, Forever). Merchant uses
  `C_MerchantFrame.SellAllJunkItems` where it exists, the bag loop elsewhere.
- Dispels/interrupts are `classic`-only: addons can't read the combat log on Retail/Forever. Auto
  keystone, dungeon portals and `core\keystone.lua` are `standard`-only. Skyriding race is the
  standalone `Skyriding` addon.
- Install sets `taintLog` to 0 on Retail and to the `C.general.taintLog` level elsewhere: on Retail (12.0.5)
  turning it on mid-session breaks frame-method `hooksecurefunc` hooks until `/reload` (client bug,
  reproduces with no addons; #13). For a Retail taint log: `/console taintLog 1`, then `/reload`.

## Decisions

Agreed during the rebuild; don't re-litigate without a new reason.

- **General:** feature detection first; a client flag only where nothing can be tested. Submodules
  (`dispels`, `interrupts`, `screenshots`) are fixed upstream, then the pointer is bumped.
- **Minimap:** 198 on mainline (Blizzard default), 180 on classic. Maps and Minimap are two registry
  modules. Datatexts run on every client so the strip is never empty.
- **Chat:** one shared implementation. Right chat = first undocked, non-temporary frame
  (`ChatFrame2..max`), no saved ID. Window 3 (Voice) is Blizzard's. Chat owns the first-run reset.
- **Action bars:** `countdownForCooldowns` stays in the Core install. Bars 6–8 always exist, off via
  `C.actionbars.bar6/7/8`. Backgrounds follow their Blizzard bar. Main-bar paging is Blizzard's.
- **Auras:** secret timers show raw seconds (`TruncateWhenZero`), plain ones `E.FormatTime`.
- **Tooltips:** spell/aura IDs always, NPC ID Shift-only, Era vendor-price line, Blizzard comparison
  anchoring. Nothing more (pet-battle, talent, recipe, azerite, conduit, totem ID hooks dropped).
- **Blizzard tweaks:** experience keeps every bar that can have data (Azerite, Artifact, Anima, house
  favor on Retail). Objective tracker: Tainted anchor on mainline, Edit Mode fallback. Durability below
  the minimap strip (`C.blizzard.durability`). Ghost uses the taxi button's anchor (Retail, Forever,
  MoP); talking head Retail/Forever. Raid utility dropped (Blizzard `/wm`, `/readycheck`, keybinds);
  unit frames hide the raid manager.
- **Bags:** one implementation; clients differ only in data (bag IDs, sort, Classic bank and bag-slot
  strip). Blizzard slot templates, nothing secure. Classic shows Blizzard's own container-frame item
  buttons (their frames become invisible holders): addon-created slots run the template's inline
  `OnClick` tainted and can't use items in combat. The Classic bank container keeps Tainted buttons.
  Toggles hooked, never replaced. `BAG_UPDATE` marks
  a bag dirty, `BAG_UPDATE_DELAYED` refreshes only dirty bags; a hidden window catches up on show.
  Non-goals: mainline/warband/reagent bank, item level, junk/new markers, categories, currencies, movers.
- **Classic sort:** hearthstone, class, subclass (desc), equip slot, quality (desc), name, ID, full
  stacks first; junk fills from the end; special bags take fitting items first. Never starts in combat;
  `PLAYER_REGEN_DISABLED`/`BANKFRAME_CLOSED` stop it. Keyring never sorted. `C.bags.sort_bank` sorts
  the open bank separately.
- **Unit frames:** plugins (Atonement, AuraTrack, RaidDebuffs) may be edited;
  oUF_Tempest is out of scope. The Atonement bar is created on no client (spell-ID aura lookups are
  secret on Retail/Forever). Healer position: `C.unitframes.raid.healer`, role override `E.db.role`.
  Unit-frame code is shared, Retail oUF is the reference; a remaining difference is a capability
  check, not a client flag. AlternativePower on every client. Adapter ports skipped: castbar duration
  objects, colour curves, range without polling, Auras shim.
- **Raid auras:** Retail/Forever use oUF `Auras` groups with Blizzard filters. Buffs:
  `BIG_DEFENSIVE`, `EXTERNAL_DEFENSIVE`, own `RAID_IN_COMBAT` HoTs. Debuffs: `RAID_PLAYER_DISPELLABLE`,
  boss, `CROWD_CONTROL`, `IMPORTANT`. Classic keeps AuraTrack and RaidDebuffs.
- **Miscellaneous:** dispels on all Classic clients with per-client data; dungeon portals accept
  per-season data upkeep.

## oUF variants

- `libs/oUF` (Retail, read-only): `colors.debuff` is `colors.dispel`. `AddGroup` groups aren't
  exclusive (later groups need `!` negations); spell-ID filters are ignored for debuffs on friendly units.
- `libs/oUF_Classic` (branch `classic`): Era, TBC, WotLK, MoP. Retail `master` plus small Classic
  commits; shims live in `compat.lua`, game content is gated by master's `GameVersion`. Public flags
  for plugins keep the legacy names: `oUF.isRetail`, `isClassic` (Era only), `isTBC`, `isWrath`,
  `isCata`, `isMoP`. ClassPower `PostUpdate` uses the Retail signature. Mirrors Retail: frames set
  `__unit`/`__realUnit` and `__unitIndex` (number), never `frame.unit`; Target, Phase, Summon and
  PvPClassification indicators are the Retail elements (no `oUF_TargetIndicator` plugin). `Auras` is
  the button-based Buffs/Debuffs element (no container, no `AddGroup`); dispel colour keys come from
  `AuraUtil` (`None` for undispellable). QuestIndicator loads but never enables (`UnitIsQuestBoss`
  absent); selection colour comes from `UnitSelectionColor`. So nameplate health colour
  (`units/nameplate.lua`) is the one remaining oUF-variant branch.

## Runtime client checks

Flags in `core/init.lua`, named after [TOC](https://warcraft.wiki.gg/wiki/TOC_format) game types/families:

- Game type (exact `WOW_PROJECT_ID`; Forever is `WOW_PROJECT_CAMELOT`, not mainline): `E.isStandard`,
  `E.isCamelot`, `E.isVanilla`, `E.isTBC`, `E.isWrath`, `E.isCata`, `E.isMists`, `E.isPlunderstorm`.
- Family: `E.isMainline`, `E.isClassic`.
- Family flags for API/UI differences; game flags only for game content (spells, talents, one client's
  frames). Remaining game-flag uses are content: Era vehicles, haste and pet happiness, MoP stances and
  keyring, Retail nameplate distance and currencies, install CVar defaults.
- The oUF variant has no flag: code depending on it goes in files tagged like the oUF line, or checks
  the matching game flags, or checks for a method defined only in such a file (`raid.lua`:
  `CreateRaidAuras`) or for the API itself (`indicators.lua`: `UnitIsQuestBoss`).
- `ChatFrame_*`, `SendChatMessage`, `GetItemInfo`, `IsSpellKnown`, `GetSpecialization`,
  `GetWeaponEnchantInfo` exist only via `loadDeprecationFallbacks`; use the `C_*` API.

## Secret values (Midnight / Retail)

- Secret values allow no arithmetic, comparison, string operations or table keys.
- Check the target client's generated API docs (`Blizzard_APIDocumentationGenerated`, see
  [references.md](references.md)) before using a result in logic; APIs and secret flags differ per client.
- Tags and aura features are most likely affected. Audit before fixing.
- Predicates: `C_Secrets.ShouldAurasBeSecret` (tainted `GetAuraDuration`/`GetAuraDataByIndex` error
  while true), `ShouldUnitStatsBeSecret`, `ShouldUnitThreatValuesBeSecret`.
- `AbbreviateNumbers` accepts secret numbers on Retail/Forever and returns a secret string.
- Nothing may anchor to an `AuraContainer` ("dependent object would inherit forbidden aspects").
