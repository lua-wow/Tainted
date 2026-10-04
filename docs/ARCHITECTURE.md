# Tainted — Architecture

Tainted is a minimalistic World of Warcraft UI, heavily influenced by Tukui and built
on [oUF](https://github.com/oUF-wow/oUF). Version `1.3.5` (`## Version` in every TOC).

This document describes how the addon is put together. Paths are relative to the repo
root. Anything not verified from the code is marked **unsure**.

Related docs: [`docs/README.md`](README.md) (helper API notes), [`docs/DEBUG.md`](DEBUG.md)
(taint log), [`docs/auras/README.md`](auras/README.md).

---

## 1. Folder layout

| Path | Purpose |
| --- | --- |
| `Tainted.toc`, `Tainted_Classic.toc`, `Tainted_Mists.toc` | One TOC per game flavour (see §2). |
| `core/` | Engine: bootstrap (`init.lua`), module registry + event loop (`core.lua`), widget API (`api.lua`), helpers (`utils.lua`), assets/fonts/colors, SavedVariables (`database.lua`), CVars (`install.lua`), UI scale (`scaling.lua`), slash commands (`commands.lua`), dropdown skinning (`dropdown.lua`), talents/keystone trackers, `development.lua` (empty scratch file). |
| `config/settings.lua` | Static configuration table `C` (all defaults). |
| `locales/` | `init.xml` loads `enUS.lua` only; `template.lua` is a template, not loaded. |
| `modules/actionbars/` | Action bars 1–8, pet bar, stance bar, extra/zone buttons, keybinding setup. |
| `modules/auras/` | Player buff/debuff headers. |
| `modules/bags/` | Bags/bank (`C.bags.enabled = false` by default). |
| `modules/blizzard/` | Reskins/repositions of Blizzard frames (XP bar, mirror timers, objective tracker, raid utility, …). |
| `modules/chat/` | Chat frames, chat history, copy text/URL. |
| `modules/datatexts/` | Data text panels; one file per element in `elements/`. |
| `modules/maps/` | Minimap, world map, zone map. |
| `modules/miscellaneous/` | Merchant, threat bar, M+ helpers, skyriding race + three **submodules**: `dispels/`, `interrupts/`, `screenshots/`. |
| `modules/tooltips/` | Tooltip skinning + metadata lines. |
| `modules/unitframes/` | oUF style: `core.lua`, `tags.lua`, `elements/`, `classes/`, `units/`. |
| `assets/` | Fonts, textures, icons (paths listed in `core/assets.lua`). |
| `libs/` | Git submodules: `oUF`, `oUF_Classic`, `oUF_Mists`, `oUF_Atonement`, `oUF_AuraTrack`, `oUF_RaidDebuffs`, `oUF_TargetIndicator`, `oUF_Tempest`, `LibDispel`, `LibMobs`, `LibStub`, `TaintLess` (`.gitmodules`). |
| `Makefile`, `exclude.lst`, `.github/workflows/release.yml` | Packaging: `make zip` zips the repo minus `exclude.lst`; the release workflow runs it. |

---

## 2. Load flow

### 2.1 TOC files

| TOC | `## Interface` | oUF variant | Notes |
| --- | --- | --- | --- |
| `Tainted.toc` | `120100` | `libs/oUF` | Retail (Midnight). Fallback TOC. |
| `Tainted_Classic.toc` | `11507` | `libs/oUF_Classic` | Classic Era. `## OptionalDeps: Questie`. |
| `Tainted_Mists.toc` | `50500` | `libs/oUF_Mists` | MoP Classic. |

All three declare `## SavedVariables: TaintedDatabase, TaintedChatHistory`.
None declares `## X-oUF`, so oUF is embedded privately (see §4).

### 2.2 Load order (same skeleton in every TOC)

1. `core/init.lua` — creates the engine and namespace.
2. Libraries — `TaintLess`, `LibStub`, `LibDispel`, `LibMobs`, then the oUF variant and oUF plugins.
3. Assets — `core/assets.lua`, `core/colors.lua`, (`core/curves.lua` Retail only), `core/fonts.lua`.
4. `locales/init.xml`.
5. `config/settings.lua` — must come after `colors.lua` because it calls `E:CreateColor`.
6. Core — `scaling.lua`, `api.lua`, `utils.lua`, `core.lua`, `database.lua`, `install.lua`,
   `dropdown.lua`, `commands.lua`, `talents.lua` (Classic/MoP) or `keystone.lua` (Retail),
   `development.lua`.
7. Modules — auras, bags, chat, maps, blizzard, miscellaneous, actionbars, datatexts,
   tooltips, unitframes (`core.lua`, `tags.lua`, `elements/*`, `classes/*`, `units/*`).

Order inside a module matters: the file that calls `E:CreateModule("X")` must load before
files that call `E:GetModule("X")` (e.g. `modules/actionbars/init.xml` loads `core.lua`
first; `modules/unitframes/core.lua` is listed before `elements/`, `classes/`, `units/`).

### 2.3 Per-version differences in the TOCs

| | Retail `Tainted.toc` | Classic `Tainted_Classic.toc` | MoP `Tainted_Mists.toc` |
| --- | --- | --- | --- |
| oUF plugins | `oUF_Atonement`, `oUF_Tempest` (AuraTrack, RaidDebuffs, TargetIndicator commented out) | `oUF_AuraTrack`, `oUF_RaidDebuffs`, `oUF_TargetIndicator` | same as Classic |
| `core/curves.lua` | yes | no | no |
| `core/talents.lua` | commented out | yes | yes |
| `core/keystone.lua` | yes (runtime `E.isRetail` guard; Forever has no keystones) | not listed | not listed |
| Modules other than unitframes | **all commented out** | loaded | loaded |
| `modules/bags/_init.xml` | not listed | loaded | loaded |
| blizzard XML | `init.xml` (commented) | `init_classic.xml` | `init_mists.xml` |
| miscellaneous XML | `init.xml` (commented) | `init_classic.xml` | `init_mists.xml` |

On Retail only the engine, `core/dropdown.lua`, `core/keystone.lua` and the unit frames
currently load. This
matches the WIP Midnight port (commit `7fe4618 patch 12.0.5 (wip)`).

Version-specific XML contents:

- `modules/blizzard/init.xml` (Retail) has `raid_utility.lua` and no `durability.lua`;
  `init_classic.xml` / `init_mists.xml` have `durability.lua` and no `raid_utility.lua`.
- `modules/miscellaneous/init.xml` (Retail) adds `auto_keystone.lua`, `dungeon_portals.lua`,
  `skyriding_race.lua`; the Classic/MoP variants only load the submodules, `settings.lua`,
  `merchant.lua`, `threatbar.lua`.

### 2.4 Runtime boot (`core/core.lua:71-130`)

The engine frame `E` handles its own events and dispatches to `E[event]`:

| Event | Handler | Does |
| --- | --- | --- |
| `ADDON_LOADED` (`E.addon`) | `E:ADDON_LOADED` | `E:InitDatabase()` (`core/database.lua`) → sets `E.db`, then unregisters the event. |
| `VARIABLES_LOADED` | `E:VARIABLES_LOADED` | Refresh locale, `E:UpdateFonts()` (`core/fonts.lua`). |
| `PLAYER_LOGIN` | `E:PLAYER_LOGIN` | First run: `E:SetupDefaultsCVars()` (`core/install.lua`) + `E:SetupUiScale()` + Retail bag sort CVars, set `db.installed`. Later logins: `E:ApplyUiScale()`. Always: `E:InitModules()`. |
| `SETTINGS_LOADED` (Retail only) | `E:SETTINGS_LOADED` | Enables action bars 2–5 via `Settings.SetValue`, only when the value differs. |
| `PLAYER_ENTERING_WORLD` | `E:PLAYER_ENTERING_WORLD` | First run only, if the `Chat` module is loaded: `Chat:Reset()` + `db.chat = true`. |

---

## 3. Modules

### 3.1 Registry (`core/core.lua:10-55`)

`ModuleMixin` is mixed into `E`. The registry (`indexes`, `modules`) is closure locals in
`core/core.lua`, not fields on the mixin.

- `E:CreateModule(name, proto)` — asserts the name is new, appends it to `indexes`
  (ordered), stores `proto or {}`. Returned table is the module.
- `E:SetModule(name, module)` — stores without adding to `indexes` (no `Init` call).
- `E:GetModule(name)` — lookup.
- `E:InitModules()` — called at `PLAYER_LOGIN`; calls `module:Init()` in registration
  (= file load) order, each through `E:Call` (`xpcall` + `geterrorhandler()`), so one
  failing module doesn't stop the rest. A missing `Init` is reported and skipped.
- `E:UpdateModules()` — calls `module:Update()` through `E:Call` on every module that has
  one. No caller found.

### 3.2 Registration styles in use

1. **Registered module with `Init`** — `CreateModule` in the first file, `GetModule` in the
   rest:
   - `ActionBars` (`modules/actionbars/core.lua`) + `bar1..8.lua`, `petbar.lua`, `stancebar.lua`, …
   - `Bags` (`modules/bags/core.lua`), `Containers` (`modules/bags/containers.lua`)
   - `Blizzard` (`modules/blizzard/core.lua`) + per-frame files
   - `Chat` (`modules/chat/chatframe.lua`) + `copy_text.lua`, `copy_url.lua`
   - `DataTexts` (`modules/datatexts/core.lua`) + `elements/*.lua`
   - `DropDown` (`core/dropdown.lua`)
   - `Maps` (`modules/maps/core.lua`), `Minimap` (`modules/maps/minimap.lua`)
   - `Tooltips` (`modules/tooltips/tooltips.lua:670`, created with an existing prototype)
   - `UnitFrames` (`modules/unitframes/core.lua:6`)
2. **Service object, no `Init`** — a self-driven frame stored with `SetModule`:
   `Talents` (`core/talents.lua:196`), `KeyStone` (`core/keystone.lua:171`).
3. **Standalone file** — not registered; creates its own frame/events, usually gated by
   a config flag with an early `return` at file scope, e.g.
   `modules/auras/auras.lua` (`C.auras.enabled`), `modules/miscellaneous/threatbar.lua:13`,
   `modules/blizzard/ghost.lua:15`, `modules/chat/history.lua:7`, `modules/maps/minimap.lua:13`.
4. **Submodules** (`modules/miscellaneous/{dispels,interrupts,screenshots}`) publish on the
   private namespace: `ns.Dispels`, `ns.Interrupts`, `ns.ScreenShots`. Tainted configures them
   from `modules/miscellaneous/settings.lua` (e.g. `ns.ScreenShots.Frame:SetOptions(C.miscellaneous.screenshots)`).

A minimal module:

```lua
local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Example")

function MODULE:Init()
    if not C.example.enabled then return end
    -- build frames, register events
end
```

---

## 4. Namespace and globals

### 4.1 Private namespace (`core/init.lua`)

```lua
local addon, ns = ...
local frame = CreateFrame("Frame", nil, UIParent)
_G[addon] = frame                                   -- _G.Tainted
local E, C, A, L, P = frame, {}, {}, {}, {}
ns.E, ns.C, ns.A, ns.L, ns.P = E, C, A, L, P
```

| Key | Name | Contents |
| --- | --- | --- |
| `ns.E` | Engine | A `Frame`. Player/system info (`E.class`, `E.realm`, `E.screenHeight`, `E.pixelPerfectScale`, …), version flags (`E.isRetail`, …), `E.Hider`, `E.PetHider`, module registry, helpers. |
| `ns.C` | Config | Defaults from `config/settings.lua`. |
| `ns.A` | Assets | `A.fonts`, `A.textures`, `A.icons`, `A.sounds` (`core/assets.lua`). |
| `ns.L` | Locales | Strings (`locales/enUS.lua`). |
| `ns.P` | Private | Empty; no use found. |
| `ns.oUF` | oUF | Set by the embedded oUF's `init.lua` (shares Tainted's `ns`). |

