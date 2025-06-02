# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
