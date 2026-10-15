# Compatibility

Authoritative for supported clients, TOC loading, oUF variants, secret values and agreed design decisions.
Other docs link here instead of repeating these facts.

## Supported clients

A single `Tainted.toc` serves every supported client (`## Interface: 11509, 20506, 38002, 50504, 120105, 16001`):

| Client          | Interface | Game type  | Family     | oUF                |
|:----------------|:----------|:-----------|:-----------|:-------------------|
| Retail/Midnight | `120105`  | `standard` | `mainline` | `libs\oUF`         |
| Classic Forever | `16001`   | `camelot`  | `mainline` | `libs\oUF`         |
| Classic Era     | `11509`   | `vanilla`  | `classic`  | `libs\oUF_Classic` |
| Classic TBC     | `20506`   | `tbc`      | `classic`  | `libs\oUF_Classic` |
| Classic WotLK   | `38002`   | `wrath`    | `classic`  | `libs\oUF_Classic` |
| Classic MoP     | `50504`   | `mists`    | `classic`  | `libs\oUF_Classic` |

- WotLK is Titan 3.80.x (loads the `Wrath` flavor with `WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC`),
  not the retired 3.4.x Wrath Classic. Don't assume 3.4.x behavior.
- Cata is not supported.

## TOC rules

- Do not add client-specific TOCs (`Tainted_*.toc`); a suffixed TOC overrides `Tainted.toc` on its client.
- Shared files are untagged. Client-specific files are tagged per line with
  `[AllowLoadGameType ...]`, using the family (`mainline`, `classic`) or game types
  (`vanilla, tbc, wrath`, `mists`). Keep one ordered list; place variants where they load.
- `[Game]`/`[Family]` path variables are not used: variants are named files (`init_classic.xml`,
  `init_mists.xml`), not `<Game>\` directories.
- A condition whose tokens the client doesn't recognize is treated as satisfied. A `camelot`-only
  line would therefore also need `[ExcludeLoadGameType standard, classic]` (as ElvUI does).
- Per-game metadata (`## Title`, `## OptionalDeps`) uses the same `[AllowLoadGameType ...]` suffix.

## Current status

- Every module loads on all 6 clients; the exceptions are tagged per line in `Tainted.toc` and
  listed below. Bags and action bars load on all clients (bag bank and sort are
  `classic`-tagged).
- Core: `core\keystone.lua` (keystone and weekly-reward tracking) is `standard`-tagged.
- Chat loads on all clients (one shared implementation, no per-client files).
- Datatexts load on all clients. An element's `Enable` returns `true` only if it can run on
  the client.
- Tooltips load on all clients: tooltip data post-calls where `GameTooltip.ProcessInfo` exists
  (Retail, Forever), `OnTooltipSet*` hooks elsewhere.
- Player auras: `SecureAuraHeaderTemplate` only exists on Classic (`modules/auras/classic`);
  mainline uses Blizzard's `AuraContainer` (`modules/auras/mainline`), which renders secret values itself.
- Blizzard tweaks load on all clients, except ghost (`GhostFrame`: Retail, Forever, MoP) and
  talking head (Retail, Forever). Branches use feature detection (`MirrorTimerContainer`,
  `QueueStatusButton`, `C_Housing`, experience bar APIs), not client flags. Blizzard frames are
  re-anchored from `SetPoint` hooks with `ClearAllPointsBase`/`SetPointBase` (durability,
  mainline objective tracker), never by replacing their methods. Wrath/MoP `WatchFrame` is
  reparented to `UIParent` to leave the right managed container.
- Miscellaneous: merchant, screenshots and threat bar load on all clients. The threat bar hides
  while threat values are secret (Retail, Forever); merchant sells junk with
  `C_MerchantFrame.SellAllJunkItems` where it exists, the bag loop elsewhere. Dispels and
  interrupts are `classic`-tagged: addons can't read the combat log on Retail/Forever. Auto
  keystone and dungeon portals are `standard`-tagged (Retail `Blizzard_ChallengesUI`). Skyriding
  race is the standalone `Skyriding` addon.

## Decisions

Agreed during the rebuild; don't re-litigate without a new reason.

- **General:** feature detection first; a client flag only where nothing can be tested. Submodules
  (`dispels`, `interrupts`, `screenshots`) are fixed upstream, then the pointer is bumped.
- **Minimap:** 198 on mainline (Blizzard default), 180 on classic. Maps and Minimap stay two registry
  modules. Datatexts run on every client so the strip is never empty.
- **Chat:** right chat = first undocked, non-temporary frame (`ChatFrame2..max`), no saved ID. Window 3
  (Voice) is left to Blizzard. Chat owns the first-run reset.
- **Action bars:** `countdownForCooldowns` stays in the Core install. Bars 6–8 always exist, off via
  `C.actionbars.bar6/7/8`. Backgrounds follow their Blizzard bar. Main-bar paging is Blizzard's.
- **Auras:** secret timers show raw seconds (`TruncateWhenZero`), plain ones `E.FormatTime`.
- **Tooltips:** spell/aura IDs always on, NPC ID Shift-only, Era vendor-price line kept, Blizzard's
  comparison anchoring. No content beyond that (pet-battle, talent, recipe, azerite, conduit and totem
  ID hooks dropped).
