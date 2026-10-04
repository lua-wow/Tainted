local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

local element_proto = {}

if E.isVanilla or E.isTBC or E.isWrath or E.isMists then
    local ObjectiveTracker_SetPoint = function(self, point, anchor, anchorPoint, x, y)
        if InCombatLockdown() then return end
        if anchor ~= self.holder then
            self:ClearAllPoints()
            self:SetPoint("TOP", self.holder)
        end
    end

    function element_proto:Load()
        local element = self

        local frame = _G.QuestWatchFrame or _G.WatchFrame
        if frame then
            frame:SetMovable(true)
            frame:SetUserPlaced(true)
            frame:SetDontSavePosition(true)
            frame:SetClampedToScreen(false)
            frame:ClearAllPoints()
            frame:SetPoint("TOP", element)
            -- frame.ignoreFramePositionManager = true

            frame.holder = element

            hooksecurefunc(frame, "SetPoint", ObjectiveTracker_SetPoint)
        end
    end
else
    function element_proto:Load()
        local element = self

        local ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
        ObjectiveTrackerFrame:ClearAllPoints()
        ObjectiveTrackerFrame:SetPoint("TOPLEFT", element, 0, 0)
        ObjectiveTrackerFrame:SetClampedToScreen(false)
        ObjectiveTrackerFrame.ignoreFramePositionManager = true
        -- ObjectiveTrackerFrame.ignoreInLayout = true

        hooksecurefunc(ObjectiveTrackerFrame, "SetPoint", function(self, _, parent)
            if InCombatLockdown() then return end
            if parent ~= element then
                self:ClearAllPoints()
                self:SetPoint("TOPLEFT", element, 0, 0)
            end
        end)
    end
end

local frame = Mixin(CreateFrame("Frame", "TaintedObjectiveTrackerContainer", UIParent), element_proto)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -210, -236)
frame:SetSize(260, 80)

MODULE.ObjectiveTracker = frame
