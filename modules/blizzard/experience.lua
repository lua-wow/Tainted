local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Blizzard
local MAX_REPUTATION_REACTION = _G.MAX_REPUTATION_REACTION or 8

local GameLimitedMode_GetLevelLimit = _G.GameLimitedMode_GetLevelLimit
local GameLimitedMode_IsBankedXPActive = _G.GameLimitedMode_IsBankedXPActive
local GetMaxLevelForPlayerExpansion = _G.GetMaxLevelForPlayerExpansion
local GetRestState = _G.GetRestState
local GetXPExhaustion = _G.GetXPExhaustion
local UnitHonor = _G.UnitHonor
local UnitHonorLevel = _G.UnitHonorLevel
local UnitHonorMax = _G.UnitHonorMax
local UnitLevel = _G.UnitLevel
local UnitTrialBankedLevels = _G.UnitTrialBankedLevels
local UnitTrialXP = _G.UnitTrialXP
local UnitXPMax = _G.UnitXPMax

-- Mine
local bars = {}

local EXP_PATTERN = "%d / %d (%.1f%%)"
local RESTED_PATTERN = "+%d (%.1f%%)"

local EXPERIENCE = _G.COMBAT_XP_GAIN or "Experience"
local REPUTATION = _G.REPUTATION or "Reputation"
local HONOR = _G.HONOR or "Honor"
local RANK = _G.RANK or "Rank"
local ARTIFACT = "Artifact"
local AZERITE = "Azerite"
local ANIMA = _G.POWER_TYPE_ANIMA or "Anima"
local RESTED = _G.TUTORIAL_TITLE26 or "Rested"

local BarsEnum = {
    Experience = 1,
	Reputation = 2,
	Honor = 3,
	Artifact = 4,
	Azerite = 5,
	Anima = 6,
	PetExperience = 7,
    -- others
	None = -1,
	Rested = 0,
    Renown = 8,
}

local BarPriorities = {
	[BarsEnum.Experience] = 0,
	[BarsEnum.Reputation] = 1,
	[BarsEnum.Honor] = 2,
	[BarsEnum.Azerite] = 3,
	[BarsEnum.Artifact] = 4,
	[BarsEnum.PetExperience] = 5
}

local BarColors = {
    [BarsEnum.Experience] = E:CreateColor(0.00, 0.50, 1.00),
    [BarsEnum.Rested] = E:CreateColor(0.40, 0.20, 0.80),
    [BarsEnum.Honor] = E:CreateColor(0.87, 0.09, 0.09),
    [BarsEnum.Azerite] = E:CreateColor(0.90, 0.80, 0.50),
    [BarsEnum.Artifact] = E:CreateColor(0.90, 0.80, 0.50),
    [BarsEnum.Anima] = E:CreateColor(0.60, 0.80, 1.00),
    [BarsEnum.PetExperience] = E:CreateColor(1.00, 1.00, 0.41),
    [BarsEnum.Renown] = E:CreateColor(0.36, 0.68, 0.87),
}

local FACTION_STANDING = {
    [0] = _G.UNKNOWN,
    [1] = _G.FACTION_STANDING_LABEL1,
    [2] = _G.FACTION_STANDING_LABEL2,
    [3] = _G.FACTION_STANDING_LABEL3,
    [4] = _G.FACTION_STANDING_LABEL4,
    [5] = _G.FACTION_STANDING_LABEL5,
    [6] = _G.FACTION_STANDING_LABEL6,
    [7] = _G.FACTION_STANDING_LABEL7,
    [8] = _G.FACTION_STANDING_LABEL8
}

local element_proto = {
    min = 0
}

function element_proto:SetTooltip(tooltip)
    E:print("SetTooltip", self:GetName(), tooltip)
end

function element_proto:OnEnter()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
    self:SetTooltip(tooltip)
    tooltip:Show()
end

function element_proto:OnLeave()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:Hide()
end

function element_proto:UpdateStatusBar(current, min, max, rested)
    if self.Exp then
        self.Exp:SetMinMaxValues(min or 0, max or 1)
        self.Exp:SetValue(current or 0)
    end

    if self.Rested then
        self.Rested:SetMinMaxValues(min or 0, max or 1)
        self.Rested:SetValue(current + rested)
    end
end

function element_proto:UpdateColor(color)
    if not color then return end
    
    local exp = self.Exp
    if exp then
        exp:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    end
        
    local bg = self.bg
    if bg then
        local mu = bg.multiplier or 1
        bg:SetVertexColor(mu * color.r, mu * color.g, mu * color.b, color.a or 1)
    end
