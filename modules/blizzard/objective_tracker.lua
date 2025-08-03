local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

local element_proto = {}

if E.isClassic then
    function element_proto:Load()
        local element = self

        hooksecurefunc("FramePositionDelegate_Override_QuestWatchFrameOffsets", function(anchorYStartValue, rightActionBars, buffsAnchorY)
            local QuestWatchFrame = _G.QuestWatchFrame
            if QuestWatchFrame then
                QuestWatchFrame:ClearAllPoints()
                QuestWatchFrame:SetPoint("TOPLEFT", element, 0, 0)
            end
        end)
    end
elseif E.isMoP then
    function element_proto:Load()
        local element = self

        local frame = _G.WatchFrame
        if frame then
            frame:SetMovable(true)
            frame:SetUserPlaced(true)
            frame:SetDontSavePosition(true)
            frame:SetClampedToScreen(false)
            frame:ClearAllPoints()
            frame:SetPoint("TOP", element)
            -- frame.ignoreFramePositionManager = true

            hooksecurefunc(frame, "SetPoint", function(_, _, parent)
                -- if InCombatLockdown() then return end
                if parent ~= element then
                    frame:ClearAllPoints()
                    frame:SetPoint("TOP", element)
                end
            end)
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
