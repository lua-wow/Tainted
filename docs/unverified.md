# Unverified in-game

-   Action bars on Retail and Forever (working on Classic clients); paging for druid/rogue forms on Forever.
-   House favor bar: tracked-house data.
-   Classic unit frames (`libs/oUF_Classic`, Retail oUF plus Classic compat): tested on MoP only. On Era,
    TBC and WotLK: unit frames, auras, castbar, combo points, runes (WotLK), pet happiness (Era/TBC).
    Arena preparation and specs (TBC, WotLK, MoP) and the PvP honor badge are untested on every client.

## Open

-   Two startup models: registry `Init` vs ~15 modules with their own login frame (errors not
    isolated). One model, or document both?
-   Modules find each other by global frame name and TOC order (chat/minimap → datatexts).
-   Pixel scale is computed at file load, before the UI scale is applied at login.
-   Classic nameplates use the Retail layout; restore the Classic one.