end

function element_proto:CalculatePercentage(value, max)
    if not max or max == 0 then
        return 0
    end
    return ((value or 0) / max) * 100
end

local EnableBar = function(enum)
    for index, bar in next, bars do
        if index == enum then
            if not bar:IsShown() then
                bar:Show()
            end
            E:SetExperienceBarIndex(enum)
        else
            if bar:IsShown() then
                bar:Hide()
            end
        end
    end
end

local EnableBarCallback = function(value)
    return function()
    end
end

function element_proto:OnMouseUp(...)
    if MenuUtil then

        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            rootDescription:CreateButton(EXPERIENCE, function() EnableBar(BarsEnum.Experience) end)
            rootDescription:CreateButton(REPUTATION, function() EnableBar(BarsEnum.Reputation) end)
            rootDescription:CreateButton(HONOR, function() EnableBar(BarsEnum.Honor) end)
            rootDescription:CreateButton(ARTIFACT, function() EnableBar(BarsEnum.Artifact) end)
            rootDescription:CreateButton(AZERITE, function() EnableBar(BarsEnum.Azerite) end)
            rootDescription:CreateButton(ANIMA, function() EnableBar(BarsEnum.Anima) end)
        end)
    end
end

--------------------------------------------------
-- Experience
--------------------------------------------------
local experience_proto = Mixin({ unit = "player" }, element_proto)

do
    function experience_proto:GetMaxLevel()
        return GetMaxLevelForPlayerExpansion()
    end

    function experience_proto:IsCapped()
        if GameLimitedMode_IsBankedXPActive() then
            local restrictedLevel = GameLimitedMode_GetLevelLimit()
            return UnitLevel(self.unit) >= restrictedLevel
        end

        return false;
    end

    function experience_proto:IsMaxLevel()
        local level = UnitLevel(self.unit)
        return level == self:GetMaxLevel()
    end

    function experience_proto:GetLevelData()
        local currXP = self:IsCapped() and UnitTrialXP(self.unit) or UnitXP(self.unit)
        local nextXP = UnitXPMax(self.unit)
        local level = UnitLevel(self.unit)
        local bankedLevels, xpIntoCurrentLevel, xpForNextLevel = UnitTrialBankedLevels(self.unit)

        return currXP, nextXP, level, bankedLevels;
    end

    function experience_proto:Update()
        local exhaustionID, name, factor = GetRestState()
        local exhaustion = GetXPExhaustion()
        local currXP, nextXP, level, bankedLevels = self:GetLevelData()

        self.currXP = currXP or 0
        self.nextXP = nextXP or 0
        self.level = level or -1
        self.bankedLevels = bankedLevels
        self.restedXP = exhaustion or 0
        self.isRested = (exhaustionID == 1)
        self.percentage = self:CalculatePercentage(self.currXP, self.nextXP)

        self:UpdateStatusBar(self.currXP, 0, self.nextXP, self.restedXP)
    end

    function experience_proto:SetTooltip(tooltip)
        local color = BarColors[BarsEnum.Experience]

        tooltip:AddDoubleLine(LEVEL, self.level)
        
        if not self:IsCapped() then
            tooltip:AddDoubleLine(color:WrapTextInColorCode(XP .. ":"), EXP_PATTERN:format(self.currXP, self.nextXP, self.percentage))

            if (self.isRested and self.restedXP > 0) then
                local restedColor = BarColors[BarsEnum.Rested]
                local restedPercentage = self:CalculatePercentage(self.restedXP, self.nextXP)
                GameTooltip:AddDoubleLine(color:WrapTextInColorCode(RESTED .. ":"), RESTED_PATTERN:format(self.restedXP, restedPercentage))
            end
        end
    end
end

--------------------------------------------------
-- Reputation
--------------------------------------------------
local reputation_proto = Mixin({}, element_proto)

