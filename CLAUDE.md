# CLAUDE.md

`Tainted` - World of Warcraft addon, minimalistic UI.
Heavily influenced by `Tukui` addon and based on `oUF`.

**Status:** being revived after a long break (patch 11.2.5).
Expect broken code caused by changed/removed Blizzard APIs and from secret values.
Do not assume existing code is correct.

## Compatibility

Supported clients are defined by the project's TOC files:

- Retail / Midnight -> `Tainted.toc`
- Classic Forever   -> `Tainted.toc`
- Classic Era       -> `Tainted_Classic.toc`
- Classic TBC       -> `Tainted_TBC.toc`
- Classic WotLK     -> keep support, but no TOC file.
- Classic MoP       -> `Tainted_Mists.toc`

Never assume an API exists on every client.
Check the appropriate Blizzard source when version differences matter.

## Important Principles

- Preserve existing Tainted behavior and visual design unless the API makes that behavior impossible.
- Prefer fixing the smallest amount of code necessary.
- Do not rewrite functioning systems merely because another addon implements them differently.
- Do not invent WoW APIs.
- Do not assume Retail and Classic APIs are identical.
- Use Blizzard `wow-ui-source` to determine what the API actually does.
- Use `ElvUI`, `Tukui`, and `ls_UI` to find practical compatibility patterns
  and workarounds.
- Treat Blizzard UI source as authoritative for Blizzard implementation details.
- Treat `ElvUI`, `Tukui`, and `ls_UI` as implementation references, not API authority.

## Before changing code

For API compatibility problems, as applicable:

1. Identify the failing API/function/event/frame behavior.
2. Search Tainted for all usages.
3. Determine the current Blizzard API behavior.
4. Check relevant Retail/Classic differences.
5. Check `ElvUI`, `Tukui`, or `ls_UI` for an existing compatibility approach.
6. Explain the proposed fix.
7. If asked to make the change, make the smallest appropriate change.
8. Search for other usages of the same deprecated/changed API.

## Main Features

- oUF-based unit frames
- `action bar` and `chat` skinning/styling
- `minmap` modifications
- `bags` modifications
- `auras` modifications
- `tooltips` modifications
- utilities / helpers / miscellaneous

## Repository Submodules

Most submodules may be modified when needed.

`libs/oUF` is the exception: **Retail oUF is read-only**. Work around problems
in Tainted and report/document them.

## oUF

- `libs/oUF`: **Retail oUF. Do not modify.** [fork of upstream official oUF]
- `libs/oUF_Classic`: Classic oUF [branch: `classic`; used by Era/TBC/WotLK].
  Fixes allowed when needed.
- `libs/oUF_Mists`: MoP oUF [branch: `mop`; used by MoP]. Fixes allowed when needed.
- Do not merge/refactor the Classic and MoP implementations unless asked.
- Retail `oUF` updates are handled by me.

## Midnight (Retail) rules

- Some APIs return "secret" values: no arithmetic, comparison, string operations or
  table keys on them. Before using an API result in logic, check the generated API
  docs in `../_source/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated`.
- If you are unsure whether a function returns secrets or is restricted, say so.
  Don't guess.
- Tags and aura-based features are the most likely to be affected. Audit before fixing.

## Code Style

- Lua 5.1 / WoW runtime.
- Follow existing code style.
- Use prototype style where already used.
- Keep changes focused.
- No unrelated refactors, reformatting, or modernization.
- Avoid new globals.

## Testing

- Manual, in-game with `/reload`.
  After a change, tell me what to verify and on which game versions.
- Claude cannot run the game. I will paste Lua errors back to you.

## Reference repositories

The following repositories are outside this repository and are **read-only** reference material.

- `../_source/wow-ui-source`                    -> branch `live`    (Retail)
- `../_source/wow-ui-source/worktrees/classic`  -> branch `classic` (Classic Era)
- `../_source/wow-ui-source/worktrees/forever`  -> branch `forever` (Classic Forever)
- `../_source/Tukui`
- `../_source/ElvUI`
- `../_source/ls_UI`

Do not modify these repositories.

Use them when investigating WoW API, UI, template, event or compatibility behavior.

## Reference documentation
Where to look for API truth, in order:

1. The Blizzard UI source above, especially `Blizzard_APIDocumentationGenerated`
2. `docs/` files, once they exist (see below)
3. Wiki: `https://warcraft.wiki.gg/wiki/API:[NAME]`, e.g. `C_Spell.GetSpellInfo`
   and `https://warcraft.wiki.gg/wiki/Event:[NAME]`, e.g. `PLAYER_LOGIN`

If sources disagree, trust 1. Never invent an API. If you cannot verify it, mark it
"unverified" in your answer.

## Git Rules

- Allowed just **read-only** operations and commands.
- Allowed: `status`, `diff`, `log`, `show`, `blame`, `branch` (listing only),
  `worktree list`, `submodule status`.
- Forbidden: `push`, `commit`, `add`, `pull`, `fetch`, `merge`, `rebase`, `checkout`,
  `switch`, `stash`, `tag`, `cherry-pick`, `reset`, `restore`, `revert`, `clean`, and
  `submodule update/init/sync/add`.
- Do not use the GitHub CLI (`gh`).
