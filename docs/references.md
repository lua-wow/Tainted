# Reference repositories

Read-only clones in `../refs`, for WoW API, UI, template, event and compatibility questions. Search,
don't browse: targeted `Grep`/`Glob` scoped to one repo, addon and flavor dir, in the worktree matching
the client. No recursive listings or whole-repo reads.

## Roles (priority order)

1. **`wow-ui-source`**: Blizzard UI source; authoritative. Wins when sources disagree.
2. **`Tukui`**: primary visual/layout reference (intended look: [design.md](design.md)); also an
   implementation reference for Retail, Era and MoP, incl. its Classic oUF (`Libs/oUF`; Retail is
   `Libs/oUF_Retail`), useful for Classic unit frames. Understand, never copy code, assets or
   architecture unless explicitly authorized. 11.2.7 predates 12.x: don't trust it for secret values.
3. **`ElvUI`**: technical reference for every client (API usage, workarounds, events, version
   differences). Confirm the API applies to the Tainted client in question.
4. **`ls_UI`**: code style and patterns only; outdated, never an API authority.
5. `idTip`: cross-client tooltip hooking.

Wiki (after Blizzard source): `https://warcraft.wiki.gg/wiki/API:<Name>`, `.../wiki/Event:<NAME>`.

## `wow-ui-source`

| Path (`../refs/wow-ui-source/...`) | Branch                | Version | Client          |
|:-----------------------------------|:----------------------|:--------|:----------------|
| `.`                                | `live`                | 12.1.0  | Retail/Midnight |
| `worktrees/forever`                | `forever`             | 1.60.1  | Classic Forever |
| `worktrees/classic`                | `classic`             | 5.5.4   | MoP Classic     |
| `worktrees/classic_titan`          | `classic_titan`       | 3.80.2  | WotLK (Titan)   |
| `worktrees/classic_anniversary`    | `classic_anniversary` | 2.5.6   | TBC Anniversary |
| `worktrees/classic_era`            | `classic_era`         | 1.15.9  | Classic Era     |

- Code: `Interface/AddOns/Blizzard_<Name>/<Flavor>/` (`Shared`, `Mainline`, `Classic`, `Vanilla`, `TBC`,
  `Wrath`, `Cata`, `Mists`, `Camelot`). Classic-family worktrees contain all flavor dirs: the client is
  given by the per-flavor TOC (`*_Classic.toc`, `*_Mainline.toc`) line tags, not the dir.
- API truth: `Blizzard_APIDocumentationGenerated/*Documentation.lua`, per worktree (APIs and secret
  flags differ). Removed/renamed: `Blizzard_Deprecated*`. Indexes: `Interface/ui-toc-list.txt`,
  `Interface/ui-code-list.txt`.
- `classic_titan` is the WotLK target; ElvUI/idTip call it `38002`.

## Addon references

| Repo    | Clients                                    | Layout                                                                                          |
|:--------|:-------------------------------------------|:------------------------------------------------------------------------------------------------|
| `ElvUI` | Era…Retail (11509…120105)                  | `ElvUI/ElvUI/Game/Shared/{Modules,Tags,General}`, overrides `Game/<Flavor>/`; libs/oUF `ElvUI/ElvUI_Libraries/Game/Shared` |
| `Tukui` | Retail 110207, MoP 50501, Era 11507        | `Tukui/Tukui/Modules/<Feature>/`                                                                |
| `ls_UI` | Retail 110207                              | `ls_UI/ls_UI/modules/<feature>/`, `core/`, oUF `embeds/oUF`                                     |
| `idTip` | Era…Retail (11509…120105)                  | `idTip.lua`                                                                                     |

ElvUI and idTip ship `AGENTS.md`.

## Where to look

Blizzard dirs under `Interface/AddOns/`; addon paths relative to the layouts above.

| Feature     | Blizzard                                                                           | ElvUI `Shared/`             | Tukui `Modules/`              | ls_UI `modules/` |
|:------------|:-----------------------------------------------------------------------------------|:----------------------------|:------------------------------|:-----------------|
| Minimap     | `Blizzard_Minimap`, `Blizzard_HybridMinimap` (retail)                              | `Modules/Maps/Minimap.lua`  | `Maps/Minimap.lua`            | `minimap`        |
| Action bars | `Blizzard_ActionBar`, `Blizzard_ActionBarController`, `Blizzard_OverrideActionBar` | `Modules/ActionBars`        | `ActionBars`                  | `bars`           |
| Chat        | `Blizzard_ChatFrame`, `Blizzard_ChatFrameBase`, `Blizzard_ChatFrameUtil`           | `Modules/Chat`              | `ChatFrames`                  |                  |
| Bags        | `Blizzard_UIPanels_Game/<Flavor>/ContainerFrame*.lua`, `Blizzard_MainMenuBarBagButtons` | `Modules/Bags`         | `Inventory/Bags{,Retail}.lua` |                  |
| Auras       | `Blizzard_BuffFrame`, `Blizzard_AuraContainer` (retail), `Blizzard_PrivateAurasUI` | `Modules/Auras`             | `Auras`                       | `auras`          |
| Tooltips    | `Blizzard_GameTooltip` (also `idTip`)                                              | `Modules/Tooltip`           | `Tooltips`                    | `tooltips`       |
| Unit frames | `Blizzard_UnitFrame`, `Blizzard_NamePlates`                                        | `Modules/{UnitFrames,Nameplates}` | `UnitFrames`            | `unitframes`     |
| Tags        |                                                                                    | `Tags`                      | `UnitFrames/Tags.lua`         |                  |
| Quest tracker | retail `Blizzard_ObjectiveTracker`; classic `Blizzard_UIPanels_Game/Wrath/WatchFrame.lua` | `../Mainline/Blizzard/ObjectiveFrame.lua` |              |                  |
