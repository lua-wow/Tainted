# Reference repositories

Read-only clones in `../refs`, for WoW API, UI, template, event and compatibility questions. Search,
don't browse: targeted `Grep`/`Glob` scoped to one repo, addon and flavor dir, in the worktree matching
the client. No recursive listings or whole-repo reads.

**`wow-ui-source`** (Blizzard UI source) is authoritative and wins when sources disagree.

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
- `classic_titan` is the WotLK target.

## Where to look

Dirs under `Interface/AddOns/`.

| Feature       | Blizzard                                                                                    |
|:--------------|:--------------------------------------------------------------------------------------------|
| Minimap       | `Blizzard_Minimap`, `Blizzard_HybridMinimap` (retail)                                       |
| Action bars   | `Blizzard_ActionBar`, `Blizzard_ActionBarController`, `Blizzard_OverrideActionBar`          |
| Chat          | `Blizzard_ChatFrame`, `Blizzard_ChatFrameBase`, `Blizzard_ChatFrameUtil`                    |
| Bags          | `Blizzard_UIPanels_Game/<Flavor>/ContainerFrame*.lua`, `Blizzard_MainMenuBarBagButtons`     |
| Auras         | `Blizzard_BuffFrame`, `Blizzard_AuraContainer` (retail), `Blizzard_PrivateAurasUI`          |
| Tooltips      | `Blizzard_GameTooltip`                                                                      |
| Unit frames   | `Blizzard_UnitFrame`, `Blizzard_NamePlates`                                                 |
| Quest tracker | retail `Blizzard_ObjectiveTracker`; classic `Blizzard_UIPanels_Game/Wrath/WatchFrame.lua`   |
