# CLAUDE.md

`Tainted` - World of Warcraft addon, minimalistic UI.
Heavily influenced by `Tukui` addon and based on `oUF`.

**Status:** being revived after a long break (patch 11.2.5).
Expect broken code caused by changed/removed Blizzard APIs and from secret values.
Do not assume existing code is correct.

## Compatibility

A single `Tainted.toc` serves every supported client (`## Interface: 120100, 16001, 11509, 20506, 38002, 50504`):

| Client          | Interface | Game type  | Family     |
|-----------------|-----------|------------|------------|
| Retail/Midnight | `120100`  | `standard` | `mainline` |
| Classic Forever | `16001`   | `camelot`  | `mainline` |
| Classic Era     | `11509`   | `vanilla`  | `classic`  |
| Classic TBC     | `20506`   | `tbc`      | `classic`  |
| Classic WotLK   | `38002`   | `wrath`    | `classic`  |
| Classic MoP     | `50504`   | `mists`    | `classic`  |

WotLK is Titan 3.80.x, not the retired 3.4.x Wrath Classic. Cata is not supported.

TOC rules:
- Do not add client-specific TOCs (`Tainted_*.toc`); a suffixed TOC overrides `Tainted.toc` on its client.
- Shared files are untagged. Client-specific files are tagged per line with
  `[AllowLoadGameType ...]`, using the family (`mainline`, `classic`) or game types
  (`vanilla, tbc, wrath`, `mists`). Keep one ordered list; place variants where they load.
- oUF selection: `libs\oUF` (mainline), `libs\oUF_Classic` (vanilla, tbc, wrath), `libs\oUF_Mists` (mists).
- Classic-only modules (auras, bags, chat, actionbars, datatexts, tooltips) are tagged `classic`
  while Retail is being revived; drop the tag to enable them on Retail.
- `[Game]`/`[Family]` path variables are not used: variants are named files (`init_classic.xml`,
  `init_mists.xml`), not `<Game>\` directories.
- A condition whose tokens the client doesn't recognize is treated as satisfied. A `camelot`-only
  line would therefore also need `[ExcludeLoadGameType standard, classic]` (as ElvUI does).
- Per-game metadata (`## Title`, `## OptionalDeps`) uses the same `[AllowLoadGameType ...]` suffix.

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
  docs in `../refs/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated`.
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

## Reference repositories (`../refs`)

Local clones outside this repo. **Read-only**: never edit, and no git write operations.
Use them when investigating WoW API, UI, template, event or compatibility behavior.

- Search, don't browse: targeted `Grep`/`Glob` scoped to one repo, addon and flavor dir.
  No recursive listings or whole-repo reads.
- Pick the worktree that matches the client in question before searching.

### Reference roles (priority order)

1. **`wow-ui-source`**: Blizzard's own UI source. Authoritative for how Blizzard UI and
   APIs actually work.
2. **`Tukui`**: **primary visual/layout reference**. Tainted should look and feel like
   Tukui where appropriate.
   Secondary: a version-specific implementation reference for Retail, Classic Era,
   MoP and TBC, including Tukui's own maintained Classic oUF (`Tukui/Tukui/Libs/oUF`,
   vs `Libs/oUF_Retail` for Retail). Useful for Classic unit-frame behavior.
   **Rule: understand and infer from it, never copy it.** No code, assets or architecture
   unless explicitly authorized.
3. **`ElvUI`**: broad technical reference for every client: API usage, compatibility
   handling, workarounds, event behavior, version differences. Always confirm the API
   applies to the Tainted client in question.
4. **`ls_UI`**: code-style, organization and implementation-pattern reference only.
   Outdated (Retail 110207): never use it as authority for current API behavior.
5. `idTip`: minor; cross-client tooltip hooking.

### `wow-ui-source` (Blizzard UI; authoritative)

| Path (`../refs/wow-ui-source/...`) | Branch                | Version (`version.txt`) | Client                       |
|------------------------------------|-----------------------|-------------------------|------------------------------|
| `.`                                | `live`                | 12.1.0                  | Retail/Midnight              |
| `worktrees/forever`                | `forever`             | 1.60.1                  | Classic Forever              |
| `worktrees/classic`                | `classic`             | 5.5.4                   | MoP Classic                  |
| `worktrees/classic_titan`          | `classic_titan`       | 3.80.2                  | WotLK (Titan; see note)      |
| `worktrees/classic_anniversary`    | `classic_anniversary` | 2.5.6                   | TBC Anniversary              |
| `worktrees/classic_era`            | `classic_era`         | 1.15.9                  | Classic Era                  |

