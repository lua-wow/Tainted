# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

-   Bag window close button, gold display and bag slot hover that highlights the bag's items (Classic)
-   Bag window columns computed from the number of slots (`C.bags.buttons.columns = 0`, the default)
-   Blocked and forbidden action messages printed when `taintLog` is enabled

### Changed

-   Bag window layout closer to Retail: search box and sort button at the top, free slots bottom left, gold bottom right
-   Gold datatext: shift-click no longer toggles the bag slots on Classic (they live in the bag window)
-   Fix items in bags not usable in combat on Classic clients ([#10](https://github.com/lua-wow/Tainted/issues/10))
-   Fix bag window closing when a bag is swapped or an empty bag slot is clicked (Classic)
-   Fix Retail Lua errors: `taintLog` is never enabled on Retail and is a level elsewhere ([#13](https://github.com/lua-wow/Tainted/issues/13))

### Removed

-   `/tainted keybindings`: personal key bindings moved to a separate addon

## [1.4.0] - 2026-10-15

### Added

-   Support for Retail (Midnight, 12.1) and `Classic Forever`
-   One `Tainted.toc` for every client: Retail, Forever, Era, TBC, WotLK (Titan) and MoP
-   Unified bag window on every client, with search, sort and free/total slots
-   Classic bank window and Tainted's own bag sort on Classic clients (`C.bags.sort_bank` also sorts the bank)
-   Retail player auras on Blizzard's `AuraContainer`; Retail unit-frame and raid auras with Blizzard filters
-   Threat border on raid and party frames
-   Specialization datatext
-   House favor bar (Retail)
-   Role commands `/tainted healer`, `/tainted tank`, `/tainted dps` and `/tainted auto`; healer role moves the raid frames to the centre
-   Static analysis with `luacheck` (`make check`)

### Changed

-   Updated for Midnight secret values: tags, nameplates, castbar, class power, totems and threat bar
-   Works with `loadDeprecationFallbacks` disabled (`C_*` APIs instead of deprecated globals)
-   One classic oUF (`libs/oUF_Classic`) for Era, TBC, WotLK and MoP
-   Action bars, Blizzard tweaks, merchant, screenshots and threat bar load on every client
-   Auto keystone and dungeon portals updated for Midnight (Retail only)
-   Dispel and interrupt announcers use `C_ChatInfo.SendChatMessage` (Classic only)
-   Threat bar updates on events instead of polling
-   Fix quest tracker not updating in MoP Classic ([#6](https://github.com/lua-wow/Tainted/issues/6))
-   Fix player tooltips not showing class colors in MoP Classic ([#7](https://github.com/lua-wow/Tainted/issues/7))
-   Fix spell tooltips not showing spell IDs in MoP Classic ([#8](https://github.com/lua-wow/Tainted/issues/8))
-   Fix combat taint blocks on Classic auras and extra/zone ability buttons

### Removed

-   `Tainted_Classic.toc`, `Tainted_Mists.toc` and the `oUF_Mists` submodule. Existing git clones can delete the stale `libs/oUF_Mists` folder
-   Skyriding race tracker (now the standalone `Skyriding` addon)
-   Raid utility frame and `/tainted raid` (use Blizzard's `/wm`, `/readycheck` and keybinds)
-   Meter and bags datatexts

### Known limitations

-   Bag items can't be used in combat on Classic clients ([#10](https://github.com/lua-wow/Tainted/issues/10))
-   No way to customize Tainted from a separate addon yet ([#11](https://github.com/lua-wow/Tainted/issues/11))
-   Dispel and interrupt announcers are Classic only: addons can't read the combat log on Retail and Forever
-   Threat bar is hidden while threat values are secret (Retail, Forever)
-   See [docs/limitations.md](./docs/limitations.md)

## [1.3.5] - 2026-04-23

### Added

-   Support for Mists of Pandaria Classic - Patch 5.5.0

### Changed

-   Fix MoP Minimap
-   Fix MoP nameplates coloring for challenge mode
-   Fix tooltip border coloring
-   Update Objective Tracker
-   Removed oUF_Harmony submodule (added by mistake)

## [v1.3.4] - 2025-06-02

### Changed

-   Fix keystone parse regex
-   Added vault activities tracker for mythic keystones
-   Changed character datatext to display mythic keystone progress track

## [1.3.3] - 2025-04-20

### Added

-   Added `Classic Era` support
-   Added new dependency `oUF_Tempest`
-   Added tempest bar to track shaman enhancement maelstorm weapon and tempest stacks

### Changed

-   Update depenencies for patch 11.1.0
-   Update keystone parser for War Within Season 2
-   Update dungeon portal spells for War Within Season 2

## [1.3.2] - 2024-10-29

### Added

-   Added new dependency `LibMobs`.
-   Added options to time datatext to display time as 24-hour or 12-hour format.
-   Added dungeon portal shortcut inside challenge frame.

### Changed

-   Fixed time datatext bug which was showing time 1h ahead.
-   Fixed keystone affix comparison.

## [1.3.1] - 2024-10-16

### Changed

-   fixed time datatext error
-   fixed tooltip anchor point

## [1.3.0] - 2024-10-15

### Added

-   Embedded `TaintLess`
-   Custom chat frames
-   Custom experience bar
-   Datatexts
-   New miscellanous that takes screenshots when achievements are earned
-   New miscellanous to track skyriding race timer
-   Setup game fonts
-   Reagent tooltips shows amount in bag
-   Raid utility frame and `/tainted raid` command
-   Added list of keystones in the character datatext

### Changed

-   Fix health temporary loss status bar and texture
-   Missing configuration for worldmap coordinates
-   Added Ping System on default binding configuration
-   Added Achievement window as `shift + y`
-   Fix chatframe bug on install
-   Fixed some unitframes options
-   Removed power bar from nameplates
-   Colored nameplates by enemy type (mythic keys)
-   Different raid frame layouts for 20 and 40-man groups
-   Skin Battle.net toasts
-   Skin tooltip close button

## [1.2.0] - 2024-08-14

### Added

-   Auto keystone
-   Changed font fo frame rate (Ctrl + R)
-   Placing queue status button inside minimap
-   Update raid frame anchor for cataclysm classic
-   Action bars styling
-   Fixed Objective Tracker position

### Changed

-  Added mirro timers for classic

## [1.1.0] - 2024-08-04

### Added

-   StatusBar to display health temporary loss.
-   Skin `GhostFrame`

### Changed

-   Patch 11.0.0, updating dependencies
-   Taint Fix: you are not suppose to move stuff while in combat.
-   Fix minimap tracking frame.
-   Fix nameplates callback.
-   Fix dispelable auras highlight.
-   Fix raid frame taint.

## [1.0.0] - 2024-07-27

### Added

-   Initial setup
-   Pushing everything from `patch 10.2.7`
