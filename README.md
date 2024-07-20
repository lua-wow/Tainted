# Tainted

## Description

**Tainted** is a minimalistic user interface replacement for **World of Warcraft**.

## Options

Type `/tainted help` in the game chat to see options.

## Installation

1.  Download the latest version of [**Tainted**](https://github.com/lua-wow/Tainted/releases)
2.  Backup your **Interface** and **WTF** folders.
3.  Delete **Cache** and **WTF** folders for a clean install.
4.  Copy/Paste **Tainted** folder into WoW interface folder (*../World of Warcraft/_retail_/Interface/AddOns*)
5.  Now you are ready to start World of Warcraft.

## Development Setup

### Method 1

```bash
# clone repository and its submodules
git clone --recurse-submodules git@github.com:lua-wow/Tainted.git
```

### Method 2

```bash
# clone just the main repository
git clone git@github.com:lua-wow/Tainted.git

# clone submodules
git submodule update --init --recursive
```

### Ignore `core/development.lua` changes

```bash
# you should upload changes in the core/development.lua
git update-index --assume-unchanged core/development.lua
```

## License

Please, see [LICENSE](./LICENSE) file.