do
    function reputation_proto:Update()
        local watchedFactionData = C_Reputation.GetWatchedFactionData();
        if watchedFactionData and watchedFactionData.factionID ~= 0 then
            self.factionID = watchedFactionData.factionID
            self.name = watchedFactionData.name
            self.level = watchedFactionData.reaction
            self.minBar = watchedFactionData.currentReactionThreshold
            self.maxBar = watchedFactionData.nextReactionThreshold
            self.value = watchedFactionData.currentStanding

            local reputationInfo = C_GossipInfo.GetFriendshipReputation(self.factionID)
            self.friendshipID = reputationInfo and reputationInfo.friendshipFactionID

            if C_Reputation.IsFactionParagon(self.factionID) then
                local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(self.factionID)
                self.minBar = 0
                self.maxBar = threshold
                self.value = currentValue % threshold
                self.maxLevel = nil
                -- self.level = self.maxLevel
                if hasRewardPending then
                    self.value = self.value + threshold
                end
                
                if C_Reputation.IsMajorFaction(self.factionID) then
                    -- overrideUseBlueBarAtlases = true
                    self.color = BarColors[BarsEnum.Renown]
                    self.standing = MAJOR_FACTION_RENOWN_LEVEL_TOAST:format(self.level)
                else
                    self.color = E.colors.reaction[self.level]
                    self.standing = FACTION_STANDING[self.level]
                end
            elseif C_Reputation.IsMajorFaction(self.factionID) then
                local majorFactionData = C_MajorFactions.GetMajorFactionData(self.factionID);
                self.minBar = 0
                self.maxBar = majorFactionData.renownLevelThreshold
                self.level = majorFactionData.renownLevel
                self.color = BarColors[BarsEnum.Renown]
                self.standing = MAJOR_FACTION_RENOWN_LEVEL_TOAST:format(self.level)
            elseif (self.friendshipID > 0) then
                local reputationRankInfo = C_GossipInfo.GetFriendshipReputationRanks(self.factionID);
                self.level = reputationRankInfo.currentLevel;
                if reputationInfo.nextThreshold then
                    self.minBar = reputationInfo.reactionThreshold
                    self.maxBar = reputationInfo.nextThreshold
                    self.value = reputationInfo.standing;
                else
                    -- max rank, make it look like a full bar
                    self.minBar = 0
                    self.maxBar = 1
                    self.value = 1
                end

                -- self.level = 5
                self.color = E.colors.reaction[self.level]
                self.standing = FACTION_STANDING[self.level]
            else
                self.level = watchedFactionData.reaction
                self.color = E.colors.reaction[self.level]
                self.standing = FACTION_STANDING[self.level]
            end
        else
            self.factionID = nil
            self.name = nil
            self.level = 5
            self.minBar = 0
            self.maxBar = 1
            self.value = 0
            self.color = E.colors.reaction[self.level]
            self.standing = FACTION_STANDING[self.level]
        end
        
        self.isCapped = (self.level and self.maxLevel) and (self.level >= self.maxLevel) or false
        self.maxBar = self.maxBar - self.minBar
        self.value = self.value - self.minBar
        if self.isCapped and self.maxBar == 0 then
            self.maxBar = 1
            self.value = 1
        end
        self.minBar = 0

        self.percentage = self:CalculatePercentage(self.value, self.maxBar)
        
        self:UpdateColor(self.color)
        self:UpdateStatusBar(self.value, self.minBar, self.maxBar)
    end

    function reputation_proto:SetTooltip(tooltip)
        if self.factionID then
            GameTooltip:AddLine(self.name)
            GameTooltip:AddDoubleLine(
                self.color:WrapTextInColorCode(self.standing),
                EXP_PATTERN:format(self.value, self.maxBar, self.percentage)
            )
        else
            GameTooltip:AddLine(REPUTATION)
        end
    end
end

--------------------------------------------------
-- Honor
--------------------------------------------------
local honor_proto = Mixin({ unit = "player" }, element_proto)

do
    function honor_proto:Update()
        self.value = UnitHonor(self.unit)
        self.maxBar = UnitHonorMax(self.unit)
        self.level = UnitHonorLevel(self.unit)
        self.percentage = self:CalculatePercentage(self.value, self.maxBar)
        self:UpdateStatusBar(self.value, 0, self.maxBar)
    end

    function honor_proto:SetTooltip(tooltip)
        local color = BarColors[BarsEnum.Honor]
        if self.maxBar == 0 then
            tooltip:AddLine(PVP_HONOR_PRESTIGE_AVAILABLE)
            tooltip:AddLine(PVP_HONOR_XP_BAR_CANNOT_PRESTIGE_HERE)
        else
            tooltip:AddDoubleLine(color:WrapTextInColorCode(HONOR .. ":"), EXP_PATTERN:format(self.value, self.maxBar, self.percentage))
            tooltip:AddDoubleLine(color:WrapTextInColorCode(RANK .. ":"), self.level)
        end
    end
end

--------------------------------------------------
-- Azerite
--------------------------------------------------
local azerite_proto = Mixin({}, element_proto)

