local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Nameplates
--------------------------------------------------
local config = C.unitframes.nameplate

-- reference: https://warcraft.wiki.gg/wiki/Console_variables
UnitFrames.NameplateCVars = {
    nameplateMaxAlpha = 1.0,                                -- the max alpha of nameplates. default: 1.0
    nameplateMaxAlphaDistance = 40,                          -- the distance from the camera that nameplates will reach their maximum alpha. default: 40
    nameplateMaxScale = 1.0,                                -- the max scale of nameplates. default: 1.0
    nameplateMaxDistance = E.isRetail and 61 or 41,         -- the max distance to show nameplates. default: 40
    nameplateMinAlpha = config.minAlpha or 0.6,             -- the minimum alpha of nameplates. default: 0.6
    nameplateMinAlphaDistance = 10,                         -- the distance from the max distance that nameplates will reach their minimum alpha. default: 10
    nameplateMinScale = 0.8,                                -- the minimum scale of nameplates. default: 0.8
    nameplateMinScaleDistance = 10,                         -- the distance from the max distance that nameplates will reach their minimum scale. default: 10
    nameplateMotion = 0,                                    -- defines the movement/collision model for nameplates. detault: 2 (0 = overlapping, 1 = stacking, 2 = spreading)
    nameplateMotionSpeed = 0.025,                           -- controls the rate at which nameplate animates into their target locations [0.0-1.0] detault: 0.025
    nameplateSelectedAlpha = config.selectedAlpha or 1.0,   -- the alpha of the selected nameplate. detault: 1.0
    nameplateSelectedScale = config.selectedScale or 1.2,   -- the scale of the selected nameplate. detault: 1.2
    nameplateNotSelectedAlpha = (not E.isRetail) and config.notSelectedAlpha,
    nameplateOccludedAlphaMult = 0.4,                       -- alpha multiplier of nameplates for occluded targets. default: 0.4
    nameplateShowAll = 1,
    nameplateShowSelf = 0
}

local function UpdateAlpha(self, alpha)
    if self.Name then self.Name:SetAlpha(alpha) end
    if self.Health then self.Health:SetAlpha(alpha) end
    if self.Power then self.Power:SetAlpha(alpha) end
    if self.Backdrop then self.Backdrop:SetAlpha(alpha) end
    if self.Backdrop and self.Backdrop.Center then self.Backdrop.Center:SetAlpha(alpha) end
    if self.Backdrop and self.Backdrop.BottomEdge then self.Backdrop.BottomEdge:SetAlpha(alpha) end
end

-- reference: https://github.com/trincasidra/TrincaUI/blob/main/unitframes/nameplate.lua
UnitFrames.NameplateCallback = function(self, event, unit)
    if (event == "NAME_PLATE_UNIT_ADDED") then
        if unit then
            self.widgetsOnly = UnitNameplateShowsWidgetsOnly(unit)
            self.widgetSet = UnitWidgetSet(unit)
        end

        local blizzPlate = self:GetParent().UnitFrame
        if blizzPlate then
            self.blizzPlate = blizzPlate
            self.widgetContainer = self.blizzPlate.WidgetContainer
        end
        
        if self.widgetsOnly then
            UpdateAlpha(self, 0)
            if self.widgetContainer then
                self.widgetContainer:SetScale(2.0)
                self.widgetContainer:SetParent(self)
                self.widgetContainer:ClearAllPoints()
                self.widgetContainer:SetPoint("BOTTOM", self, "BOTTOM")
            end
        end
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if self.widgetContainer and self.widgetsOnly then
            UpdateAlpha(self, 1)
            self.widgetContainer:SetParent(self.blizzPlate)
            self.widgetContainer:ClearAllPoints()
            self.widgetContainer:SetPoint("TOP", self.blizzPlate.castBar, "BOTTOM")
        end
    end
end

local power_proto = {}

function power_proto:PostUpdate(unit, cur, min, max)
    local frame = self:GetParent()

	if not unit then
		unit = frame.unit
	end

	if not unit then return end

	if not cur then
		cur, max = UnitPower(unit), UnitPowerMax(unit)
	end

	local Power = frame.Power
	local Health = frame.Health
	local CastBar = frame.Castbar
	local IsPowerHidden = Power.IsHidden
    
    local offset = E.Scale(1)

	if (cur and cur == 0) and (max and max == 0) then
		if (not IsPowerHidden) then
			Health:ClearAllPoints()
			Health:SetPoint("TOP", 0, 0)
            Health:SetPoint("LEFT", 0, 0)
            Health:SetPoint("RIGHT", 0, 0)
            Health:SetPoint("BOTTOM", 0, 0)

			Power:SetAlpha(0)
			Power.IsHidden = true

			if (CastBar) then
				CastBar:ClearAllPoints()
				CastBar:SetSize(Health:GetWidth(), Power:GetHeight())
				CastBar:SetPoint("BOTTOM", Health, "BOTTOM", 0, 0)
			end
		end
	else
		if (IsPowerHidden) then
			Health:ClearAllPoints()
            Health:SetPoint("TOP", 0, 0)
            Health:SetPoint("LEFT", 0, 0)
            Health:SetPoint("RIGHT", 0, 0)
            Health:SetPoint("BOTTOM", 0, E.Scale(C.unitframes.power.height))

			if (CastBar) then
				CastBar:ClearAllPoints()
				CastBar:SetAllPoints(Power)
			end

			Power:SetAlpha(1)
			Power.IsHidden = false
		end
	end
end

function UnitFrames:CreateNameplateFrame(frame)
    frame:SetScale(UIParent:GetEffectiveScale())
    frame:SetPoint("CENTER", 0, 0)

    frame.Health = self:CreateHealth(frame)
    frame.HealthPrediction = self:CreateHealthPrediction(frame)
    frame.Power = Mixin(self:CreatePower(frame), power_proto)
    frame.Name = self:CreateName(frame, frame)
    frame.Castbar = self:CreateCastbar(frame)
    frame.Debuffs = self:CreateDebuffs(frame)
    frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(frame)
    frame.TargetIndicator = self:CreateTargetIndicator(frame)
    frame.QuestIndicator = self:CreateQuestIndicator(frame)
end
