# Tainted UI Design

## Design goal

A dark, flat, compact UI that keeps the centre of the screen clear for the game world.
Everything sits in a few tight clusters at the screen edges and just below centre, built from
the same small set of parts: flat dark panels, 1px black borders, a plain bar texture and one
small font. Information appears next to what it describes and nowhere else.

## Relationship to Tukui

- Tukui is the primary visual and layout reference. Resembling it is intended.
- The goal is the same design language — composition, density, restraint — not a reproduction.
- Never copy Tukui's code, assets, architecture or implementation.
- Where Tainted differs from Tukui, that is not automatically a bug. The Tainted screenshots
  record Tainted's own established look; prefer them when the two disagree, unless the Tainted
  element is clearly broken or unfinished.

## Core principles

1. **Clear centre.** The middle of the screen belongs to the game. UI lives at the edges and in
   one compact combat cluster below centre.
2. **One panel style.** Every Tainted surface uses the same flat dark backdrop and 1px black
   border. No component gets its own look.
3. **Flat and restrained.** No gradients, glows, rounded corners, textured frames or ornaments.
   Colour is used for meaning, not decoration.
4. **Compact, not cramped.** Small consistent gaps between related elements; larger empty space
   between clusters.
5. **Information where it's needed.** Values sit on or right next to their bar/icon; no separate
   readouts, no labels for things the position already explains.
6. **Symmetry.** The layout mirrors around the vertical centre line (chats, unit frames,
   action bar groups).
7. **Show less.** Only what is useful during play. If Blizzard already shows it well enough and
   it's out of the way, leave it.

## Layout and density

- **Bottom-left / bottom-right:** two chat panels of equal size, mirrored, each with a datatext
  row along its bottom edge. They anchor the bottom corners.
- **Bottom-centre:** main action bars in a compact horizontal block, grouped side by side with
  equal gaps. Extra bars, if shown, go vertically on the right edge — not stacked higher in the
  centre.
- **Combat cluster (just above action bars):** player frame left of centre, target frame right
  of centre, small frames (target-of-target, castbar, class power) between or below them.
- **Raid/party frames:** a horizontal row at the left edge, above the left chat panel. For
  healers they move to the centre, between the player and target frames.
- **Top-right:** square minimap with a slim info strip below it (time, location). Player
  buffs/debuffs fill leftward from the minimap. The objective tracker sits beneath, on the
  right edge.
- **Tooltip:** anchored bottom-right, above the right chat panel — not following the cursor.
- **Top-left:** low-priority bars only — a utility action bar (bar 3, shown out of combat)
  and the stance bar. Otherwise kept empty.
- Spacing is a small set of repeated values (see `config/settings.lua`: `margin`, `spacing`).
  Use those; don't introduce one-off offsets.
- Align edges between neighbouring elements (frame widths matching the block they sit over,
  aura rows aligned to their frame). Elements in a cluster should read as one block.
- Density is high inside a cluster and low between clusters. Don't fill empty screen space
  just because it exists.

## Typography and information hierarchy

- One small, condensed, bold sans-serif family throughout (`core/assets.lua`, `core/fonts.lua`).
  Hierarchy comes from colour and position, rarely from size.
- Outlined text where it sits over bars, icons or the game world (unit frames, auras, action
  bars, tooltips); plain text inside panels (chat, datatexts).
- Unit frames: name centred, health value on one end, power value on the other. Short formats
  (`18.2m`, `43%`). Level/classification is a small prefix to the name.
- Auras: duration/count as small text on or under the icon, coloured by urgency; no timer bars.
- Datatexts: label + value, value coloured; three per panel, evenly spaced.
- No titles, headers or captions on Tainted's own frames. Blizzard-owned text (objective
  tracker headers, banners) is not Tainted's typography.

## Color and decoration

- Backdrop: flat dark grey, slightly transparent; border: 1px solid black. Values in
  `C.general` (`config/settings.lua`).
- Bars: plain flat texture. Unit-frame health is dark (monochrome) with colour carried by the
  text — name in class/reaction colour, values in health/power colour. This is a deliberate
  Tainted choice and differs from Tukui's coloured health fill; keep it.
- Colour has meaning: class, reaction, power type, debuff type, cast state
  (interruptible vs not), urgency. Palette in `core/colors.lua`; reuse it, don't add near-duplicates.
