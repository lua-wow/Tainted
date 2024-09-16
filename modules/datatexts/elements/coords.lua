local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local GetInstanceInfo = _G.GetInstanceInfo
local GetZoneText = _G.GetZoneText

-- Mine
local UPDATE_INTERVAL = 1
local DATATEXT_STRING = "%.2f, %.2f"
local NAME_STRING = "%s (%d)"

local MAP = L.MAP or "Map"
local ZONE = L.ZONE or "Zone"
local INSTANCE = L.INSTANCE

local coords_proto = {}

function coords_proto:CreateTooltip(tooltip)
    local map = self.mapID and NAME_STRING:format(self.mapName, self.mapID) or self.mapName
    tooltip:AddDoubleLine(MAP, map, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    if self.zoneName ~= self.mapName then
        tooltip:AddDoubleLine(ZONE, self.zoneName, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end
    tooltip:AddDoubleLine(INSTANCE, NAME_STRING:format(self.instanceName, self.instanceID), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
end

function coords_proto:OnUpdate(elapsed)
    self.updateInterval = self.updateInterval - (elapsed or 1)
    if self.updateInterval <= 0 then
        local name = nil
        local x, y = 0, 0

        local mapID = C_Map.GetBestMapForUnit(self.unit)
        if mapID then
            local position = C_Map.GetPlayerMapPosition(mapID, self.unit)
            if position then
                x, y = position:GetXY()
            end

            local info = C_Map.GetMapInfo(mapID)
            if info then
                name = info.name
            end
        else
            name = GetMinimapZoneText()
        end
        
        self.mapID = mapID
        self.mapName = name
        self.zoneName = GetZoneText()
        self.instanceName, _, _, _, _, _, _, self.instanceID = GetInstanceInfo()

        if self.Text then
            if (x and x > 0) and (y and y > 0) then
                self.Text:SetFormattedText(DATATEXT_STRING, x * 100, y * 100)
            else
                self.Text:SetText(self.color:WrapTextInColorCode(name))
            end
        end

        self.updateInterval = UPDATE_INTERVAL
    end
end

function coords_proto:Update()
    self:OnUpdate()
end

function coords_proto:Enable()
    self.updateInterval = 0
    self:SetScript("OnUpdate", self.OnUpdate)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:Show()
end

function coords_proto:Disable()
    self:SetScript("OnUpdate", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self:Hide()
end

MODULE:AddElement("Coords", coords_proto)
