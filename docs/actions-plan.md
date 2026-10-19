# GitHub Actions plan

CI for Tainted and the other `lua-wow` addons. Goals: catch mistakes before `/reload`, remove release and
patch-day chores, and keep GitHub usage low. Public repos run on standard runners for free, but jobs
still run only when they can find something.

Not planned: packaging on every push, Dependabot for submodules (updated by hand), store uploads (later).

## Overview

| # | What                  | Where                                    | Runs on                            |
|:--|:----------------------|:-----------------------------------------|:-----------------------------------|
| 1 | Lint and TOC check (done) | new action `lua-wow/toc-check` + `lint.yml` | push to `master`, PRs (path-filtered) |
| 2 | Interface bump PR     | `interface.yml` (third-party actions)    | monthly cron, manual               |
| 3 | Release guard (done)  | change to `lua-wow/packager`             | tag push (`release.yml`)           |

Order: 3 (smallest, existing action; done) → 1 (done) → 2.

## 1. Lint and TOC check (done)

Catches typos, accidental globals and missing files on every client, including ones not tested in-game.

### `lua-wow/toc-check` (composite action)

Inputs: `path` (addon root, default `.`). Fails with the list of missing files.

`check.sh`:

1. Find the single `*.toc` in `path` (same rule as the packager).
2. For each line that is not blank and not a `#` comment: strip trailing `[AllowLoad...]` directives, turn
   `\` into `/`, and `test -f` it relative to `path`. `[Family]`/`[Game]`/`[TextLocale]` paths pass if
   any folder matches (Filger uses `data\[Game]\`).
3. For each `.xml` (from the TOC or found recursively): drop `<!-- -->` comments, extract `file="..."`
   from `<Script>` and `<Include>`, resolve relative to that XML's folder, check it, and recurse into nested XML.
4. Print every missing path; exit 1 if any.

The runner is case-sensitive, so a case mismatch fails even though it loads on Windows. Intended.

### `lint.yml` in each addon

```yaml
name: Lint

on:
    push:
        branches: [master]
        paths: ['**.lua', '**.xml', '*.toc', '.luacheckrc', '.github/workflows/lint.yml']
    pull_request:
        paths: ['**.lua', '**.xml', '*.toc', '.luacheckrc', '.github/workflows/lint.yml']

jobs:
    check:
        runs-on: ubuntu-latest
        permissions:
            contents: read
        steps:
            - name: Checkout
              uses: actions/checkout@v7
              with:
                  submodules: recursive # TOC lists files inside submodules

            - name: Luacheck
              uses: lunarmodules/luacheck@v1

            - name: TOC check
              uses: lua-wow/toc-check@v1
```

Limitation: checks the repo, not the zip, so a TOC entry stripped by `exclude.lst` is not caught. Today
only `modules/blizzard/event_trace.lua` is excluded code; acceptable.

## 2. Interface bump PR

Removes tracking patch days and hand-editing `## Interface:`. The PR still gets tested in-game before merge.

No own action: `p3lim/toc-interface-updater` rewrites the TOC, `peter-evans/create-pull-request` opens
(or updates) the PR on branch `toc-bump`. Less code to maintain; Dependabot keeps both pinned majors fresh.

`toc-interface-updater` behavior (read from `update.sh`, v4.16):

- Fetches `https://us.version.battle.net/v2/products/<product>/versions`, row `us` (`cn` for Titan, which
  has no `us` row), drops the build and converts (`3.80.2` → `38002`, `12.1.5` → `120105`).
- Rewrites the whole `## Interface:` line in flavor order, unsorted: the `flavor` list must follow the
  TOC order or every run reorders it.
- Edits every `*.toc` down to `depth` (default 99): set `depth: '1'` so submodule TOCs are never touched.

Flavors, checked with `curl` on 2026-10-18 (all matched `Tainted.toc`):

| Flavor    | Product             | Live       | Interface |
|:----------|:--------------------|:-----------|:----------|
| `vanilla` | `wow_classic_era`   | `1.15.9`   | `11509`   |
| `tbc`     | `wow_anniversary`   | `2.5.6`    | `20506`   |
| `wrath`   | `wow_classic_titan` | `3.80.2`   | `38002`   |
| `mists`   | `wow_classic`       | `5.5.4`    | `50504`   |
| `retail`  | `wow`               | `12.1.5`   | `120105`  |
| `forever` | `wow_classic_beta`  | `1.60.1`   | `16001`   |

Caveat: `forever` reads `wow_classic_beta` ("temporary until we get close to release" in `update.sh`). If
Blizzard reuses that product for another Classic beta, the PR shows a wrong Forever value; reject it.

### `interface.yml` in each addon

See `.github/workflows/interface.yml`. Monthly cron plus `workflow_dispatch`; adjust `flavor` to the
clients in that addon's TOC, in TOC order.

The repo setting "Allow GitHub Actions to create and approve pull requests" must be enabled.

## 3. Release guard (done)

Avoids deleting and re-tagging a release shipped with the wrong version or no changelog entry.

### Change to `lua-wow/packager`

Not a wrapper action: the packager already reads the TOC and knows the tag, and the guard must run
before the release is created.

- New input `check-version` (default `false`, so existing `@v1` users keep working; ship as `v1.x`).
- When `true` and `github.ref_type == 'tag'`, before zipping:
  - `${TAG#v}` must equal the TOC `## Version:` value.
  - If `CHANGELOG.md` exists, it must contain `## [${TAG#v}]` (Keep a Changelog format).
  - Otherwise fail with a message saying which one is wrong.
- Optional, same change: print `unzip -Z1 "$file"` after zipping so the log shows what ships.
- Add a fixture case to `tests/` for match and mismatch.

Later option: write the tag into `## Version` while packaging so it is never edited by hand. That
changes the shipped TOC, so decide separately.

### `release.yml` in each addon

```yaml
            - name: Package
              uses: lua-wow/packager@v1
              with:
                  check-version: true
```

## Manual test build (optional)

To test packaging without a tag: a `workflow_dispatch` workflow running the packager with
`release: false` hard-coded (picking a tag as ref would otherwise publish) and `actions/upload-artifact`
with `retention-days: 3`.
