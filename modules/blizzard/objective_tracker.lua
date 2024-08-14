local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

local frame = CreateFrame("Frame", "TaintedObjectiveTrackerContainer", UIParent)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -210, -236)
frame:SetSize(260, 80)

local ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
ObjectiveTrackerFrame:ClearAllPoints()
ObjectiveTrackerFrame:SetPoint("TOPLEFT", frame, 0, 0)
-- ObjectiveTrackerFrame:SetHeight(E.screenHeight - 520)
ObjectiveTrackerFrame:SetClampedToScreen(false)
ObjectiveTrackerFrame.ignoreFramePositionManager = true
-- ObjectiveTrackerFrame.ignoreInLayout = true

hooksecurefunc(ObjectiveTrackerFrame, "SetPoint", function(self, _, parent)
    if InCombatLockdown() then return end
    if parent ~= frame then
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", frame, 0, 0)
    end
end)