- Code lives in `Interface/AddOns/Blizzard_<Name>/<Flavor>/`. Flavor dirs: `Shared`,
  `Mainline`, `Classic`, `Vanilla`, `TBC`, `Wrath`, `Cata`, `Mists` (`Camelot` in forever).
  Every classic-family worktree contains all flavor dirs: don't infer the client from the dir.
  Instead read the per-flavor TOC (`*_Classic.toc`, `*_Mainline.toc`): each file line is tagged
  `[AllowLoadGameType vanilla|tbc|wrath|cata|mists]`.
- WotLK note: `classic_titan` is Tainted's WotLK target client (3.80.x, interface `38002`;
  loads the `Wrath` flavor with `WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC`). Not the
  retired 3.4.x Wrath Classic: don't assume 3.4.x behavior.
  ElvUI/idTip target it as interface `38002`.
- API truth: `Interface/AddOns/Blizzard_APIDocumentationGenerated/*Documentation.lua`
  (check every worktree; APIs and secret flags differ per client).
- Removed/renamed APIs: `Interface/AddOns/Blizzard_Deprecated*`.
- Index of all addons/files: `Interface/ui-toc-list.txt`, `Interface/ui-code-list.txt`.

### Addon references (not API authority; roles above)

| Repo      | Clients (TOC `## Interface`)                            | Layout                                                                                              |
|-----------|---------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `ElvUI`   | Era, Forever, TBC, Wrath, MoP, Retail (11509…120105)    | `ElvUI/ElvUI/Game/Shared/{Modules,Tags,General}`; flavor overrides in `Game/<Flavor>/`; `Game/load_<flavor>.xml`; libs + oUF in `ElvUI/ElvUI_Libraries/Game/Shared` |
| `Tukui`   | Retail 110207, MoP 50501, Era 11507 (`Tukui-*.toc`)     | `Tukui/Tukui/Modules/<Feature>/`; `Libs/oUF` (classic) and `Libs/oUF_Retail` (Mainline TOC)        |
| `ls_UI`   | Retail only (110207)                                    | `ls_UI/ls_UI/modules/<feature>/`; `core/`; oUF in `embeds/oUF`                                     |
| `idTip`   | Era…Retail (11509…120105)                               | single file `idTip.lua`; cross-client tooltip hooks                                                 |

ElvUI and idTip ship `AGENTS.md`. Tukui (11.2.7) predates 12.x: don't trust it for
secret-value handling.

### Where to look, by Tainted feature

| Feature        | Blizzard (`Interface/AddOns/...`)                                             | Addons                                                                                          |
|----------------|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| Minimap        | `Blizzard_Minimap`, `Blizzard_HybridMinimap` (retail)                          | ElvUI `Shared/Modules/Maps/Minimap.lua`; Tukui `Modules/Maps/Minimap.lua`; ls_UI `modules/minimap` |
| Action bars    | `Blizzard_ActionBar`, `Blizzard_ActionBarController`, `Blizzard_OverrideActionBar` | ElvUI `Shared/Modules/ActionBars`; Tukui `Modules/ActionBars`; ls_UI `modules/bars`             |
| Chat           | `Blizzard_ChatFrame`, `Blizzard_ChatFrameBase`, `Blizzard_ChatFrameUtil`      | ElvUI `Shared/Modules/Chat`; Tukui `Modules/ChatFrames`                                         |
| Bags           | `Blizzard_UIPanels_Game/<Flavor>/ContainerFrame*.lua`, `Blizzard_MainMenuBarBagButtons` | ElvUI `Shared/Modules/Bags`; Tukui `Modules/Inventory` (`Bags.lua`, `BagsRetail.lua`)  |
| Auras          | `Blizzard_BuffFrame`, `Blizzard_AuraContainer` (retail), `Blizzard_PrivateAurasUI` | ElvUI `Shared/Modules/Auras`; Tukui `Modules/Auras`; ls_UI `modules/auras`                  |
| Tooltips       | `Blizzard_GameTooltip`                                                        | ElvUI `Shared/Modules/Tooltip`; Tukui `Modules/Tooltips`; ls_UI `modules/tooltips`; `idTip`     |
| Unit frames    | `Blizzard_UnitFrame`, `Blizzard_NamePlates`                                   | ElvUI `Shared/Modules/{UnitFrames,Nameplates}`; Tukui `Modules/UnitFrames`; ls_UI `modules/unitframes` |
| Tags           | —                                                                             | ElvUI `Shared/Tags`; Tukui `Modules/UnitFrames/Tags.lua`                                        |
| Quest tracker  | retail `Blizzard_ObjectiveTracker`; classic `Blizzard_UIPanels_Game/Wrath/WatchFrame.lua` | ElvUI `Game/Mainline/Blizzard/ObjectiveFrame.lua`                                   |

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
