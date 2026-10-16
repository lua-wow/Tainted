# Tainted UI Design

A dark, flat, compact UI that keeps the centre of the screen clear: a few tight clusters at the edges
and just below centre, built from flat dark panels, 1px black borders, a plain bar texture and one small
font. Information appears next to what it describes and nowhere else.

The Tainted screenshots below are the reference: they win unless an element is clearly broken or
unfinished.

## Principles

1. **Clear centre.** UI at the edges plus one compact combat cluster below centre. No big floating frames.
2. **One panel style.** Same flat dark backdrop, 1px black border, font for everything.
3. **Flat.** No gradients, glows, shadows, rounded corners, textures, Blizzard art. Colour for meaning only.
4. **Compact, not cramped.** Small gaps inside clusters, large empty space between them.
5. **Information where it's needed.** Values on or next to their bar/icon; no duplicates, no labels
   for what position explains.
6. **Symmetry** around the vertical centre (chats, unit frames, action bar groups).
7. **Show less.** Only what's useful in play; leave Blizzard UI that's fine and out of the way.

Also avoid: bright saturated fills over large areas, adding elements because another UI has them,
treating every element in a screenshot as a requirement.

## Layout

- **Bottom corners:** two equal, mirrored chat panels, each with a datatext row along the bottom.
- **Bottom-centre:** main action bars side by side, equal gaps. Extra bars go vertically on the right
  edge, not stacked higher in the centre.
- **Combat cluster (above action bars):** player left, target right, small frames (target-of-target,
  castbar, class power) between or below.
- **Raid/party:** horizontal row at the left edge above the left chat; for healers, centred between
  player and target.
- **Top-right:** square minimap, slim info strip below (time, location), buffs/debuffs filling leftward,
  objective tracker beneath on the right edge.
- **Tooltip:** fixed bottom-right, above the right chat.
- **Top-left:** only bar 3 (utility, out of combat) and the stance bar.
- Spacing only from `margin`/`spacing` in `config/settings.lua`; no one-off offsets. Align neighbouring
  edges (frame widths match the block below, aura rows match their frame).

## Typography

- One small, condensed, bold sans-serif (`core/assets.lua`, `core/fonts.lua`); hierarchy by colour and
  position, rarely size.
- Outlined over bars, icons and the world (unit frames, auras, action bars, tooltips); plain in panels
  (chat, datatexts).
- Unit frames: name centred, health one end, power the other; short formats (`1.5b`, `18.2m`, `1.5k`,
  `43%`); level/classification as a small name prefix.
- Auras: duration/count small on or under the icon, coloured by urgency; no timer bars.
- Datatexts: label + coloured value, three per panel, evenly spaced.
- No titles or captions on Tainted frames (Blizzard-owned text isn't Tainted's).

## Colour

- Backdrop flat dark grey, slightly transparent, uniform; values in `C.general`.
- Bars plain. Unit-frame health is dark/monochrome with colour in the text (name by class/reaction,
  values by health/power). Deliberately not a coloured fill; keep it.
- Meaningful colour: class, reaction, power, debuff type, cast interruptibility, urgency. Palette in
  `core/colors.lua`; no near-duplicates. `C.general.highlight` only for hover/selection.
- Inactive things (out of range, non-target nameplates) fade, not hide or restyle.
- One thin experience/reputation/honor strip above the left chat, chat-width, 8px.

## Components

- **Unit frames:** short wide bars, thin attached power bar; player and target same size, mirrored;
  secondary units smaller; no portraits.
- **Castbars:** detached, centred, icon and text on the bar.
- **Nameplates:** unit-frame style, smaller, auras above.
- **Raid/party:** small uniform cells, name only, status by colour/alpha. One large raid-debuff icon
  centred, border by debuff type if dispellable, red if not. Cell border: target (highlight), threat
  (yellow/orange/red), else black.
- **Action bars:** square icons, uniform size/gap, hotkey/count small outlined; no backgrounds or gryphons.
- **Auras:** square cropped icons in tidy rows; debuff border by type.
- **Minimap:** square, bordered, no ring art or button clutter.
- **Chat:** tabs as plain text on top, datatexts at the bottom; no Blizzard art or button column.
- **Tooltips:** compact lines; extra info (IDs) only if small and useful.
- **Datatexts:** only inside chat and minimap panels.

## Reference images

[tainted-tank-reference](images/tainted-tank-reference.jpg) (solo/tank),
[tainted-header-reference](images/tainted-header-reference.jpg) (party). Not pixel specs; constants
live in `core/colors.lua`, `core/fonts.lua`, `core/assets.lua`, `C.general`.

Not Tainted: Blizzard objective tracker styling, banners, cooldown-manager icon grids, encounter
widgets; other addons' damage meter (right chat), aura/cooldown displays, spell-ID tooltip lines.

Easy to misread:

- header, top-left row of 12: action bar 3 (`modules/actionbars/bar3.lua`), utility, out of combat only.
- header, five cells between player and target: raid frames, healer position.
- tank, five squares above left chat: raid frames, default position. Purple skulls are
  `oUF_RaidDebuffs` icons, red border = not dispellable; in header the same debuff is blue (Magic)
  because the mistweaver can dispel it.
- tank, "1.6m / 18.2m - 8%" above target-of-target: monk Stagger
  (`modules/unitframes/elements/stagger.lua`) at the class power anchor.
- tank, red "Soul-Scribe 100.00%" bottom-right: threat bar (`modules/miscellaneous/threatbar.lua`),
  covers the right chat datatexts in combat.
- Both Tainted images, strip above left chat: `modules/blizzard/experience.lua`.