Every file starts with `local _, ns = ...` and pulls what it needs:
`local E, C, A = ns.E, ns.C, ns.A`.

### 4.2 Globals created by Tainted

- `Tainted` — the engine frame `E` (`core/init.lua:6`).
- `TaintedDatabase`, `TaintedChatHistory` — SavedVariables.
- `SLASH_TAINTED1`, `SLASH_RELOADUI1`, `SlashCmdList.TAINTED/RELOADUI` (`core/commands.lua`).
- Font objects `TaintedFont`, `TaintedFontOutline`, `TaintedUFFont` (`core/assets.lua:48-55`).
- Named frames, e.g. `TaintedHider`, `TaintedPetHider` (`core/init.lua`), `TaintedGroupHolder`,
  `TaintedPlayer`, `TaintedTarget`, `TaintedRaid` (unit frames are named `addon .. Unit`,
  `modules/unitframes/core.lua:191-210`), `TaintedThreatBar`, `TaintedRaidUtility`, ….
- No global `oUF`: no TOC declares `X-oUF`. Files use `ns.oUF or _G.oUF`
  (`core/colors.lua:2`, `core/curves.lua:2`, `modules/unitframes/core.lua:2`).

---

## 5. Prototype / Mixin pattern

Behaviour lives in a plain `*_proto` table; a frame is created and the prototype mixed in
with Blizzard's `Mixin(obj, ...)` (copies fields onto the object).

