local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Queue Status
--------------------------------------------------
function MODULE:UpdateQueueStatusFrame()
    -- Blizzard anchors the tooltip to the eye on every client
    local frame = _G.QueueStatusFrame
    if frame then
        frame:StripTextures()
        frame:CreateBackdrop("transparent")

        if frame.NineSlice then
            frame.NineSlice:StripTextures()
        end
    end

    -- mainline only; Classic's eye is the minimap LFG frame (minimap_classic.lua)
    local element = _G.QueueStatusButton
    if not element then return end

    -- scaled on the holder: Edit Mode's eye size calls SetScale on the button
    local holder = CreateFrame("Frame", "TaintedQueueStatus", UIParent)
    holder:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    holder:SetSize(45, 45)
    holder:SetScale(0.65)

    element:SetParent(holder)
    element:ClearAllPoints()
    element:SetAllPoints(holder)

    hooksecurefunc(element, "SetPoint", function(self)
        self:ClearAllPoints()
        self:SetAllPoints(holder)
    end)
end
