local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Queue Status
--------------------------------------------------
function MODULE:UpdateQueueStatusFrame()
    local holder = CreateFrame("Frame", "TaintedQueueStatus", UIParent)
    holder:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    holder:SetSize(30, 30)
    -- holder:SetScale(0.65)

    local element = _G.QueueStatusButton
    if element then
        element:SetParent(holder)
        element:ClearAllPoints()
        element:SetAllPoints(holder)
        element:SetScale(0.65)

        hooksecurefunc(element, "SetPoint", function(self)
            self:SetAllPoints(holder)
        end)
    end

    local frame = _G.QueueStatusFrame
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("TOPRIGHT", element, "TOPLEFT", -5, 0)
        frame:StripTextures()
        frame:CreateBackdrop("transparent")

        if frame.NineSlice then
            frame.NineSlice:StripTextures()
        end
    end
end
