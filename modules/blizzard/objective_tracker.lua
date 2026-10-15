local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

local element_proto = {}

if E.isClassic then
    local ObjectiveTracker_SetPoint = function(self, point, anchor, anchorPoint, x, y)
        -- only WatchFrame's secure item buttons make it protected; QuestWatchFrame (Era/TBC) has
        -- none and is laid out by the right container in combat too
        if InCombatLockdown() and self:IsProtected() then return end
        if anchor ~= self.holder then
            self:ClearAllPoints()
            self:SetPoint("TOP", self.holder)
        end
    end

    function element_proto:Load()
        local element = self

        local frame = _G.QuestWatchFrame or _G.WatchFrame
        if frame then
            -- WatchFrame is a layout child of UIParentRightManagedFrameContainer (layoutIndex), so every
            -- container Layout() re-anchors it, also in combat. Leaving the container stops that.
            -- Not our holder: WatchFrame_Update sizes it down to its parent's bottom.
            if frame == _G.WatchFrame then
                frame:SetParent(UIParent)
            end

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
    -- ObjectiveTrackerFrame is an Edit Mode system: SetPoint/ClearAllPoints are overrides, the originals
    -- are kept as *Base. Blizzard places it through the override (right container layout, Edit Mode);
    -- calling the originals skips our hook. Top and bottom anchors set the height, not UpdateHeight.
    local Reanchor = function(frame, holder)
        frame:ClearAllPointsBase()
        frame:SetPointBase("TOP", holder, "TOP", 0, 0)
        frame:SetPointBase("LEFT", holder, "LEFT", 0, 0)
        frame:SetPointBase("RIGHT", holder, "RIGHT", 0, 0)
        frame:SetPointBase("BOTTOM", _G.TaintedChatRight, "TOP", 0, C.chat.margin)
    end

    function element_proto:Load()
        local element = self

        local frame = _G.ObjectiveTrackerFrame
        if not frame then return end

        frame:SetClampedToScreen(false)

        -- placements skipped in combat are applied once it ends
        element:SetScript("OnEvent", function(holder)
            holder:UnregisterEvent("PLAYER_REGEN_ENABLED")
            Reanchor(frame, holder)
        end)

        hooksecurefunc(frame, "SetPoint", function(self)
            if InCombatLockdown() then
                element:RegisterEvent("PLAYER_REGEN_ENABLED")
                return
            end
            Reanchor(self, element)
        end)

        Reanchor(frame, element)
    end
end

local frame = Mixin(CreateFrame("Frame", "TaintedObjectiveTrackerContainer", UIParent), element_proto)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -210, -236)
frame:SetSize(260, 80)

MODULE.ObjectiveTracker = frame
