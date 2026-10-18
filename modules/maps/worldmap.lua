local addon, ns = ...
local E, C, A, L = ns.E, ns.C, ns.A, ns.L
local MODULE = E:GetModule("Maps")

-- Blizzard
local WorldMapFrame = _G.WorldMapFrame

--------------------------------------------------
-- World Map
--------------------------------------------------
local WorldMap = CreateFrame("Frame", addon .. "WorldMap")

-- Classic's map canvas reads the raw cursor, assuming the map (ignoreParentScale) is at scale 1;
-- divide by its scale as Retail does, or the scaled map hovers/clicks the wrong zone.
local function GetCursorPosition()
    local x, y = _G.GetCursorPosition()
    local scale = WorldMapFrame:GetEffectiveScale()
    return x / scale, y / scale
end

function WorldMap:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) - elapsed

    if (self.elapsed < 0) then
        do
            local x, y = 0, 0

            -- player coords
            local uiMapID = C_Map.GetBestMapForUnit(self.unit)
            if (uiMapID) then
                local position = C_Map.GetPlayerMapPosition(uiMapID, self.unit)
                if (position) then
                    x, y = position:GetXY()
                end
            end

            if (x and x > 0) and (y and y > 0) then
                self.player:SetFormattedText("%s: %.2f, %.2f", PLAYER, x * 100, y * 100)
            else
                self.player:SetText(" ")
            end
        end

        do
            -- mouse coords
            local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
            
            if (x and x > 0 and x < 1) and (y and y > 0 and y < 1) then
                self.cursor:SetFormattedText("%s: %.2f, %.2f", L.CURSOR, x * 100, y * 100)
            else
                self.cursor:SetText(" ")
            end

        end

        self.elapsed = nil --self.UpdateEveryXSeconds
    end
end

function WorldMap:CreateCoords()
    local font = A.fonts.normal

    local element = CreateFrame("Frame", nil, WorldMapFrame)
    element:SetFrameLevel(90)

    -- the map canvas ends above a bottom strip shared with Track Quest (left) and,
    -- on MoP, Map Options (right) and the quest panel; keep both on one line in its centre.
    local player = element:CreateFontString(nil, "OVERLAY")
    player:SetPoint("RIGHT", WorldMapFrame, "BOTTOM", -8, 15)
    player:SetFont(font, 12, "THINOUTLINE")
    player:SetTextColor(1, 1, 1)
    player:SetText("")

    local cursor = element:CreateFontString(nil, "OVERLAY")
    cursor:SetPoint("LEFT", WorldMapFrame, "BOTTOM", 8, 15)
    cursor:SetFont(font, 12, "THINOUTLINE")
    cursor:SetTextColor(1, 1, 1)
    cursor:SetText("")

    element.unit = "player"
    element.player = player
    element.cursor = cursor

    return element
end

function WorldMap:SynchronizeDisplayState()
    if self:IsMaximized() then
        self:SetScale(C.maps.worldmap.scale or 0.80)
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    else
        self:SetScale(1)
    end
end

function WorldMap:Init()
    local BlackoutFrame = WorldMapFrame.BlackoutFrame
    if (BlackoutFrame) then
        BlackoutFrame:StripTextures()
        BlackoutFrame:EnableMouse(false)
    end

    hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", self.SynchronizeDisplayState)

    if (WorldMapFrame:IsIgnoringParentScale()) then
        WorldMapFrame.ScrollContainer.GetCursorPosition = GetCursorPosition
    end

    -- Retail/Forever have Blizzard's coords panel (worldMapShow*Coords CVars)
    if (C.maps.worldmap.coords and E.isClassic) then
        self.Coords = self:CreateCoords()
        self.Coords:SetScript("OnUpdate", self.OnUpdate)
    end
end

MODULE.WorldMap = WorldMap