**Unit frame element** — `modules/unitframes/elements/health.lua`:

```lua
local element_proto = {
    colorDisconnected = true,
    colorTapping = E.isClassic,
    colorClass = true,
    colorReaction = true
}

function element_proto:SetColor(color) ... end
function element_proto:PostUpdateColor(unit, color) ... end   -- oUF callback

function UnitFrames:CreateHealth(frame, textParent)
    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Health", frame), element_proto)
    ...
end
```

The proto carries both oUF options (`colorClass`, …) and oUF hooks (`PostUpdateColor`), so
mixing it in configures the element. Same shape in `elements/stagger.lua:51`,
`elements/atonement.lua:20`.

**Layering prototypes** — `modules/unitframes/units/nameplate.lua:333` mixes a second proto
onto an already-built element: `Mixin(self:CreateHealth(frame, textParent), health_proto)`.
`modules/bags/core.lua:66` mixes two: `Mixin(CreateFrame(...), container_proto, element_proto)`.

**Event-driven frame** — raid holder, `modules/unitframes/core.lua:33-119`: proto has
`OnEvent`, `GetPosition`, `UpdatePosition`; then
`element:SetScript("OnEvent", element.OnEvent)`. Same in `core/talents.lua:192`,
`core/keystone.lua`, `modules/miscellaneous/threatbar.lua:109`,
`modules/blizzard/objective_tracker.lua:67`, `modules/chat/history.lua:92`.

