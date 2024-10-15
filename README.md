# Tainted

## Description

**Tainted** is a minimalistic user interface replacement for **World of Warcraft**.

## Usage

> **obs.**: There is o ingame configuration in the current version

### Commands

-   `/tainted` - List all available commands.
-   `/tainted raid` - Display the raid utility frame.

### Minimap
-   `Left-Click`: open tracking frame.
-   `Wheel-Click`: open expansion langing page, such as factions.

### Datatexts
-   `Micro Menu` - `Shift Click` shows micro menu bar.
-   `Gold`: `Shift Click` shows bags bars.

> Some datatexts will display extra infomations while holding `Shift`.

## Features

-   **Auto Keytone**: Automativally places the keystone When mythic plus frame is open.
-   **Auto Screenshots**: Tiggers a screenshot upon certain events like `Level Up`, `Earn Achievement`, `Mythic Key Completion` or `Encounter End`.
-   **Auto Repair**: Repairs your gear automatically when interacting with a merchant.
-   **Auto Sell Junk**: Automatically sells junk items when a merchant frame is open.
-   **Interrupts**: Announces your interrupts in group chat.
-   **Dispels**: Announces yours dispels in group chat. Just a few auras are announced, to avoid span.
-   **Talking Head**: Talking Head frame is disabled by default.
-   **Skyriding Time Tracker**: Displays a status bar to track the required race time for gold medals in Sky Riding races.

## Installation

1.  Download the latest version of [**Tainted**](https://github.com/lua-wow/Tainted/releases)
2.  Backup your **Interface** and **WTF** folders.
3.  Delete the **Cache** and **WTF** folders for a clean install.
4.  Copy the **Tainted** folder into WoW Interface folder: `../World of Warcraft/_retail_/Interface/AddOns`
5.  Now you ready to launch World of Warcraft.

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

### Ignore `core/development.lua` changes

```bash
# ignore changes done to core/development.lua
git update-index --assume-unchanged core/development.lua
```

## License

Please, see [LICENSE](./LICENSE) file.
