local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Nameplates
--------------------------------------------------
UnitFrames.NameplateCVars = {
    nameplateMaxAlpha = 1,
    nameplateMinAlpha = C.unitframes.nameplate.minAlpha,
    nameplateSelectedAlpha = C.unitframes.nameplate.selectedAlpha,
    nameplateNotSelectedAlpha = C.unitframes.nameplate.notSelectedAlpha,
    nameplateOccludedAlphaMult = 1,
    nameplateMaxAlphaDistance = 0,
    nameplateMaxScale = 1,
    nameplateMinScale = 1,
    nameplateSelectedScale = C.unitframes.nameplate.selectedScale,
    nameplateMaxDistance = E.isRetail and 61 or 41
}

-- reference: https://github.com/trincasidra/TrincaUI/blob/main/unitframes/nameplate.lua
UnitFrames.NameplateCallback = function(self, event, unit)
    -- event == "PLAYER_TARGET_CHANGED"
    if (event == "NAME_PLATE_UNIT_ADDED") then
        self.blizzPlate = self:GetParent().UnitFrame
        self.widgetsOnly = UnitNameplateShowsWidgetsOnly(unit)
        self.widgetSet = UnitWidgetSet(unit)
        if (self.widgetsOnly) then
            self.Health:SetAlpha(0)
            self.widgetContainer = self.blizzPlate.WidgetContainer
            if (self.widgetContainer) then
                self.widgetContainer:SetScale(2.0)
                self.widgetContainer:SetParent(self)
                self.widgetContainer:ClearAllPoints()
                self.widgetContainer:SetPoint("BOTTOM", self, "BOTTOM")
            end
        end
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if (self.widgetsOnly and self.widgetContainer) then
            self.Health:SetAlpha(1)
            self.widgetContainer:SetParent(self.blizzPlate)
            self.widgetContainer:ClearAllPoints()
            self.widgetContainer:SetPoint('TOP', self.blizzPlate.castBar, 'BOTTOM')
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