**Engine itself** — `core/core.lua:54`: `E = Mixin(E, ModuleMixin)`.

**Module as proto** — `modules/tooltips/tooltips.lua:670`: `E:CreateModule("Tooltips", tooltip_proto)`.

**Widget API injection** (related, not Mixin) — `core/api.lua:202-225` copies every function in
`E.API` (`Kill`, `StripTexts`, `StripTextures`, `SetFadeIn/OutTemplate`, `SetOutside`,
`SetInside`, `CreateBackdrop`, `SkinButton`, `GetCooldownTimer`, `SkinCloseButton`) into the
shared metatable `__index` of each widget type (Frame, Texture, FontString, and every type
found via `EnumerateFrames`). That is why any frame can call `frame:CreateBackdrop()`.

---

## 6. Configuration and SavedVariables

### 6.1 Config (`C`) — static, not saved

`config/settings.lua` fills `C` with plain Lua tables. There is no in-game options UI and
nothing in `C` is persisted; changing settings means editing this file.

Top-level sections: `general` (uiScale `0.64`, backdrop/border/highlight colours, margin),
`actionbars`, `auras`, `bags`, `blizzard`, `chat`, `datatexts`, `maps`, `miscellaneous`,
`tooltips`, `unitframes` (global options + one sub-table per unit: `player`, `target`,
`targettarget`, `focus`, `focustarget`, `pet`, `arena`, `boss`, `nameplate`, `raid`).

Some defaults depend on the version, e.g. `C.blizzard.ghost/talkinghead/raid_utility = E.isRetail`.

Unit frames read their sub-table through `frame.__config = C.unitframes[frame.__unit]`
(`modules/unitframes/core.lua`, style function).

### 6.2 SavedVariables (`core/database.lua`)

```
TaintedDatabase = {
    [realm] = {
        [characterName] = {      -- E.db
            installed = bool,    -- first-run setup done (core/core.lua PLAYER_LOGIN)
            chat = bool,         -- chat layout reset done (core/core.lua PLAYER_ENTERING_WORLD)
            experience = number, -- E:Get/SetExperienceBarIndex
            money = number,      -- E:Get/SetMoney (gold datatext)
            keystone = ...,      -- E:Get/SetKeyStone
            vault = ...,         -- E:Get/SetVault
        }
    }
}
TaintedChatHistory = { ... }     -- modules/chat/history.lua
```

