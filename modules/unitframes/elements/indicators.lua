local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

-- Blizzard
local UnitIsQuestBoss = _G.UnitIsQuestBoss

-- Mine
local ICON_SIZE = 20
local VERTEX_COLOR = { 0.69, 0.31, 0.31 }

local function CreateIndicator(frame, name, parent, element_proto, sublevel, size)
    local element = Mixin(parent:CreateTexture(frame:GetName() .. name, "OVERLAY", nil, sublevel or 7), element_proto)
    --element:SetPoint("CENTER", parent, "TOPLEFT", 0, 0)
    element:SetSize(size or 16, size or 16)
    return element
end

--------------------------------------------------
-- Assistant Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateAssistantIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "AssistantIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPLEFT", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Combat Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateCombatIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "CombatIndicator", frame.Health, element_proto)
        element:SetPoint("RIGHT", frame.Name, "LEFT", -5, 0)
        return element
    end
end

--------------------------------------------------
-- Group Role Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateGroupRoleIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "GroupRoleIndicator", frame.Health, element_proto)
        element:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, 3)
        return element
    end
end

--------------------------------------------------
-- Leader Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateLeaderIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "LeaderIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPLEFT", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Phase Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreatePhaseIndicator(frame, sublevel)
        if E.isClassic then
            return nil
        end
        
        local element = CreateFrame("Frame", frame:GetName() .. "PhaseIndicator", frame)
        element:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        element:SetSize(20, 20)
        element:EnableMouse(true)

        local icon = element:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        element.Icon = Icon

        return element
    end
end

--------------------------------------------------
-- PvP Classification Indicator
--------------------------------------------------
do
    local element_proto = {
        useAtlasSize = true
    }

    function UnitFrames:CreatePvPClassificationIndicator(frame, sublevel)
        if E.isClassic then
            return nil
        end

        local element = CreateIndicator(frame, "PvPClassificationIndicator", frame.Health, element_proto)
        element:SetPoint("LEFT", frame.Health, "RIGHT", 5, 0)
        return element
    end
end

--------------------------------------------------
-- PvP Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreatePvPIndicator(frame, sublevel)
        local holder = CreateFrame("Frame", frame:GetName() .. "PvPIndicator", parent)
        holder:SetPoint("CENTER", frame, "TOPRIGHT", 0, 0)
        holder:SetSize(16, 16)

        local element = Mixin(holder:CreateTexture(nil, "ARTWORK", nil, 0), element_proto)
        element:SetAllPoints()
        -- element:SetPoint("TOPLEFT", holder, "TOPLEFT", 10, -12)
        -- element:SetSize(30, 30)
        
        local banner = holder:CreateTexture(nil, "ARTWORK", nil, -1)
        banner:SetAllPoints()

        element.Holder = holder
        element.Banner = banner

        return element
    end
end

--------------------------------------------------
-- Quest Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateQuestIndicator(frame, sublevel)
        if E.isClassic then
            return nil
        end

        local element = CreateIndicator(frame, "QuestIndicator", frame, element_proto)
        element:SetPoint("LEFT", frame, "RIGHT", 5, 0)
        element:SetTexture([[Interface\QuestFrame\AutoQuest-Parts]])
        element:SetTexCoord(0.13476563, 0.17187500, 0.01562500, 0.53125000)
        return element
    end
end

--------------------------------------------------
-- Raid Role Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateRaidRoleIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "RaidRoleIndicator", frame, element_proto)
        element:SetPoint("BOTTOM", frame.Heatlth, "TOP", 0, 5)
        return element
    end
end

--------------------------------------------------
-- Raid Target Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateRaidTargetIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "RaidTargetIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOP", 0, 0)
        element:SetTexture(A.icons.raidtarget)
        return element
    end
end

--------------------------------------------------
-- Ready Check Indicator
--------------------------------------------------
do
    local element_proto = {
        finishedTime = 10,
        fadeTime = 1.5
        -- readyTexture = nil,
        -- notReadyTexture = nil,
        -- waitingTexture = nil
    }

    function UnitFrames:CreateReadyCheckIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "ReadyCheckIndicator", frame.Power, element_proto, 7, 14)
        element:SetPoint("CENTER", frame.Power, "CENTER", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Resting Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateRestingIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "RestingIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPRIGHT", 0, 0)
        element:SetTexture(A.icons.resting)
        return element
    end
end

--------------------------------------------------
-- Resurrect Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateResurrectIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "ResurrectIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Summon Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateSummonIndicator(frame, sublevel)
        if E.isClassic then
            return nil
        end

        local element = CreateIndicator(frame, "SummonIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)
        return element
    end
end
