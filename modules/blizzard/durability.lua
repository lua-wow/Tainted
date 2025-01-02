local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Durability
--------------------------------------------------
local Durability = {}

function Durability:Init()
    local frame = _G.DurabilityFrame
    if frame then
        local DurabilityFrame_SetPoint = frame.SetPoint

        function frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
            if relativeTo == "MinimapCluster" or relativeTo == _G.MinimapCluster then
                point = "TOPRIGHT"
                relativeTo = _G["TaintedMinimapDataText"] or _G.Minimap
                relativePoint = "BOTTOMRIGHT"
                xOffset = 0
                yOffset = -5
            end

            DurabilityFrame_SetPoint(self, point, relativeTo, relativePoint, xOffset, yOffset)
        end
    end
end

MODULE.Durability = Durability