`E:InitDatabase()` creates missing levels on `ADDON_LOADED`. `E:ResetDatabase()` wipes the
current character's entry and the chat history (`/tainted reset`). Exact shape of
`keystone`/`vault` values: **unsure** (see `core/keystone.lua`).

---

## 7. oUF usage

### 7.1 Variant per version

| Version | Library | Notes |
| --- | --- | --- |
| Retail | `libs/oUF` (branch `retail`) | Has `enums.lua` (`oUF.Enum`), private auras, etc. **Do not modify.** |
| Classic Era | `libs/oUF_Classic` (branch `classic`) | Adds `combatevents.lua`; exposes `oUF.isRetail/isClassic/...`. |
| MoP | `libs/oUF_Mists` (branch `mop`) | Classic-style core + runes, stagger, additional/alternative power. |

All three are embedded the same way: `init.lua` sets `ns.oUF = {}` on Tainted's namespace.

### 7.2 Style and spawning (`modules/unitframes/core.lua`)

`UnitFrames:Init()`:

1. `DisableBlizzard()` — reparents party/compact raid frames to `E.Hider`.
2. `CreateRaidHolder()` — `TaintedGroupHolder` anchor frame.
3. `oUF:RegisterStyle(addon, fn)` — one style named `"Tainted"`. `fn` sets
   `frame.__unit` (unit without digits) and `frame.__config`, sizes the frame, adds a backdrop,
   then dispatches by unit to `UnitFrames:CreatePlayerFrame`, `CreateTargetFrame`, …,
   `CreateNameplateFrame` (`units/*.lua`).
4. `oUF:Factory(...)` — spawns `player`, `target`, `targettarget`, `pet`, `focus`,
   `focustarget`, `boss1..N`, `arena1..N` via local `CreateUnit` (skips units with
   `enabled = false`), then two group headers `TaintedRaid` / `TaintedRaid40` via
   `SpawnHeader` with visibility macros (`GetRaidVisibility`, `GetRaid40Visibilty`), then
   `SpawnNamePlates(addon)` with CVars/callbacks from `UnitFrames.Nameplates`.

### 7.3 Elements, classes, units

- `elements/*.lua` — builders `UnitFrames:CreateHealth`, `CreatePower`, `CreateName`,
  `CreateCastbar`, `CreateBuffs/Debuffs`, `CreatePortrait`, indicators, `CreateAtonement`, …
  Each returns an oUF element (often proto-mixed, §5). `UnitFrames:CreateUnitFrame(frame)`
  (`core.lua:156`) attaches the common set.
- `classes/<class>.lua` — `UnitFrames:<CLASS>(frame)` adds class resources. Called from the
  player frame via `self[frame.__class](self, frame)` (`units/player.lua:55`).
- `units/<unit>.lua` — per-unit layout.
- `UnitFrames:RunTest()` / `/tainted test` forces all spawned frames to show as `player`.

### 7.4 Custom tags (`modules/unitframes/tags.lua`)

Registered into oUF's tag system at file load:

```lua
for tag, method in next, tags do
    oUF.Tags.Events[tag] = events[tag]
    oUF.Tags.Methods[tag] = method
end
```

Tags defined: `name`, `nameshort`, `namemedium`, `namelong`, `healthcolor`, `namecolor`,
`rolecolor`, `hostility`, `difficulty`, `classification`, `dead`. Several reuse oUF built-in
names (`name`, `dead`, `classification`) and replace them in Tainted's private oUF copy.
Tags are applied with `frame:Tag(fontString, tag)` in `elements/name.lua:28`,
`elements/health.lua:89`, `elements/power.lua:47`.

### 7.5 Colors

`core/colors.lua` extends `oUF.colors` (reaction, power, runes, totems, difficulty,
classification, …) and aliases it as `E.colors`; `E.CreateColor = oUF.CreateColor`.
Retail-only `core/curves.lua` builds a `C_CurveUtil` color curve for aura durations, exposed
as `oUF.curves` / `E.curves`.

---

## 8. Version differences in code

1. **Separate TOCs and XML include files** (§2.3). Coarse-grained: whole files/modules on
   or off per version.
