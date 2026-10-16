# Unverified in-game

-   Action bars on Retail and Forever (working on Classic clients); paging for druid/rogue forms on Forever.
-   House favor bar: tracked-house data.

## Open

-   Two startup models: registry `Init` vs ~15 modules with their own login frame (errors not
    isolated). One model, or document both?
-   Modules find each other by global frame name and TOC order (chat/minimap → datatexts).
-   Pixel scale is computed at file load, before the UI scale is applied at login.
