# Compatibility

Authoritative for supported clients, TOC loading, oUF variants and secret values.
Other docs link here instead of repeating these facts.

## Supported clients

A single `Tainted.toc` serves every supported client (`## Interface: 120100, 16001, 11509, 20506, 38002, 50504`):

| Client          | Interface | Game type  | Family     | oUF                |
|:----------------|:----------|:-----------|:-----------|:-------------------|
| Retail/Midnight | `120100`  | `standard` | `mainline` | `libs\oUF`         |
| Classic Forever | `16001`   | `camelot`  | `mainline` | `libs\oUF`         |
| Classic Era     | `11509`   | `vanilla`  | `classic`  | `libs\oUF_Classic` |
| Classic TBC     | `20506`   | `tbc`      | `classic`  | `libs\oUF_Classic` |
| Classic WotLK   | `38002`   | `wrath`    | `classic`  | `libs\oUF_Classic` |
| Classic MoP     | `50504`   | `mists`    | `classic`  | `libs\oUF_Mists`   |

- WotLK is Titan 3.80.x (loads the `Wrath` flavor with `WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC`),
  not the retired 3.4.x Wrath Classic. Don't assume 3.4.x behavior.
- Cata is not supported.

## TOC rules

- Do not add client-specific TOCs (`Tainted_*.toc`); a suffixed TOC overrides `Tainted.toc` on its client.
- Shared files are untagged. Client-specific files are tagged per line with
  `[AllowLoadGameType ...]`, using the family (`mainline`, `classic`) or game types
  (`vanilla, tbc, wrath`, `mists`). Keep one ordered list; place variants where they load.
- `[Game]`/`[Family]` path variables are not used: variants are named files (`init_classic.xml`,
  `init_mists.xml`), not `<Game>\` directories.
- A condition whose tokens the client doesn't recognize is treated as satisfied. A `camelot`-only
  line would therefore also need `[ExcludeLoadGameType standard, classic]` (as ElvUI does).
- Per-game metadata (`## Title`, `## OptionalDeps`) uses the same `[AllowLoadGameType ...]` suffix.

## Current status

- Retail is being revived. Classic-only modules (bags, actionbars)
  are tagged `classic` in the TOC for now; drop the tag to enable them on Retail.
- Chat loads on all clients (one shared implementation, no per-client files).
- Datatexts load on all clients. An element's `Enable` returns `true` only if it can run on
  the client.
- Tooltips load on all clients: tooltip data post-calls where `GameTooltip.ProcessInfo` exists
  (Retail, Forever), `OnTooltipSet*` hooks elsewhere.
- Player auras: `SecureAuraHeaderTemplate` only exists on Classic (`modules/auras/classic`);
  mainline uses Blizzard's `AuraContainer` (`modules/auras/mainline`), which renders secret values itself.

## oUF variants

- `libs/oUF`: Retail oUF, fork of upstream. **Read-only** — work around problems in Tainted
  and report/document them. Updates are handled by the maintainer.
- `libs/oUF_Classic`: branch `classic` (Era/TBC/WotLK). Fixes allowed when needed.
- `libs/oUF_Mists`: branch `mop` (MoP). Fixes allowed when needed.
- Do not merge/refactor the Classic and MoP implementations unless asked.

## Runtime client checks

Flags in `core/init.lua` are named after the TOC game types and families
([TOC format](https://warcraft.wiki.gg/wiki/TOC_format)):

| Kind      | Flags                                                                                          | Meaning                                         |
|:----------|:-----------------------------------------------------------------------------------------------|:------------------------------------------------|
| Game type | `E.isStandard`, `E.isCamelot`, `E.isVanilla`, `E.isTBC`, `E.isWrath`, `E.isCata`, `E.isMists`, `E.isPlunderstorm` | exact `WOW_PROJECT_ID` (Forever is `WOW_PROJECT_CAMELOT`, not `WOW_PROJECT_MAINLINE`) |
| Family    | `E.isMainline`, `E.isClassic`                                                                   | TOC `mainline` / `classic` families             |

- Use family flags for API/UI-family differences; game flags only for game-specific content
  (spells, talents, a single client's frames).
- The oUF variant has no runtime flag: the TOC picks it. Code that depends on the oUF variant
  belongs in files tagged like the oUF line, or checks the game flags that match it.
- Some call sites still use game flags where a family is meant (e.g. `E.isStandard` for
  "mainline", `E.isVanilla` for "classic"); fix them as their rebuild item touches them.
- TOC path variables (`[Game]`, `[Family]`) work on all supported clients but are not used:
  variants split by oUF variant, not by game or family, and inline branches still need flags.

## Secret values (Midnight / Retail)

- Some APIs return "secret" values: no arithmetic, comparison, string operations or table keys
  on them.
- Before using an API result in logic, check the generated API docs
  (`Blizzard_APIDocumentationGenerated`, see [reference-repositories.md](reference-repositories.md))
  for the target client; APIs and secret flags differ per client.
- If unsure whether a function returns secrets or is restricted, say so. Don't guess.
- Tags and aura-based features are the most likely to be affected. Audit before fixing.
