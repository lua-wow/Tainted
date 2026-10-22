local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

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
        element:SetTexture(A.icons.assistant)
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
-- Focus Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateFocusIndicator(frame, sublevel)
        if not E.isMainline then
            return nil
        end

        local element = CreateIndicator(frame, "FocusIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPRIGHT", 0, 0)
        element:SetTexture(A.icons.focus)
        return element
    end
end

--------------------------------------------------
-- Group Role Indicator
--------------------------------------------------
do
    local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
    local issecretvalue = _G.issecretvalue

    local textures = {
        TANK = A.icons.tank,
        HEALER = A.icons.healer,
        DAMAGER = A.icons.damage
    }

    local element_proto = {}

    -- replaces both oUF updates (Retail atlases, Classic tex coords) so every client shows the same icons
    function element_proto.Override(frame, event)
        local element = frame.GroupRoleIndicator
        local role = UnitGroupRolesAssigned(frame.__unit or frame.unit)
        -- secret while unit identity is restricted (Retail, Forever)
        local texture = not (issecretvalue and issecretvalue(role)) and textures[role]
        if texture then
            element:SetTexture(texture)
            element:Show()
        else
            element:Hide()
        end
    end

    function UnitFrames:CreateGroupRoleIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "GroupRoleIndicator", frame.Health, element_proto)
        element:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, 3)
        return element
    end
end

--------------------------------------------------
-- Happiness Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateHappinessIndicator(frame, sublevel)
        if not E.isMainline then
            return nil
        end

        local element = CreateIndicator(frame, "Happiness", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPRIGHT", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Leader Indicator
--------------------------------------------------
do
    local element_proto = {}

    -- oUF sets Blizzard's leader/guide texture on every update; replace it
    function element_proto:PostUpdate(isLeader)
        if isLeader then
            self:SetTexture(A.icons.leader)
            self:SetTexCoord(0, 1, 0, 1)
        end
    end

    function UnitFrames:CreateLeaderIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "LeaderIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPLEFT", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Master Looter Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateMasterLooterIndicator(frame, sublevel)
        if not E.isMainline then
            return nil
        end

        local element = CreateIndicator(frame, "MasterLooterIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPLEFT", 16, 0)
        return element
    end
end

--------------------------------------------------
-- Phase Indicator
--------------------------------------------------
do
    function UnitFrames:CreatePhaseIndicator(frame, sublevel)
        local element = CreateFrame("Frame", frame:GetName() .. "PhaseIndicator", frame)
        element:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        element:SetSize(20, 20)
        element:EnableMouse(true)

        local icon = element:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        element.Icon = icon

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

    local fallbacks = {
        [Enum.PvPUnitClassification.FlagCarrierHorde] = [[Interface\WorldStateFrame\HordeFlag]],
        [Enum.PvPUnitClassification.FlagCarrierAlliance] = [[Interface\WorldStateFrame\AllianceFlag]]
    }

    -- the nameplate flag atlases are missing on Classic (MoP verified), so SetAtlas leaves an empty texture
    function element_proto:PostUpdate(unit, class)
        if not self:IsShown() or self:GetAtlas() then return end
        local texture = fallbacks[class]
        if texture then
            self:SetTexture(texture)
            self:SetTexCoord(0, 1, 0, 1)
        else
            self:Hide()
        end
    end

    function UnitFrames:CreatePvPClassificationIndicator(frame, sublevel)
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
        -- oUF_Classic calls UnitHonorLevel unguarded
        if not E.isMainline then
            return nil
        end

        local element = CreateIndicator(frame, "PvPIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPRIGHT", -18, 0)
        return element
    end
end

--------------------------------------------------
-- Quest Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateQuestIndicator(frame, sublevel)
        if not E.isMainline then
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
        element:SetPoint("BOTTOM", frame.Health, "TOP", 0, 5)
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

    function element_proto:PostUpdate(isResting)
        local animation = self.Animation
        if not isResting then
            animation:Stop()
        elseif not animation:IsPlaying() then
            animation:Play()
        end
    end

    function UnitFrames:CreateRestingIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "RestingIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOPRIGHT", 0, 0)
        -- 4x2 sheet of 32x32 frames: z, zz, zzZ, each letter popping in small then full size
        element:SetTexture(A.icons.resting)

        local animation = element:CreateAnimationGroup()
        animation:SetLooping("REPEAT")

        local flipbook = animation:CreateAnimation("FlipBook")
        flipbook:SetFlipBookRows(2)
        flipbook:SetFlipBookColumns(4)
        flipbook:SetFlipBookFrames(8)
        flipbook:SetFlipBookFrameWidth(0)
        flipbook:SetFlipBookFrameHeight(0)
        flipbook:SetDuration(3.0)

        element.Animation = animation

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
        element:SetPoint("CENTER", frame.Health, "TOP", 0, 0)
        return element
    end
end

--------------------------------------------------
-- Summon Indicator
--------------------------------------------------
do
    local element_proto = {}

    function UnitFrames:CreateSummonIndicator(frame, sublevel)
        local element = CreateIndicator(frame, "SummonIndicator", frame.Health, element_proto)
        element:SetPoint("CENTER", frame.Health, "TOP", 0, 0)
        return element
    end
end