function azerite_proto:Update()
    local azeriteItemLocation  = C_AzeriteItem.FindActiveAzeriteItem()
    if not azeriteItemLocation or AzeriteUtil.IsAzeriteItemLocationBankBag(azeriteItemLocation) then
        self.level = -1
        self.value = 0
        self.maxBar = 0
    else
        local xp, totalXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
        self.level = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
        self.value = xp
        self.maxBar = totalXP

        local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation);
        local azeriteItemName = azeriteItem:GetItemName();
        self.name = azeriteItemName
    end

    self:UpdateStatusBar(self.value, 0, self.maxBar)
end

function azerite_proto:SetTooltip(tooltip)
    if not self.name then
        tooltip:AddLine(AZERITE)
    else
        tooltip:AddDoubleLine(("%s (%d)"):format(self.name, self.level), ISLANDS_QUEUE_WEEKLY_QUEST_PROGRESS:format(self.value, self.maxBar), 0.90, 0.80, 0.50)
        tooltip:AddLine(AZERITE_POWER_TOOLTIP_BODY:format(self.name))
    end
end

--------------------------------------------------
-- Artifact
--------------------------------------------------
local artifact_proto = Mixin({}, element_proto)

do
    function artifact_proto:Update()
        local element = self

        local artifactItemID = C_ArtifactUI.GetEquippedArtifactItemID();
        if artifactItemID then
            local item = Item:CreateFromItemID(artifactItemID);

            item:ContinueOnItemLoad(function()
                local artifactItemID, _, name, _, artifactTotalXP, artifactPointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
                local numPointsAvailableToSpend, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(artifactPointsSpent, artifactTotalXP, artifactTier)

                element.name = name
                element.value = xp;
                element.totalXP = artifactTotalXP;
                element.maxBar = xpForNextPoint;
                element.level = numPointsAvailableToSpend + artifactPointsSpent
                element:UpdateStatusBar(element.value, 0, element.maxBar)
            end);
        else
            self.name = nil
            self.value = 0
            self.maxBar = 0
            self.totalXP = 0
            self.level = 0
            self:UpdateStatusBar(self.value, 0, self.maxBar)
        end
    end

    function artifact_proto:SetTooltip(tooltip)
        if not self.name or self.maxBar == 0 then
            tooltip:AddLine(ARTIFACT)
        else
            tooltip:AddLine(self.name .. " (" .. self.level .. ")")
            tooltip:AddLine(ARTIFACT_POWER_BAR:format(self.value, self.maxBar))
        end
    end
end
--------------------------------------------------
-- Anima
--------------------------------------------------
local anima_proto = Mixin({}, element_proto)

do
    function anima_proto:Update()
        local currencyID, maxDisplayableValue = C_CovenantSanctumUI.GetAnimaInfo()
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if currencyInfo then
            self.value = currencyInfo.quantity
            self.maxBar = currencyInfo.maxQuantity
        else
            self.value = 0
            self.maxBar = 0
        end

        self.level = C_CovenantSanctumUI.GetRenownLevel()
        self.percentage = self:CalculatePercentage(self.value, self.maxBar)

        self:UpdateStatusBar(self.value, 0, self.maxBar)
    end

    function anima_proto:SetTooltip(tooltip)
        if self.maxBar == 0 then
            tooltip:AddLine(ANIMA)
        else
            tooltip:AddDoubleLine("|cffFF3333" .. COVENANT_SANCTUM_TAB_RENOWN .. " " .. LEVEL .. ": ", self.level)
            tooltip:AddDoubleLine("|cff99CCFF" .. ANIMA_DIVERSION_CURRENCY_TOOLTIP_TITLE .. ": ", EXP_PATTERN:format(self.value, self.maxBar, self.percentage))
        end
    end
end

--------------------------------------------------
-- Pet Experience
--------------------------------------------------
local GetPetExperience = _G.GetPetExperience

local pet_experience_proto = Mixin({ unit = "pet" }, element_proto)

do
    function pet_experience_proto:Update()
        local value, max = GetPetExperience()
        self.value = value or 0
        self.max = max or 0
        self.percentage = self:CalculatePercentage(self.value, self.max)
        self:UpdateStatusBar(self.value, 0, self.max)
    end

    function pet_experience_proto:SetTooltip(tooltip)
        if self.max == 0 then
            tooltip:AddLine(PET .. " " .. EXPERIENCE)
        else
            tooltip:AddDoubleLine("|cff0090FF" .. PET .. " " .. XP .. ":|r", EXP_PATTERN:format(self.value, self.max, self.percentage))
        end
    end
