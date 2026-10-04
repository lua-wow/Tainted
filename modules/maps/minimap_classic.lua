local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Minimap (Classic Era, TBC, MoP)
--------------------------------------------------
if not C.maps.enabled then return end
if E.isRetail or E.isForever then return end

local MODULE = E:GetModule("Minimap")

function MODULE:OnMouseClick(button)
    local Minimap = _G.Minimap
    -- vanilla has no tracking menu, so right-click pings like left-click
    local TrackingButton = _G.MiniMapTrackingButton
    if (button == "RightButton" and TrackingButton) then
        TrackingButton:SetMenuOpen(not TrackingButton:IsMenuOpen())
        if TrackingButton.menu then
            TrackingButton.menu:ClearAllPoints()
            TrackingButton.menu:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -5, 0)
        end
    else
        Minimap_OnClick(Minimap)
    end
end

function MODULE:StyleBlizzard()
    local Minimap = _G.Minimap

    Minimap:SetSize(180, 180)

    -- classic has no mouse wheel zoom and its zoom buttons are hidden with 'MinimapBackdrop'
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if (delta > 0) then
            _G.Minimap_ZoomIn()
        elseif (delta < 0) then
            _G.Minimap_ZoomOut()
        end
    end)

    local ToggleButton = _G.MinimapToggleButton
    if ToggleButton then
        ToggleButton:Hide()
    end

    -- mail icon
    do
        local frame = _G.MiniMapMailFrame
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        end
    end

    -- tracking icon (mining, herbalism, etc.)
    do
        local frame = _G.MiniMapTracking
        local button = _G.MiniMapTrackingButton
        if button then
            -- the tracking menu opens with right-click on the minimap.
            -- not hidden: the menu manager closes a menu whose owner isn't visible
            frame:SetParent(Minimap)
            frame:SetAlpha(0)
            button:EnableMouse(false)

            -- otherwise the menu manager closes the menu on mouse down and 'OnMouseUp' reopens it
            function Minimap:HandlesGlobalMouseEvent(mouseButton, event)
                return event == "GLOBAL_MOUSE_DOWN" and mouseButton == "RightButton"
            end
        elseif frame then
            frame:SetParent(Minimap)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, -30)
        end
    end

    -- looking for group icon
    do
        local frame = _G.LFGMinimapFrame or _G.MiniMapLFGFrame
        if frame then
            frame:SetParent(Minimap)
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
        end
    end

    -- instance difficulty icons
    for _, frame in next, { _G.MiniMapInstanceDifficulty, _G.GuildInstanceDifficulty } do
        frame:SetParent(Minimap)
        frame:ClearAllPoints()
        frame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -1, -1)
    end

    do
        local frame = _G.MiniMapChallengeMode
        if frame then
            frame:SetParent(Minimap)
            frame:ClearAllPoints()
            frame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -3, -3)
        end
    end

    do
        local frame = _G.MiniMapBattlefieldFrame
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
        end
    end
end
