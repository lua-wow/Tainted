# Tainted

## Description

**Tainted** is a minimalistic user interface replacement for **World of Warcraft**, heavily
inspired by [Tukui](https://www.tukui.org) and built on [oUF](https://github.com/oUF-wow/oUF).
A single addon folder serves every supported client and should look the same on all of them.

> Tainted is being revived after a long break. Most modules are done but still **pending in-game
> verification**; see [known limitations](./docs/limitations.md) and
> [unverified features](./docs/unverified.md).

## Supported clients

| Client                | Interface |
|:----------------------|:----------|
| Retail (Midnight)     | `120105`  |
| Classic Forever       | `16001`   |
| Classic Era           | `11509`   |
| Classic TBC           | `20506`   |
| Classic WotLK (Titan) | `38002`   |
| Classic MoP           | `50504`   |

Cataclysm is not supported.

## Modules

| Feature                                                                       | Retail | Forever | Era | TBC | WotLK | MoP |
|:------------------------------------------------------------------------------|:------:|:-------:|:---:|:---:|:-----:|:---:|
| **Unit frames**: player, target, target of target, pet, focus, focus target, party, raid, boss and arena, with class resources, castbars and auras | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Nameplates**                                                                | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Minimap**: square minimap with a datatext strip; styled world map with coordinates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Chat**: styled chat frames, history across reloads, copy chat text, clickable URLs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Datatexts**: guild, character (durability), friends, system, specialization, gold, time, coordinates, micro menu, voice chat | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Action bars**: main, multi bars (6–8 off by default), pet, stance, extra and zone ability buttons, micro menu and bags bars | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Auras**: player buffs, debuffs and weapon enchants next to the minimap      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Tooltips**: styled tooltips with extra information such as spell IDs       | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Bags**: a single bag window with a sort button (Blizzard's sort on Retail and Forever, Tainted's own on Classic) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Bank**: a single bank window                                                | — | — | ✅ | ✅ | ✅ | ✅ |
| **Blizzard UI tweaks**: durability, experience/reputation bars, framerate, mirror timers, objective tracker, queue status, UI widgets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Ghost frame** tweak                                                         | ✅ | ✅ | — | — | — | ✅ |
| **Talking head**: hidden                                                      | ✅ | ✅ | — | — | — | — |
| **Auto Repair** and **Auto Sell Junk** at merchants                           | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Auto Screenshots** on level up, achievements, boss kills and Mythic+ completion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Threat bar**                                                                | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Interrupts** and **Dispels**: announce your interrupts and (a few) dispels in group chat | — | — | ✅ | ✅ | ✅ | ✅ |
| **Auto Keystone**: places your keystone when the Mythic+ frame opens          | ✅ | — | — | — | — | — |
| **Dungeon Portals**: teleport buttons on the Mythic+ frame                    | ✅ | — | — | — | — | — |

## Usage

### Commands

-   `/tainted` - List all available commands.
-   `/tainted healer` - Set the healer role: raid frames move to the centre (groups of up to 20).
-   `/tainted tank` - Set the tank role: raid frames stay above the chat.
-   `/tainted dps` - Set the damage role: raid frames stay above the chat.
-   `/tainted auto` - Clear the manual role and use the detected one.
-   `/tainted spell <spellID|name>` - Print a spell's name, ID and whether it is known.
-   `/tainted test` - Show the unit frames with the player as unit.
-   `/tainted reset` - Reset Tainted's saved data for this character and reload the UI.
-   `/rl` - Reload the UI.

> The role is detected from your specialization (talent points on Era, TBC and WotLK); the role commands override it per character.

### Minimap

-   `Right-Click`: open the tracking menu (on clients that have one).
-   `Middle-Click`: open the expansion landing page (Retail and Forever, when it is available).

### Datatexts

-   `Gold`: `Click` toggles the bags; `Shift-Click` shows the bag slots.
-   `Micro Menu`: `Click` shows the micro menu bar and the game menu.
-   `Character`: `Click` opens the character frame.
-   `Time`: `Click` opens the calendar (where it exists); `Right-Click` opens the time manager.
-   `Coords`: `Click` opens the world map; `Shift-Click` prints map IDs.

> Some datatexts will display extra information while holding `Shift`.

## Configuration

There is no in-game configuration.

Please report Lua errors as [issues](https://github.com/lua-wow/Tainted/issues).

## Installation

1.  Download the latest version of [**Tainted**](https://github.com/lua-wow/Tainted/releases)
2.  Backup your **Interface** and **WTF** folders.
3.  Delete the **Cache** and **WTF** folders for a clean install.
4.  Copy the **Tainted** folder into the client's AddOns folder.
    - `World of Warcraft/_retail_/Interface/AddOns`
    - `World of Warcraft/_classic_era_/Interface/AddOns`
5.  Now you're ready to launch World of Warcraft.

To install from git, clone **with submodules**: the bundled libraries in `libs/` and the
announcer/screenshot modules are git submodules, and the addon won't load without them.

## Development Setup

### Method 1

```bash
# clone the repository along with submodules
git clone --recurse-submodules git@github.com:lua-wow/Tainted.git
```

### Method 2

```bash
# clone just the main repository
git clone git@github.com:lua-wow/Tainted.git

# initialize/clone submodules
git submodule update --init --recursive
```

### Linting

Static analysis uses [luacheck](https://github.com/lunarmodules/luacheck), configured in [.luacheckrc](./.luacheckrc).

Requirements: **Lua 5.1** and **LuaRocks** (e.g. via [mise](https://mise.jdx.dev): `mise use lua@5.1`).

```bash
# install lua + luarocks + luacheck
mise install

# list available make commands
make help

# lint the whole addon (submodules under libs/ are excluded)
make check
# or, with mise
mise exec -- make check

# lint a directory or a single file, showing warning codes
luacheck core/
luacheck modules/chat/chatframe.lua --codes
```

When using a new WoW API function, frame or constant, add it to `read_globals` in `.luacheckrc`.
Globals the addon intentionally sets or mutates go in `globals`.

## Credits

-   [oUF](https://github.com/oUF-wow/oUF) by Haste, lightspark, p3lim and Rainrider (MIT).
    `libs/oUF` is a fork of upstream; `libs/oUF_Classic` is its classic branch.
-   [Tukui](https://www.tukui.org) by Tukz, the visual and layout reference.
-   [TaintLess](https://www.townlong-yak.com/addons/taintless) by Townlong Yak (see upstream for its terms).
-   [LibStub](https://www.curseforge.com/wow/addons/libstub) by Kaelten

The MIT-licensed libraries keep their license file in their folder.

## License

Please, see [LICENSE](./LICENSE) file.
