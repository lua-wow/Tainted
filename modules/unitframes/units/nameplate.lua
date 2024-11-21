local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")
local Talents = E:GetModule("Talents")

local LibMobs = LibStub("LibMobs")
assert(LibMobs, "Unable to locate LibMobs")

-- Blizzard
local UnitGUID = _G.UnitGUID
local UnitThreatSituation = _G.UnitThreatSituation
local UnitSelectionType = _G.UnitSelectionType
local UnitIsConnected = _G.UnitIsConnected
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsPlayer = _G.UnitIsPlayer

-- Mine
local selectionTypes = {
	[0] = 0,
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = 9,
	-- [10] = 10, -- unavailable to players
	-- [11] = 11, -- unavailable to players
	-- [12] = 12, -- inconsistent due to bugs and its reliance on cvars
	[13] = 13,
}

--------------------------------------------------
-- Nameplates
--------------------------------------------------
local config = C.unitframes.nameplate

-- reference: https://warcraft.wiki.gg/wiki/Console_variables
UnitFrames.NameplateCVars = {
    nameplateMaxAlpha = 1.0,                                -- the max alpha of nameplates. default: 1.0
    nameplateMaxAlphaDistance = 40,                         -- the distance from the camera that nameplates will reach their maximum alpha. default: 40
    nameplateMaxScale = 1.0,                                -- the max scale of nameplates. default: 1.0
    nameplateMaxDistance = E.isRetail and 61 or 41,         -- the max distance to show nameplates. default: 40
    nameplateMinAlpha = config.minAlpha or 0.6,             -- the minimum alpha of nameplates. default: 0.6
    nameplateMinAlphaDistance = 10,                         -- the distance from the max distance that nameplates will reach their minimum alpha. default: 10
    nameplateMinScale = 0.8,                                -- the minimum scale of nameplates. default: 0.8
    nameplateMinScaleDistance = 10,                         -- the distance from the max distance that nameplates will reach their minimum scale. default: 10
    -- nameplateMotion = 1,                                    -- defines the movement/collision model for nameplates. detault: 2 (0 = overlapping, 1 = stacking, 2 = spreading)
    -- nameplateMotionSpeed = 0.025,                           -- controls the rate at which nameplate animates into their target locations [0.0-1.0] detault: 0.025
    nameplateSelectedAlpha = config.selectedAlpha or 1.0,   -- the alpha of the selected nameplate. detault: 1.0
    nameplateSelectedScale = config.selectedScale or 1.2,   -- the scale of the selected nameplate. detault: 1.2
    nameplateNotSelectedAlpha = (not E.isRetail) and config.notSelectedAlpha,
    nameplateOccludedAlphaMult = 0.4,                       -- alpha multiplier of nameplates for occluded targets. default: 0.4
    nameplateShowAll = 1,
    nameplateShowSelf = 0,

    nameplateMotion = 1,                                    -- defines the movement/collision model for nameplates. detault: 2 (0 = overlapping, 1 = stacking, 2 = spreading)
    nameplateMotionSpeed = 0.015,                           -- controls the rate at which nameplate animates into their target locations [0.0-1.0] detault: 0.025
    nameplateLargeBottomInset = 0.35,   -- the inset from the bottom (in screen percent) that large nameplates are clamped to. (default: 0.15)
    nameplateLargeTopInset = 0.20,      -- the inset from the top (in screen percent) that large nameplates are clamped to. (default: 0.10)
    nameplateOverlapH = 0.50,   -- percentage amount for horizontal overlap of nameplates (default: 0.80)
    nameplateOverlapV = 0.70,   -- percentage amount for vertical overlap of nameplates. (default: 0.10)
}

local function UpdateAlpha(self, alpha)
    if self.Name then self.Name:SetAlpha(alpha) end
    if self.Health then self.Health:SetAlpha(alpha) end
    if self.Power then self.Power:SetAlpha(alpha) end
    if self.TextParent then self.TextParent:SetAlpha(alpha) end
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

if not E.isRetail then
    UnitFrames.NameplateCallback = function(self, event, unit) end
end

local health_proto = {
    colorDisconnected = true,
    colorTapping = true,
    colorClass = true,
    colorReaction = false,
    colorThreat = true,
    colorSelection = true,
    considerSelectionInCombatHostile = true,
    colors = {
        ["caster"] = E.colors.fuchsia,
        ["frontal"] = E.colors.aqua,
        ["focus"] = E:CreateColor(0.72, 0.24, 0.93), -- E:CreateColor(0.56, 0.27, 0.68)
    }
}

function health_proto:UnitSelectionType(unit, considerHostile)
	if (considerHostile and UnitThreatSituation("player", unit)) then
		return 0
	end
    local selection = UnitSelectionType(unit, true)
    return selectionTypes[selection]
end

if E.isRetail then
    function health_proto:UpdateColor(event, unit)
        if (not unit or self.unit ~= unit) then return end
        
        local element = self.Health

        local isTank = Talents:IsTank()

        local threat = UnitThreatSituation("player", unit)
        local selection = element:UnitSelectionType(unit, element.considerSelectionInCombatHostile)
        local creatureRole = LibMobs:UnitRole(unit)

        local color
        if (element.colorDisconnected and not UnitIsConnected(unit)) then
            color = self.colors.disconnected
        elseif (element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
            color = self.colors.tapped
        elseif (element.colorThreat and not UnitPlayerControlled(unit) and threat) then
            if creatureRole and ((isTank and threat == 3) or (not isTank and threat == 0))  then
                color = element.colors[creatureRole] or self.colors.threat[threat]
            else
                color =  self.colors.threat[threat]
            end
        elseif (element.colorClass and (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
            or (element.colorClassNPC and not (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
            or (element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
            local _, class = UnitClass(unit)
            color = self.colors.class[class]
        elseif (element.colorSelection and selection) then
            if creatureRole and (selection == 0) then
                color = element.colors[creatureRole] or self.colors.selection[selection]
            else
                color = self.colors.selection[selection]
            end
        elseif (element.colorReaction and UnitReaction(unit, "player")) then
            color = self.colors.reaction[UnitReaction(unit, "player")]
        elseif (element.colorSmooth) then
            color = E:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
        elseif (element.colorHealth) then
            color = self.colors.health
        end

        if color then
            element:SetColor(color)
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

    local textParent = CreateFrame("Frame", nil, frame)
    textParent:SetAllPoints(frame)
    textParent:SetFrameLevel(frame:GetFrameLevel() + 8)
    frame.TextParent = textParent

    frame.Health = Mixin(self:CreateHealth(frame, textParent), health_proto)
    frame.Health.TempLoss:ClearAllPoints()
    frame.Health.TempLoss:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.Health.TempLoss:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.Health.TempLoss:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    frame.Health.TempLoss:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)

    frame.HealthPrediction = self:CreateHealthPrediction(frame)
    -- frame.Power = Mixin(self:CreatePower(frame, frame), power_proto)
    frame.Name = self:CreateName(frame, textParent)
    frame.Castbar = self:CreateCastbar(frame, frame)
    frame.Debuffs = self:CreateDebuffs(frame)
    frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(frame)
    frame.TargetIndicator = self:CreateTargetIndicator(frame)
    frame.QuestIndicator = self:CreateQuestIndicator(frame)
end
