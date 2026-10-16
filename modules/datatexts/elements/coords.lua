local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local GetInstanceInfo = _G.GetInstanceInfo
local GetSubZoneText = _G.GetSubZoneText
local GetZoneText = _G.GetZoneText
local InCombatLockdown = _G.InCombatLockdown
local IsFalling = _G.IsFalling
local IsInInstance = _G.IsInInstance
local IsShiftKeyDown = _G.IsShiftKeyDown

-- Mine
local UPDATE_INTERVAL = 0.2
local DATATEXT_STRING = "%.2f, %.2f"
local NO_COORDS_STRING = "--, --"
local NAME_STRING = "%s (%d)"
local INSTANCE_STRING = "%s - %s (%d)"

local MAP = L.MAP or "Map"
local ZONE = L.ZONE or "Zone"
local SUBZONE = L.SUBZONE or "Subzone"
local COORDINATES = L.COORDINATES or "Coordinates"
local INSTANCE = L.INSTANCE
local TOGGLE_WORLD_MAP_TEXT = L.TOGGLE_WORLD_MAP_TEXT
local PRINT_IDS_TEXT = L.PRINT_IDS_TEXT

local coords_proto = {}

function coords_proto:GetMapName()
    local info = self.mapID and C_Map.GetMapInfo(self.mapID)
    return info and info.name or GetMinimapZoneText()
end

function coords_proto:CreateTooltip(tooltip)
    local mapName = self:GetMapName()
    local map = self.mapID and NAME_STRING:format(mapName, self.mapID) or mapName
    tooltip:AddDoubleLine(MAP, map, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

    local zoneName = GetZoneText()
    if zoneName ~= mapName then
        tooltip:AddDoubleLine(ZONE, zoneName, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    local subZoneName = GetSubZoneText()
    if subZoneName and subZoneName ~= "" and subZoneName ~= zoneName and subZoneName ~= mapName then
        tooltip:AddDoubleLine(SUBZONE, subZoneName, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    if self.x then
        tooltip:AddDoubleLine(COORDINATES, DATATEXT_STRING:format(self.x * 100, self.y * 100), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    if IsInInstance() then
        local instanceName, _, _, difficultyName, _, _, _, instanceID = GetInstanceInfo()
        tooltip:AddDoubleLine(INSTANCE, INSTANCE_STRING:format(instanceName, difficultyName or "", instanceID), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOGGLE_WORLD_MAP_TEXT)
    tooltip:AddLine(PRINT_IDS_TEXT)
end

function coords_proto:PrintIDs()
    local instanceName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    E:print(("%s: %s (%s), %s: %s (%d)"):format(MAP, self:GetMapName(), tostring(self.mapID), INSTANCE, instanceName, instanceID))
end

function coords_proto:OnMouseDown()
    if IsShiftKeyDown() then
        self:PrintIDs()
    elseif InCombatLockdown() then
        E:print(ERR_NOT_IN_COMBAT)
    else
        ToggleWorldMap()
    end
end

-- returns true while the player has a position on the current map (none inside instances)
function coords_proto:UpdatePosition()
    local position = self.mapID and C_Map.GetPlayerMapPosition(self.mapID, self.unit)
    local x, y = 0, 0
    if position then
        x, y = position:GetXY()
    end

    if x > 0 and y > 0 then
        self.x, self.y = x, y
        self.Text:SetFormattedText(DATATEXT_STRING, x * 100, y * 100)
        return true
    end

    self.x, self.y = nil, nil
    self.Text:SetText(self.color:WrapTextInColorCode(NO_COORDS_STRING))
    return false
end

-- runs only while moving (or falling after stopping); stops itself otherwise
function coords_proto:OnUpdate(elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < UPDATE_INTERVAL then return end
    self.elapsed = 0

    if not self:UpdatePosition() or (not self.moving and not IsFalling()) then
        self:SetScript("OnUpdate", nil)
    end
end

function coords_proto:OnEvent(event)
    if event == "PLAYER_STARTED_MOVING" or event == "PLAYER_CONTROL_LOST" then
        self.moving = true
        if self.x then
            self:StartUpdates()
        end
    elseif event == "PLAYER_STOPPED_MOVING" or event == "PLAYER_CONTROL_GAINED" then
        self.moving = false
    else
        self.mapID = C_Map.GetBestMapForUnit(self.unit)
        -- crossing into a map with coordinates while already moving
        if self:UpdatePosition() and self.moving then
            self:StartUpdates()
        end
    end
end

function coords_proto:StartUpdates()
    self.elapsed = 0
    self:SetScript("OnUpdate", self.OnUpdate)
end

function coords_proto:Update()
    self:OnEvent("ForceUpdate")
end

function coords_proto:Enable()
    self.moving = false
    self.elapsed = 0
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("PLAYER_STARTED_MOVING")
    self:RegisterEvent("PLAYER_STOPPED_MOVING")
    self:RegisterEvent("PLAYER_CONTROL_LOST")
    self:RegisterEvent("PLAYER_CONTROL_GAINED")
    self:SetScript("OnEvent", self.OnEvent)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Update()
    return true
end

function coords_proto:Disable()
    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
    self:SetScript("OnUpdate", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Coords", coords_proto)
