local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local MAX_TALENT_TABS = _G.MAX_TALENT_TABS or 3

local GetLootSpecialization = _G.GetLootSpecialization
local GetNumSpecGroups = _G.GetNumSpecGroups
local GetNumTalentGroups = _G.GetNumTalentGroups
local InCombatLockdown = _G.InCombatLockdown
local SetLootSpecialization = _G.SetLootSpecialization
local UnitClass = _G.UnitClass

-- Mine
local DATATEXT_STRING = "%s %s"
local LOOT_STRING = "%s / %s"
local TREE_STRING = "%s (%s)"
local NONE = "-"

local SPEC = L.SPEC or "Spec"
local SPECIALIZATION = _G.SPECIALIZATION or "Specialization"
local LOOT_SPEC = L.LOOT_SPEC or "Loot Spec"
local PRIMARY = _G.PRIMARY or "Primary"
local SECONDARY = _G.SECONDARY or "Secondary"
local TOGGLE_TALENTS_TEXT = L.TOGGLE_TALENTS_TEXT
local CHANGE_LOOT_SPEC_TEXT = L.CHANGE_LOOT_SPEC_TEXT
local SWITCH_SPEC_TEXT = L.SWITCH_SPEC_TEXT

-- mainline and mists have specializations and loot spec; older classic clients have talent trees
local hasSpecs = E.isMainline or E.isMists

local spec_proto = {}

-- class specializations as { id, name }, cached once the client returns them
function spec_proto:GetClassSpecs()
    if not self.specs then
        local specs = {}
        local classID = select(3, UnitClass(self.unit))
        for i = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
            local id, name = C_SpecializationInfo.GetSpecializationInfo(i)
            specs[i] = { id = id, name = name }
        end
        if #specs > 0 then
            self.specs = specs
        end
        return specs
    end
    return self.specs
end

function spec_proto:GetSpec(group)
    local index = C_SpecializationInfo.GetSpecialization(false, false, group)
    if not index or index == 0 then return end
    return C_SpecializationInfo.GetSpecializationInfo(index)
end

function spec_proto:GetSpecNameByID(specID)
    for _, spec in next, self:GetClassSpecs() do
        if spec.id == specID then
            return spec.name
        end
    end
end

-- points per tree for a talent group ("31/0/20") and the name of the tree with most points
function spec_proto:GetTalentTrees(group)
    local points, bestName, bestPoints = nil, nil, 0
    for i = 1, MAX_TALENT_TABS do
        local _, name, _, _, _, _, pointsSpent = C_SpecializationInfo.GetSpecializationInfo(i, false, false, nil, nil, group)
        pointsSpent = pointsSpent or 0
        points = points and (points .. "/" .. pointsSpent) or tostring(pointsSpent)
        if pointsSpent > bestPoints then
            bestName, bestPoints = name, pointsSpent
        end
    end
    return points, bestName
end

function spec_proto:GetNumGroups()
    if hasSpecs then
        return GetNumSpecGroups and GetNumSpecGroups(false) or 1
    end
    return GetNumTalentGroups and GetNumTalentGroups(false, false) or 1
end

function spec_proto:CreateTooltip(tooltip)
    local numGroups = self:GetNumGroups()
    local activeGroup = C_SpecializationInfo.GetActiveSpecGroup(false, false)

    if hasSpecs then
        tooltip:AddDoubleLine(SPECIALIZATION, self.specName or NONE, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        tooltip:AddDoubleLine(LOOT_SPEC, self.lootName or self.specName or NONE, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    if numGroups == 2 or not hasSpecs then
        if hasSpecs then
            tooltip:AddLine(" ")
        end
        for group = 1, numGroups do
            local value
            if hasSpecs then
                value = select(2, self:GetSpec(group)) or NONE
            else
                local points, name = self:GetTalentTrees(group)
                value = TREE_STRING:format(points, name or NONE)
            end
            -- active group in green, inactive in grey
            local r, g, b = 0.7, 0.7, 0.7
            if group == activeGroup then
                r, g, b = 0.0, 1.0, 0.0
            end
            tooltip:AddDoubleLine(group == 1 and PRIMARY or SECONDARY, value, 1.0, 1.0, 1.0, r, g, b)
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOGGLE_TALENTS_TEXT)
    if hasSpecs then
        tooltip:AddLine(CHANGE_LOOT_SPEC_TEXT)
    elseif numGroups == 2 then
        tooltip:AddLine(SWITCH_SPEC_TEXT)
    end
end

-- current spec -> each class spec -> current spec
function spec_proto:CycleLootSpec()
    local specs = self:GetClassSpecs()
    local current = GetLootSpecialization()
    local nextID = 0
    if current == 0 then
        nextID = specs[1] and specs[1].id or 0
    else
        for i, spec in next, specs do
            if spec.id == current then
                nextID = specs[i + 1] and specs[i + 1].id or 0
                break
            end
        end
    end
    SetLootSpecialization(nextID)
end

function spec_proto:OnMouseDown(button)
    if button == "RightButton" and hasSpecs then
        self:CycleLootSpec()
        return
    end

    if InCombatLockdown() then
        E:print(ERR_NOT_IN_COMBAT)
    elseif button == "RightButton" then
        if self:GetNumGroups() == 2 then
            local activeGroup = C_SpecializationInfo.GetActiveSpecGroup(false, false)
            C_SpecializationInfo.SetActiveSpecGroup(activeGroup == 1 and 2 or 1)
        end
    elseif E.isMainline then
        PlayerSpellsUtil.ToggleClassTalentOrSpecFrame()
    else
        ToggleTalentFrame()
    end
end

function spec_proto:OnEvent(event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= self.unit then return end

    local value
    if hasSpecs then
        local specID, specName = self:GetSpec()
        local lootID = GetLootSpecialization()
        self.specName = specName
        self.lootName = (lootID ~= 0 and lootID ~= specID) and self:GetSpecNameByID(lootID) or nil
        value = self.lootName and LOOT_STRING:format(specName or NONE, self.lootName) or specName
    else
        local _, name = self:GetTalentTrees(C_SpecializationInfo.GetActiveSpecGroup(false, false))
        value = name
    end

    if self.Text then
        self.Text:SetFormattedText(DATATEXT_STRING, SPEC, self.color:WrapTextInColorCode(value or NONE))
    end
end

function spec_proto:Update()
    self:OnEvent("ForceUpdate")
end

function spec_proto:Enable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    if hasSpecs then
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        self:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
    else
        self:RegisterEvent("CHARACTER_POINTS_CHANGED")
    end
    self:SetScript("OnEvent", self.OnEvent)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Update()
    return true
end

function spec_proto:Disable()
    if self.Text then
        self.Text:SetText("")
    end

    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Specialization", spec_proto)