2. **Engine flags** from `WOW_PROJECT_ID` (`core/init.lua:46-51`): `E.isRetail`,
   `E.isClassic`, `E.isTBC`, `E.isWrath`, `E.isCata`, `E.isMoP`, `E.isPlunderstorm`,
   `E.isForever` (`WOW_PROJECT_CAMELOT`, Classic Forever). Rough usage counts in
   `core/ modules/ config/ locales/`: `isRetail` 63, `isClassic` 17, `isMoP` 8, `isCata` 3,
   `isTBC` 1, `isWrath` 1. Examples:
   - `core/core.lua:74` — `SETTINGS_LOADED` only on Retail.
   - `modules/unitframes/core.lua:13` — `SPEC_DRUID_RESTORATION = E.isRetail and 4 or 3`.
   - `modules/unitframes/classes/priest.lua:9` — Atonement only on Retail.
   - `core/install.lua:52` — `whisperMode` per version.
   - `locales/enUS.lua:37` — different merchant string.
3. **API fallbacks** — resolve namespaced vs. legacy API once at file top:
   `C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata` (`core/init.lua:13`),
   `C_CVar and C_CVar.GetCVar or _G.GetCVar` (`core/scaling.lua:5`),
   `C_Container and ... or _G.GetContainerNumSlots` (`modules/miscellaneous/merchant.lua`).
4. **Existence checks** — `if SetAutoDeclineGuildInvites then` (`core/install.lua:126`),
   `_G.NUM_BOSS_FRAMES or 8`, `if CompactRaidFrameManager then` (`modules/unitframes/core.lua`).
5. **Version-dependent config defaults** (§6.1).

---

## 9. Slash commands and events

### 9.1 Slash commands (`core/commands.lua`)

| Command | Defined in | Action |
| --- | --- | --- |
| `/tainted` | `core/commands.lua:65` | Prints help (all commands with a description). |
| `/tainted reset` | `core/commands.lua:12` | `E:ResetDatabase()` + `ReloadUI()`. |
| `/tainted spell <id\|name>` | `core/commands.lua:66` | Prints spell info and whether it's known. |
| `/tainted test` | `modules/unitframes/core.lua:448` | Show all unit frames as `player`. |
| `/tainted raid` | `modules/blizzard/raid_utility.lua:399` | Toggle raid utility (Retail XML only; currently not loaded). |
| `/tainted keybindings` | `modules/actionbars/bindings.lua:75` | Reapply keybindings (not loaded on Retail now). |
| `/rl` | `core/commands.lua:68` | `ReloadUI`. |

New commands: `E:AddCommand(name, handler, description)`. The parser trims the input,
splits on the first space and trims the argument, so multi-word arguments are kept.
Unknown subcommands print help.

### 9.2 Events

Engine events: §2.4. Most common events registered across `core/` and `modules/`
(excluding submodules): `PLAYER_ENTERING_WORLD`, `PLAYER_LOGIN`, `BAG_UPDATE`,
`PLAYER_REGEN_DISABLED/ENABLED` (combat lockdown guards, e.g. raid holder
`modules/unitframes/core.lua:66-99`), `ADDON_LOADED`, `COMBAT_LOG_EVENT_UNFILTERED`,
`GROUP_ROSTER_UPDATE`, `PLAYER_SPECIALIZATION_CHANGED` / `PLAYER_TALENT_UPDATE` /
`CHARACTER_POINTS_CHANGED` (Retail vs. Classic talent events), `MERCHANT_SHOW`, bank/bag
events, `CHALLENGE_MODE_COMPLETED` / `WEEKLY_REWARDS_UPDATE` (`core/keystone.lua`).
oUF elements register their own unit events.

Hooks: `core/dropdown.lua` uses `hooksecurefunc` on `Menu` manager `OpenMenu` /
`OpenContextMenu` and `UIDropDownMenu_CreateFrames`.

---

## 10. Gotchas and oddities

Bugs below were found by reading code, not by running it. Confirm in-game before fixing.

**Unit frames**

- `modules/unitframes/core.lua:7` — `E:GetModule("Talents")` is `nil` on Retail
  (`core/talents.lua` not loaded); only used in commented code today.

**Modules**

- `modules/datatexts/elements/character.lua:4` uses `E:GetModule("KeyStone")`, but
  `core/keystone.lua` is only loaded by `Tainted.toc`, so `KeyStone` is nil on Classic/MoP.
  Whether that code path runs there: **unsure**.
- `C.bags.enabled = false` by default, but `modules/bags/_init.xml` still loads on Classic/MoP.

**Repo / docs**

- `CLAUDE.md` marks TBC/WotLK "not supported", while `oUF_Classic` and `E.isTBC/isWrath`
  checks still exist.