- **Blizzard tweaks:** experience keeps every bar that can have data (Azerite, Artifact, Anima, house
  favor on Retail). Objective tracker uses a Tainted anchor on mainline; the fallback is Edit Mode.
  Durability sits below the minimap strip (`C.blizzard.durability`). Raid utility dropped (Blizzard
  `/wm`, `/readycheck`, keybinds); unit frames hide the raid manager. Ghost uses the taxi button's anchor.
- **Bags:** one implementation; clients differ only in data (bag IDs, sort, Classic bank and bag-slot
  strip). Slots use Blizzard templates and nothing is secure. Toggles are hooked, never replaced.
  `BAG_UPDATE` marks a bag dirty and `BAG_UPDATE_DELAYED` refreshes only dirty bags; a hidden window
  catches up on show. Non-goals: mainline/warband/reagent bank, item level, junk/new markers,
  categories, currencies, movers.
- **Classic sort:** hearthstone, class, subclass (desc), equip slot, quality (desc), name, ID, full
  stacks first; junk fills from the end. Special bags take the items that fit them first. No start in
  combat; `PLAYER_REGEN_DISABLED`/`BANKFRAME_CLOSED` stop a running sort. The keyring is never sorted.
  `C.bags.sort_bank` sorts the open bank separately.
- **Unit frames:** plugins (Atonement, AuraTrack, RaidDebuffs, TargetIndicator) may be edited;
  oUF_Tempest is out of scope. The Atonement bar is created on no client (spell-ID aura lookups are
  secret on Retail/Forever). Healer position: `C.unitframes.raid.healer`, role override in `E.db.role`.
- **Raid auras:** Retail/Forever use oUF `Auras` groups with Blizzard filters. Buffs:
  `BIG_DEFENSIVE`, `EXTERNAL_DEFENSIVE`, own `RAID_IN_COMBAT` HoTs. Debuffs: `RAID_PLAYER_DISPELLABLE`,
  boss, `CROWD_CONTROL`, `IMPORTANT`. Classic keeps AuraTrack and RaidDebuffs.
- **Miscellaneous:** dispels on all Classic clients with data per client; dungeon portals accept
  per-season data upkeep.

## oUF variants

- `libs/oUF`: Retail oUF, fork of upstream. **Read-only** — work around problems in Tainted
  and report/document them. Updates are handled by the maintainer.
- `libs/oUF_Classic`: branch `classic`, one oUF for Era, TBC, WotLK and MoP (game content gated
  by `oUF.isMoP`); ClassPower `PostUpdate` uses the Retail oUF signature. Fixes allowed
  when needed.
- Retail oUF sets `frame.__unit`, not `frame.unit`; `colors.debuff` is `colors.dispel`. `AddGroup`
  groups are not exclusive (later groups need `!` negations), and spell-ID filters are ignored for
  debuffs on friendly units.

## Runtime client checks

Flags in `core/init.lua` are named after the TOC game types and families
([TOC format](https://warcraft.wiki.gg/wiki/TOC_format)):

| Kind      | Flags                                                                                          | Meaning                                         |
|:----------|:-----------------------------------------------------------------------------------------------|:------------------------------------------------|
| Game type | `E.isStandard`, `E.isCamelot`, `E.isVanilla`, `E.isTBC`, `E.isWrath`, `E.isCata`, `E.isMists`, `E.isPlunderstorm` | exact `WOW_PROJECT_ID` (Forever is `WOW_PROJECT_CAMELOT`, not `WOW_PROJECT_MAINLINE`) |
| Family    | `E.isMainline`, `E.isClassic`                                                                   | TOC `mainline` / `classic` families             |

- Use family flags for API/UI-family differences; game flags only for game-specific content
  (spells, talents, a single client's frames).
- The oUF variant has no runtime flag: the TOC picks it. Code that depends on the oUF variant
  belongs in files tagged like the oUF line, or checks the game flags that match it.
- The game flags left in the code are game content (Era vehicles, haste and pet happiness, MoP
  stances and keyring, Retail nameplate distance and currencies, install CVar defaults), not
  families.
- TOC path variables (`[Game]`, `[Family]`) work on all supported clients but are not used:
  variants split by oUF variant, not by game or family, and inline branches still need flags.
- Deprecated globals (`ChatFrame_*`, `SendChatMessage`, `GetItemInfo`, `IsSpellKnown`,
  `GetSpecialization`, `GetWeaponEnchantInfo`) exist only through `loadDeprecationFallbacks`; use the
  `C_*` API.

## Secret values (Midnight / Retail)

- Some APIs return "secret" values: no arithmetic, comparison, string operations or table keys
  on them.
- Before using an API result in logic, check the generated API docs
  (`Blizzard_APIDocumentationGenerated`, see [reference-repositories.md](reference-repositories.md))
  for the target client; APIs and secret flags differ per client.
- If unsure whether a function returns secrets or is restricted, say so. Don't guess.
- Tags and aura-based features are the most likely to be affected. Audit before fixing.
- Predicates used: `C_Secrets.ShouldAurasBeSecret` (tainted `GetAuraDuration`/`GetAuraDataByIndex`
  error while true), `ShouldUnitStatsBeSecret`, `ShouldUnitThreatValuesBeSecret`.
- `AbbreviateNumbers` accepts secret numbers on Retail/Forever and returns a secret string.
- Nothing may anchor to an `AuraContainer` ("dependent object would inherit forbidden aspects").