- Accent colour (`C.general.highlight`) only for hover/selection.
- Transparency is uniform across panels; inactive things (out of range, non-target nameplates)
  fade rather than hide or change style.
- Thin status strips are fine where they belong to a panel and stay thin: Tainted has one
  experience/reputation/honor strip above the left chat panel, chat-width and 8px tall. Tukui
  shows a strip above each chat panel; Tainted doesn't need to.

## Component principles

- **Unit frames:** short, wide bars with a thin power bar attached; player and target the same
  size, mirrored; secondary units smaller. No portraits by default, no decorative art.
- **Castbars:** detached, centred, with icon and text on the bar; colour reflects interruptibility.
- **Nameplates:** the same visual language as unit frames, smaller; auras above the bar.
- **Raid/party:** small uniform cells, compact grid, name only; status by colour and alpha.
  One large raid-debuff icon in the centre of the cell, with its border coloured by debuff
  type when the player can dispel it and red when they can't.
- **Action bars:** square icons, uniform size and gap, 1px border, hotkey/count in small
  outlined text. No bar backgrounds, art or gryphons.
- **Auras:** square icons in tidy rows, uniform size and gap, cropped icon with border;
  debuff border colour by type.
- **Minimap:** square, bordered, no Blizzard ring art or button clutter; info strip below.
- **Chat:** panel with tabs as plain text on top and datatexts at the bottom; no Blizzard
  chat frame art or button column.
- **Tooltips:** same panel style, fixed anchor, compact lines; extra info (IDs, etc.) only if
  small and useful.
- **Datatexts:** live inside the chat and minimap panels, never floating.

## Things to avoid

- Decorative textures, gradients, glows, shadows, rounded corners, Blizzard frame art.
- Components with their own border thickness, colour, backdrop or font.
- Spreading UI into the centre or top-centre of the screen; big floating frames.
- Duplicating information (e.g. the same value in two places, labels on self-explanatory values).
- Large text, many font sizes, or several font families.
- Bright, saturated fills over large areas (health fills, panel backgrounds).
- Adding visible elements "because Tukui has them".
- Treating every element in a screenshot as a requirement.

## Reading the reference images

Screenshots include things that are not Tainted design:

- **Blizzard UI:** objective tracker styling, boss/achievement banners, the cooldown-manager
  style icon grids near the character, encounter widgets.
- **Other addons:** damage meter in the right chat panel, aura/cooldown displays, spell-ID
  tooltip lines.

Tainted elements that are easy to misread:

- `tainted-header-reference`, top-left, row of 12 slots: action bar 3
  (`modules/actionbars/bar3.lua`), holding utility items/skills and shown only out of combat.
- `tainted-header-reference`, centre, five cells between player and target: raid frames in
  the healer position.
- `tainted-tank-reference`, left edge above the left chat panel, five large squares: raid
  frames in the default position. The purple skulls are raid-debuff icons (`oUF_RaidDebuffs`),
  red-bordered because the debuff can't be dispelled. In `tainted-header-reference` the same
  debuff has a blue (Magic) border because the mistweaver can dispel it.
- `tainted-tank-reference`, centre above the target-of-target, "1.6m / 18.2m - 8%": monk
  Stagger bar (`modules/unitframes/elements/stagger.lua`), at the class power anchor.
- `tainted-tank-reference`, bottom-right, red "Soul-Scribe 100.00%" bar: threat bar
  (`modules/miscellaneous/threatbar.lua`). It covers the right chat datatext row in combat.
- Both Tainted images, thin strip above the left chat panel: experience/reputation bar
  (`modules/blizzard/experience.lua`).
- `tukui-18-reference`, strips above both chat panels: Tukui's honor/reputation/experience bars.

## Reference images

- Tukui (inspiration): [images/tukui-18-reference.jpg](images/tukui-18-reference.jpg)
- Tainted, solo/tank: [images/tainted-tank-reference.jpg](images/tainted-tank-reference.jpg)
- Tainted, party: [images/tainted-header-reference.jpg](images/tainted-header-reference.jpg)

Not pixel specifications. Visual constants live in `core/colors.lua`, `core/fonts.lua`,
`core/assets.lua` and `C.general` in `config/settings.lua`.
