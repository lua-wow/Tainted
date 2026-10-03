# CLAUDE.md

World of Warcraft addon: `Tainted` - minimalistic UI

Heavily influenced by `Tukui` addon. Based on `oUF`.

**Status:** being revived after I stopped playing during Midnight. Expect broken code
from removed or changed Blizzard API and from secret values. Do not assume existing
code is correct.

## Game Versions

- Retail (Midnight) - `Tainted.toc` (fallback TOC)
- Classic Era - `Tainted_Classic.toc`
- Classic TBC - ["not supported"]
- Classic WotLK - ["not supported"]
- Classic MoP - `Tainted_Mists.toc`
- Classic Forever (New) - `Tainted.toc` (TODO: verify Forever really loads this file
  and which interface number it uses)

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
- Exception: `libs/LibMobs` is my own library; you may edit it when a fix belongs there.

## oUF

- `libs/oUF`: **Retail oUF. Do not modify.** [fork of upstream, official oUF repo]
- `libs/oUF_Classic`: Classic oUF [branch: `classic`; used by Era/TBC/WotLK].
  Fixes allowed when needed.
- `libs/oUF_Mists`: MoP oUF [branch: `mop`; used by MoP]. Fixes allowed when needed.
- Never edit Retail oUF. If something seems broken there, document it, work around it in
  `Tainted` (elements, tags, styles), and tell me.
- Updating Retail oUF from upstream (rebase/merge) is done by me. You may prepare a
  report of what changed upstream, but do not apply it.
- Whether to merge the Classic/MoP oUF branches into one codebase is undecided. Do not
  refactor toward that unless I ask.

## Midnight (Retail) rules

- Some API returns "secret" values: no arithmetic, comparison, string operations or
  table keys on them. Before using an API result in logic, check the generated API
  docs in `../wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated`.
- If you are unsure whether a function returns secrets or is restricted, say so.
  Don't guess.
- Tags and aura-based features are the most likely to be affected. Audit before fixing.

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
- Claude cannot run the game. I will paste Lua errors back to you.

## References

Blizzard UI source (read-only reference, don't edit):

- `../wow-ui-source`          -> branch `live` (Retail)
- `../wow-ui-source-forever`  -> branch `forever` (Classic Forever)
- `../wow-ui-source-classic`  -> branch `classic` (Classic Era)

Where to look for API truth, in order:

1. The Blizzard UI source above, especially `Blizzard_APIDocumentationGenerated`
2. `docs/` files, once they exist (see below)
3. Wiki: `https://warcraft.wiki.gg/wiki/API:[NAME]`, e.g. `C_Spell.GetSpellInfo`
   and `https://warcraft.wiki.gg/wiki/Event:[NAME]`, e.g. `PLAYER_LOGIN`

If sources disagree, trust 1. Never invent an API. If you cannot verify it, mark it
"unverified" in your answer.

## Docs (not created yet)

These will be generated during the revival. Do not assume they exist; check first.

- `docs/api-changes.md`: removed/renamed/changed API and where Tainted uses it
- `docs/secrets.md`: secret-restricted functions
- `TODO.md`: current checklist. Update it at the end of each task once it exists.

## Rules

- Git is **read-only** for you. I will handle all writes myself.
- Allowed: `status`, `diff`, `log`, `show`, `blame`, `branch` (listing only),
  `worktree list`, `submodule status`.
- Forbidden: `push`, `commit`, `add`, `pull`, `fetch`, `merge`, `rebase`, `checkout`,
  `switch`, `stash`, `tag`, `cherry-pick`, `reset`, `restore`, `revert`, `clean`, and
  `submodule update/init/sync/add`.
- Do not use the GitHub CLI (`gh`).
