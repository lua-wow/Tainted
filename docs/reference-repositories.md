# Reference repositories

Local clones in `../refs`, outside this repo. **Read-only**: never edit, and no git write operations.
Use them when investigating WoW API, UI, template, event or compatibility behavior.

- Search, don't browse: targeted `Grep`/`Glob` scoped to one repo, addon and flavor dir.
  No recursive listings or whole-repo reads.
- Pick the worktree that matches the client in question before searching.

## Roles (priority order)

1. **`wow-ui-source`**: Blizzard's own UI source. Authoritative for how Blizzard UI and
   APIs actually work.
2. **`Tukui`**: **primary visual/layout reference** (the intended look itself is
   [design.md](design.md)). Secondary: a version-specific implementation reference for
   Retail, Classic Era and MoP, including Tukui's own maintained Classic oUF
   (`Tukui/Tukui/Libs/oUF`, vs `Libs/oUF_Retail` for Retail). Useful for Classic unit-frame behavior.
   **Understand and infer from it, never copy it.** No code, assets or architecture unless
   explicitly authorized.
3. **`ElvUI`**: broad technical reference for every client: API usage, compatibility
   handling, workarounds, event behavior, version differences. Always confirm the API
   applies to the Tainted client in question.
4. **`ls_UI`**: code-style, organization and implementation-pattern reference only.
   Outdated: never use it as authority for current API behavior.
5. `idTip`: minor; cross-client tooltip hooking.

If sources disagree, trust `wow-ui-source`. Never invent an API; if it can't be verified,
mark it "unverified". Wiki (after Blizzard source): `https://warcraft.wiki.gg/wiki/API:[NAME]`
(e.g. `C_Spell.GetSpellInfo`) and `https://warcraft.wiki.gg/wiki/Event:[NAME]` (e.g. `PLAYER_LOGIN`).

## `wow-ui-source` (Blizzard UI; authoritative)

| Path (`../refs/wow-ui-source/...`) | Branch                | Version (`version.txt`) | Client                       |
|------------------------------------|-----------------------|-------------------------|------------------------------|
| `.`                                | `live`                | 12.1.0                  | Retail/Midnight              |
| `worktrees/forever`                | `forever`             | 1.60.1                  | Classic Forever              |
| `worktrees/classic`                | `classic`             | 5.5.4                   | MoP Classic                  |
| `worktrees/classic_titan`          | `classic_titan`       | 3.80.2                  | WotLK (Titan)                |
| `worktrees/classic_anniversary`    | `classic_anniversary` | 2.5.6                   | TBC Anniversary              |
| `worktrees/classic_era`            | `classic_era`         | 1.15.9                  | Classic Era                  |

- Code lives in `Interface/AddOns/Blizzard_<Name>/<Flavor>/`. Flavor dirs: `Shared`,
  `Mainline`, `Classic`, `Vanilla`, `TBC`, `Wrath`, `Cata`, `Mists` (`Camelot` in forever).
  Every classic-family worktree contains all flavor dirs: don't infer the client from the dir.
  Instead read the per-flavor TOC (`*_Classic.toc`, `*_Mainline.toc`): each file line is tagged
  `[AllowLoadGameType vanilla|tbc|wrath|cata|mists]`.
- `classic_titan` is Tainted's WotLK target (see [compatibility.md](compatibility.md)).
  ElvUI/idTip target it as interface `38002`.
- API truth: `Interface/AddOns/Blizzard_APIDocumentationGenerated/*Documentation.lua`
  (check every worktree; APIs and secret flags differ per client).
- Removed/renamed APIs: `Interface/AddOns/Blizzard_Deprecated*`.
- Index of all addons/files: `Interface/ui-toc-list.txt`, `Interface/ui-code-list.txt`.

## Addon references (not API authority)

| Repo      | Clients (TOC `## Interface`)                            | Layout                                                                                                                                                              |
|:----------|:--------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ElvUI`   | Era, Forever, TBC, Wrath, MoP, Retail (11509…120105)    | `ElvUI/ElvUI/Game/Shared/{Modules,Tags,General}`; flavor overrides in `Game/<Flavor>/`; `Game/load_<flavor>.xml`; libs + oUF in `ElvUI/ElvUI_Libraries/Game/Shared` |
| `Tukui`   | Retail 110207, MoP 50501, Era 11507 (`Tukui-*.toc`)     | `Tukui/Tukui/Modules/<Feature>/`; `Libs/oUF` (classic) and `Libs/oUF_Retail` (Mainline TOC)                                                                         |
| `ls_UI`   | Retail only (110207)                                    | `ls_UI/ls_UI/modules/<feature>/`; `core/`; oUF in `embeds/oUF`                                                                                                      |
| `idTip`   | Era…Retail (11509…120105)                               | single file `idTip.lua`; cross-client tooltip hooks                                                                                                                 |

ElvUI and idTip ship `AGENTS.md`. Tukui (11.2.7) predates 12.x: don't trust it for
secret-value handling.

## Where to look, by Tainted feature

| Feature        | Blizzard (`Interface/AddOns/...`)                                                         | Addons                                                                                                 |
|----------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Minimap        | `Blizzard_Minimap`, `Blizzard_HybridMinimap` (retail)                                     | ElvUI `Shared/Modules/Maps/Minimap.lua`; Tukui `Modules/Maps/Minimap.lua`; ls_UI `modules/minimap`     |
| Action bars    | `Blizzard_ActionBar`, `Blizzard_ActionBarController`, `Blizzard_OverrideActionBar`        | ElvUI `Shared/Modules/ActionBars`; Tukui `Modules/ActionBars`; ls_UI `modules/bars`                    |
| Chat           | `Blizzard_ChatFrame`, `Blizzard_ChatFrameBase`, `Blizzard_ChatFrameUtil`                  | ElvUI `Shared/Modules/Chat`; Tukui `Modules/ChatFrames`                                                |
| Bags           | `Blizzard_UIPanels_Game/<Flavor>/ContainerFrame*.lua`, `Blizzard_MainMenuBarBagButtons`   | ElvUI `Shared/Modules/Bags`; Tukui `Modules/Inventory` (`Bags.lua`, `BagsRetail.lua`)                  |
| Auras          | `Blizzard_BuffFrame`, `Blizzard_AuraContainer` (retail), `Blizzard_PrivateAurasUI`        | ElvUI `Shared/Modules/Auras`; Tukui `Modules/Auras`; ls_UI `modules/auras`                             |
| Tooltips       | `Blizzard_GameTooltip`                                                                    | ElvUI `Shared/Modules/Tooltip`; Tukui `Modules/Tooltips`; ls_UI `modules/tooltips`; `idTip`            |
| Unit frames    | `Blizzard_UnitFrame`, `Blizzard_NamePlates`                                               | ElvUI `Shared/Modules/{UnitFrames,Nameplates}`; Tukui `Modules/UnitFrames`; ls_UI `modules/unitframes` |
| Tags           | —                                                                                         | ElvUI `Shared/Tags`; Tukui `Modules/UnitFrames/Tags.lua`                                               |
| Quest tracker  | retail `Blizzard_ObjectiveTracker`; classic `Blizzard_UIPanels_Game/Wrath/WatchFrame.lua` | ElvUI `Game/Mainline/Blizzard/ObjectiveFrame.lua`                                                      |