end

--------------------------------------------------
-- Manager
--------------------------------------------------
local frame = CreateFrame("Frame", "TaintedExperienceBar", UIParent)
frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 220)
frame:SetSize(C.chat.width, 8)
frame:RegisterEvent("PLAYER_LOGIN")
frame:CreateBackdrop()

function frame:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:CreateBar("Experience", experience_proto)
        self:CreateBar("Reputation", reputation_proto)
        self:CreateBar("Honor", honor_proto)
        self:CreateBar("Artifact", artifact_proto)
        self:CreateBar("Azerite", azerite_proto)
        self:CreateBar("Anima", anima_proto)
        self:CreateBar("PetExperience", pet_experience_proto)

        local index = E:GetExperienceBarIndex() or BarsEnum.Experience
        local bar = bars[index]
        if index == BarsEnum.Experience and bar and bar:IsMaxLevel() then
            EnableBar(BarsEnum.Reputation)
        else
            EnableBar(index)
        end

        self:RegisterEvent("CVAR_UPDATE");
        self:RegisterEvent("PLAYER_ENTERING_WORLD");

        -- Experience
        self:RegisterEvent("ENABLE_XP_GAIN");
        self:RegisterEvent("DISABLE_XP_GAIN");
        self:RegisterEvent("UPDATE_EXPANSION_LEVEL");
        self:RegisterEvent("PLAYER_XP_UPDATE");
        self:RegisterUnitEvent("UNIT_LEVEL", "player");

        -- Reputation
        self:RegisterEvent("UPDATE_FACTION");
        self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED");

        -- Honor
        self:RegisterEvent("HONOR_XP_UPDATE");
        self:RegisterEvent("ZONE_CHANGED");
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA");

        -- Artifact
        self:RegisterEvent("ARTIFACT_XP_UPDATE");
        self:RegisterEvent("UNIT_INVENTORY_CHANGED");
        self:RegisterEvent("UPDATE_EXTRA_ACTIONBAR");

        -- Azerite
        self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED");
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
        self:RegisterEvent("BAG_UPDATE");


        self:UnregisterEvent(event)
    else
        if (event == "UNIT_LEVEL") then
            local bar = bars[BarsEnum.Experience]
            if bar and bar:IsMaxLevel() then
                EnableBar(BarsEnum.Reputation)
            end
        end

        for k, v in next, BarsEnum do
            local bar = bars[v]
            if bar then
                bar:Update()
            end
        end
    end
end

function frame:CreateBar(name, proto)
    local index = BarsEnum[name]
    if not index then return end

    local texture = A.textures.blank
    local color = BarColors[index]

    local element = Mixin(CreateFrame("Frame", "Tainted" .. name, self), proto)
    element:SetAllPoints()
    element:SetScript("OnEnter", element.OnEnter)
    element:SetScript("OnLeave", element.OnLeave)
    element:SetScript("OnMouseUp", element.OnMouseUp)
    element.index = index

    local bg = element:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(element)
    bg:SetDrawLayer("BACKGROUND", 0)
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg

    local exp = CreateFrame("StatusBar", element:GetName() .. "Exp", element)
    exp:SetAllPoints(element)
    exp:SetStatusBarTexture(texture)
    exp:SetFrameStrata("MEDIUM")
    exp:SetFrameLevel(element:GetFrameLevel() + 4)
    exp:SetOrientation("HORIZONTAL")
    exp:SetMinMaxValues(0, 1)
    exp:SetValue(0)
    exp:EnableMouse()
    element.Exp = exp

    if index == BarsEnum.Experience then
        local restedColor = BarColors[BarsEnum.Rested]

        local rested = CreateFrame("StatusBar", element:GetName() .. "Rested", exp)
        rested:SetAllPoints(exp)
        rested:SetStatusBarTexture(texture)
        rested:SetStatusBarColor(restedColor:GetRGB())
        rested:SetFrameStrata("MEDIUM")
        rested:SetFrameLevel(exp:GetFrameLevel() - 1)
        rested:SetOrientation("HORIZONTAL")
        rested:SetMinMaxValues(0, 1)
        rested:SetValue(0)
        rested:SetReverseFill(false)
        rested:SetClipsChildren(true)
        rested:SetAlpha(0.50)
        element.Rested = rested
    end

    element:UpdateColor(color)

    element:Hide()

    bars[index] = element
end

frame:SetScript("OnEvent", frame.OnEvent)
