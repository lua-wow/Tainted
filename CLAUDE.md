# CLAUDE.md

World of Warcraft addon: `Tainted` - minimalistic UI

Existing, working addon written mostly from scratch.
Heavily influenced by `Tukui` addon.
Based on `oUF`.

## Game Versions

- Retail (Midnight) - `Tainted.toc` (fallback TOC)
- Classic Era - `Tainted_Classic.toc`
- Classic TBC - ["not supported"]
- Classic WotLK - ["not supported"]
- Classic MoP - `Tainted_Mists.toc`
- Classic Forever (New) - `Tainted.toc`

Each version has its own TOC file. When adding/removing/renaming a file, update every
TOC that should load it and keep load order correct.
Never assume an API exists on every version; if unsure, say so and check how existing
code handles version differences.

## Submodules

The project is composed of multiple git submodules (my own work or forks):

- `libs/*`
- `modules/miscellaneous/dispels`
- `modules/miscellaneous/interrupts`
- `modules/miscellaneous/screenshots`

Rules:

- Submodules are separate repos. Git rules below apply inside them too.
- Prefer fixing things in `Tainted` over patching a submodule.
- Edit a submodule only when I ask or after you ask me first. I commit there myself and
  update the submodule pointer in this repo.
- Libraries in `libs/` other than oUF are read-only unless I say otherwise.

## oUF

- `libs/oUF`: **Retail oUF. Do not modify.** [fork of upstream, official oUF repo]
- `libs/oUF_Classic`: Classic oUF [branch: `classic`; used by Era/TBC/WotLK].
  Fixes allowed when needed.
- `libs/oUF_Mists`: MoP oUF [branch: `mop`; used by MoP]. Fixes allowed when needed.
- Never edit Retail oUF. If something seems broken there, document it, work around it in
  `Tainted` (elements, tags, styles), and tell me.

## Code Style

- Use prototype style.

```lua
local element_proto = {}

function element_proto:Update()
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:Update()
```

- Follow the existing style of the file you are editing. Keep changes focused; no
  unrelated refactors or reformatting.
- Lua 5.1 only (WoW runtime). Avoid new globals unless the project already does it.

## Testing

- Manual, in-game with `/reload`. After a change, tell me what to verify and on which
  game versions.

## References

- For WoW events consult `https://warcraft.wiki.gg/wiki/Event:[NAME]`, w.g: `PLAYER_LOGIN`
- For WoW API consult `https://warcraft.wiki.gg/wiki/API:[NAME]`, e.g: `C_Spell.GetSpellInfo`
- A local clone of Blizzard UI source is at `../wow-ui-source`
    - branch `live` for Retail
    - branch `forever` for Classic Forever
    - branch `classic` for Classic Era

## Rules

- Git is **read-only** for you. I will handle all writes myself.
- Allowed: `status`, `diff`, `log`, `show`, `blame`, `branch` (listing only),
  `submodule status`.
- Forbidden: `push`, `commit`, `add`, `pull`, `merge`, `rebase`, `checkout`, `switch`,
  `stash`, `tag`, `cherry-pick`, `reset`, `restore`, `revert`, `clean`, and
  `submodule update/init/sync/add`.
- Do not use the GitHub CLI (`gh`).