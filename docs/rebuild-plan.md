# Tainted rebuild plan

A living roadmap. Start a session with: "Continue with the next item in the Tainted rebuild plan."
Principles and workflow live in [CLAUDE.md](../CLAUDE.md); client facts in
[compatibility.md](compatibility.md). This file only records order, status and decisions.

Legend: **Observed** = seen in the code · **Recommended** = proposal, not yet agreed ·
**Decided** = agreed, don't re-litigate.

## 1. Current state

- Revived after a long maintenance gap. TOC, references and settings have been cleaned up.
- **Observed:** on Retail and Forever, only core, unit frames and maps (minimap/worldmap) load.
  Auras, bags, chat, action bars, datatexts and tooltips are tagged `classic`. Blizzard and
  miscellaneous only load on Classic and MoP.
- **Observed:** working: unit frames (most mature), minimap on all clients. Classic-only, not
  verified on Retail: chat, datatexts, action bars, auras, tooltips, Blizzard tweaks. Stub/WIP:
  bags (only the bag-slot bar loads).
- Constraints: one TOC for 6 clients; Retail oUF is read-only; Midnight secret values
  (see compatibility.md).

## 2. Rebuild principles

See CLAUDE.md → Philosophy and Changing code. These are the ones specific to the rebuild:

- Rebuild one subsystem at a time, in the order below. Fix code outside the current item only
  if it blocks this item.
- Keep the existing visual design ([design.md](design.md)). Prefer targeted fixes to rewrites.
- A subsystem that others anchor to must leave named, stable anchors when it's done.
- Enable a module on a new client only after it is verified there in-game.

## 3. Rebuild order

### 0. Core contract

**Status:** Not started · **Priority:** Critical · **Depends on:** —

**Objective:** settle what client flags mean and who owns startup side effects.

**Done when:**
- Flag meanings (game vs API family vs oUF variant) are documented in compatibility.md.
- Leaked or undefined globals reported by luacheck are fixed.
- Nothing else changes yet; affected call sites are fixed as each later item touches them.

### 1. Minimap

**Status:** Functional, not finalized · **Priority:** High · **Depends on:** 0

**Objective:** finalize the minimap as the anchor for auras, datatexts and Blizzard tweaks.

**Done when:**
- Looks the same on all 6 clients and matches design.md.
- `Minimap` and the minimap datatext strip are stable anchors.
- The strip is not an empty bar on clients without datatexts.
- No redundant updates.

### 2. Chat

**Status:** Classic only · **Priority:** High · **Depends on:** 0

**Objective:** chat panels on every client. They are the anchor for the left/right datatexts.

**Done when:**
- Loads on all clients with stable panel and datatext anchors.
- The first-run reset is owned by the chat module, not core.
- Chat history is preserved.

### 3. DataTexts

**Status:** Classic only · **Priority:** Medium · **Depends on:** 1, 2

**Objective:** bring the framework to every client, then each element one at a time.

**Done when:**
- Datatexts look up their holders explicitly.
- A missing provider (keystone, bags, action bars) disables that element without errors.

### 4. Action bars

**Status:** Classic only · **Priority:** High · **Depends on:** 0

**Objective:** working bars on Retail, including Edit Mode, without taint.

**Done when:**
- Loads on all clients.
- Core no longer touches action-bar settings.
- No global function overrides unless proven necessary.

### 5. Auras (player buffs/debuffs)

**Status:** Classic only · **Priority:** Medium · **Depends on:** 1

**Done when:** works on all clients, secret-value safe on Retail, no leaked globals.

### 6. Tooltips

**Status:** Classic only · **Priority:** Medium · **Depends on:** 0

**Done when:** works on all clients, using the tooltip data post-calls on Retail.

### 7. Blizzard UI tweaks

**Status:** Classic/MoP only · **Priority:** Low · **Depends on:** 1, 2

Experience, mirror timers, objective tracker, queue status, durability, ghost, talking head,
raid utility, widgets.

**Done when:** each tweak is either verified per client or explicitly dropped.

### 8. Bags

**Status:** Stub · **Priority:** Low · **Depends on:** 3 · **Needs a scope decision first**

### 9. Miscellaneous

**Status:** Classic/MoP only · **Priority:** Low · **Depends on:** 0

**Done when:** each feature has a keep/drop decision and a verified status per client.

### 10. Final compatibility audit

**Done when:**
- Every module loads on every client it's meant for.
- `make check` is clean of real bugs.
- This plan is up to date.

Unit frames continue in parallel as a leaf. Only item 0 touches them.

## 4. Known architectural risks (observed)

- **Ambiguous client flags.** `isRetail` is used both for Retail and for "mainline API".
  `isClassic` means Era only but is used for the whole classic family. Forever therefore takes
  wrong paths.
- **Implicit dependencies.** Modules find each other's frames by global name and rely on TOC
  order (chat/minimap → datatexts).
- **Core does module work.** It forces action-bar settings on Retail and triggers the chat reset.
- **Two startup models.** Some modules use the registry `Init`. About 15 others create their own
  frame and initialize on login. Errors in the second group aren't isolated.
- **Secret values / restricted APIs on Midnight.** Most likely to affect auras, tags, the combat
  log and tooltips.
- **Pixel scale timing.** It is computed at file load, before UI scale is applied at login.
  Unverified.

## 5. Deferred work (don't fix early)

- Registry cleanup: the unused `UpdateModules`, and Maps vs Minimap being two modules. Do this
  with item 1.
- Unit-frame raid-holder healer repositioning: currently dead machinery. Revisit with unit frames.
- Dead stubs (party unit, datatext template, `development.lua`, `event_trace.lua`): remove during
  item 10.
- Settings with no effect (`C.blizzard.ghost/talkinghead/raid_utility`, `C.bags.*`): resolve
  with their items.
- Mainline-only Blizzard/misc files are kept but unverified on 12.x. Leave them until items 7/9.
- Combat-log based dispels/interrupts on Retail. Check the API docs before reviving (item 9).
- Duplicate client detection inside the dispels/screenshots mini-addons. Handle with item 9.
- Visual refinements outside design.md.

## 6. Decisions

**Decided:**
- One TOC with per-line tags; no `Tainted_*.toc`.
- No in-game configuration.
- Retail oUF is read-only.

**Needs confirmation:**
- Item 0: one startup model for all modules, or keep both and document them?
- Item 1: on Retail/Forever, hide the minimap datatext strip until datatexts load there, or
  bring datatexts forward?
- Item 2 vs 4: which comes first on Retail, chat or action bars?
- Item 8: bags scope. Bag-slot bar only, or real bag/bank frames (new code)?
- Item 9: keep or drop each misc feature on Midnight.

## Completed

- [x] TOC/client compatibility consolidation
- [x] Reference repository documentation
- [x] Configuration/settings audit
- [x] Architecture audit
- [ ] 0. Core contract
