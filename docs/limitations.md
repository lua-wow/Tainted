# Known limitations

-   **Classic bank:** items in the bank's own slots (not bank bags) can't be used in combat on Era, TBC,
    WotLK and MoP.
-   **Auras on Retail/Forever:** aura buttons show Blizzard's protected aura tooltip, so there is no spell ID line.
-   **Minimap on Forever:** toggling `rotateMinimap` brings back Blizzard's round mask until `/reload`.
-   **Announcers:** addons can't read the combat log on Retail and Forever, so the dispel announcer is
    Classic only. The interrupt announcer there names only the player's own interrupt spell (enemy name
    and spell are secret), stays silent when the enemy has no unit token (target, focus, nameplate,
    soft target), and can credit the player if a teammate's interrupt lands in the same frame as a
    player interrupt that hit nothing.
-   **Threat bar:** hidden while threat values are secret (Retail, Forever).
-   **Skyriding race tracker:** no longer part of Tainted; it is the standalone `Skyriding` addon.
-   **Action bars 6–8:** a changed `C.actionbars.bar6/7/8` can need a second `/reload`
    (`GetActionBarToggles` is stale until the server mirrors it).
-   **Retail raid debuffs:** Blizzard filters only, no spell lists; `RAID_PLAYER_DISPELLABLE` means
    dispellable by the group.
-   **Retail unit-frame auras:** every debuff gets a type border; no desaturated foreign debuffs, no
    dispellable flash.
-   **Durability and objective tracker:** placed by Tainted, so they can't be moved in Edit Mode.
-   **Dungeon portals:** spell data must be updated each season.
