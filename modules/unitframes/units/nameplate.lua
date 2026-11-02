local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")
local Talents = E:GetModule("Talents")

local LibMobs = LibStub("LibMobs")
assert(LibMobs, "Unable to locate LibMobs")

-- Blizzard
local UnitThreatSituation = _G.UnitThreatSituation
local UnitSelectionType = _G.UnitSelectionType
local UnitIsConnected = _G.UnitIsConnected
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsPlayer = _G.UnitIsPlayer

local UnitNameplateShowsWidgetsOnly = _G.UnitNameplateShowsWidgetsOnly
local UnitWidgetSet = _G.UnitWidgetSet

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

local nameplates_proto = {}

-- reference: https://warcraft.wiki.gg/wiki/Console_variables
-- default-valued entries reset values stored by older Tainted versions
nameplates_proto.cvars = {
    nameplateMaxAlpha = 1.0,                                -- alpha at max distance, default 1.0
    nameplateMaxAlphaDistance = 40,                         -- distance for max alpha, default 40
    nameplateMinAlpha = config.minAlpha or 0.6,             -- alpha at min distance, default 0.6
    nameplateMinAlphaDistance = 10,                         -- distance for min alpha, default 10
    nameplateSelectedAlpha = config.selectedAlpha or 1.0,   -- target alpha, default 1.0
    nameplateOccludedAlphaMult = 0.4,                       -- occluded alpha multiplier, default 0.4

    nameplateMaxScale = 1.0,                                -- scale at max distance, default 1.0
    nameplateMinScale = 1.0,                                -- scale at min distance, default 0.8
    nameplateMinScaleDistance = 10,                         -- distance for min scale, default 10
    nameplateSelectedScale = config.selectedScale or 1.2,   -- target scale, default 1.2

    nameplateMaxDistance = E.isStandard and 61 or 41,       -- view distance, default 60 Retail, 41 MoP

    nameplateStackingTypes = { [Enum.NamePlateStackType.Enemy] = true }, -- bitfield, stack enemies; replaces nameplateMotion
    nameplateOverlapH = 0.50,                               -- horizontal overlap, default 0.8
    nameplateOverlapV = 1.10,                               -- vertical overlap, default 1.1

    nameplateShowAll = 1,                                   -- all unit types (pets, totems...), default 0
    nameplateShowSelf = 0,                                  -- personal resource display, default 0
    nameplateShowFriendlyNpcs = 0,                          -- friendly NPC plates
    nameplateShowOnlyNameForFriendlyPlayerUnits = 1,        -- name only, friendly player plates in instances are Blizzard-drawn; default 0
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

nameplates_proto.SetAddedCallback = function(self, event, unit)
    if unit then
        self.showWidgetsOnly = UnitNameplateShowsWidgetsOnly(unit)
        self.widgetSet = UnitWidgetSet(unit)
    end

    local parent = self:GetParent()
    local blizzPlate = parent.UnitFrame
    self.blizzPlate = blizzPlate
    self.widgetContainer = blizzPlate and blizzPlate.WidgetContainer or nil

    if self.widgetContainer then
        self.widgetContainer:SetIgnoreParentAlpha(true)
        self.widgetContainer:ClearAllPoints()
        self.widgetContainer:SetPoint("BOTTOM", self, "BOTTOM")
    end

    if self.showWidgetsOnly then
        UpdateAlpha(self, 0)
    else
        UpdateAlpha(self, 1)
    end
end

nameplates_proto.SetRemovedCallback = function(self, event, unit)
end

nameplates_proto.SetTargetCallback = function(self, event, unit)
    if self.widgetContainer then
        self.widgetContainer:ClearAllPoints()
        self.widgetContainer:SetPoint("TOP", self.blizzPlate.CastBarsContainer.castBar, "BOTTOM")
    end
end

UnitFrames.Nameplates = nameplates_proto

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

if E.isMainline then
    function health_proto:UpdateColor(event, unit)
        if (not unit or self.__unit ~= unit) then return end
        
        local element = self.Health

        -- local isTank = Talents:IsTank()
        local isTank = false

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
            if (issecretvalue(class)) then
                -- custom class colors can't be indexed by a secret class (same as Retail oUF)
                color = C_ClassColor.GetClassColor(class)
            else
                color = self.colors.class[class]
            end
        elseif (element.colorSelection and selection) then
            if creatureRole and (selection == 0) then
                color = element.colors[creatureRole] or self.colors.selection[selection]
            else
                color = self.colors.selection[selection]
            end
        elseif (element.colorReaction and UnitReaction(unit, "player")) then
            color = self.colors.reaction[UnitReaction(unit, "player")]
        elseif (element.colorSmooth and self.colors.health:GetCurve()) then
            color = element.values:EvaluateCurrentHealthPercent(self.colors.health:GetCurve())
        elseif (element.colorHealth) then
            color = self.colors.health
        end

        if color then
            element:SetColor(color)
        end
    end
elseif E.isMists then
    function health_proto:PostUpdateColor(unit)
        local element = self

        local isTank = Talents:IsTank()
        local creatureRole = LibMobs:UnitRole(unit)
        local creatureColor = element.colors[creatureRole]

        if isTank and creatureColor then
            local threat = UnitThreatSituation("player", unit)
            
            if not threat or threat == 0 or threat == 3 then
                element:SetColor(creatureColor)
            end
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

    frame.Name = self:CreateName(frame, textParent)
    frame.Castbar = self:CreateCastbar(frame, frame)
    frame.Debuffs = self:CreateDebuffs(frame)
    frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(frame)
    frame.TargetIndicator = self:CreateTargetIndicator(frame)
    frame.QuestIndicator = self:CreateQuestIndicator(frame)
end
