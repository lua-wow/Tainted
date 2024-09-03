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

local EXP_PATTERN = "%d / %d (%.0f%%)"
local RESTED_PATTERN = "+%d (%.0f%%)"

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
    [BarsEnum.Experience] = E:CreateColor(0.00, 0.56, 1.00),
    [BarsEnum.Rested] = E:CreateColor(0.29, 0.69, 0.30),
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

local element_proto = {}

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
            -- E.print(owner, owner:GetName(), rootDescription:GetName())
            rootDescription:CreateButton(_G.COMBAT_XP_GAIN or "Experience", function() EnableBar(BarsEnum.Experience) end)
            rootDescription:CreateButton(_G.REPUTATION or "Reputation", function() EnableBar(BarsEnum.Reputation) end)
            rootDescription:CreateButton(_G.HONOR or "Honor", function() EnableBar(BarsEnum.Honor) end)
            rootDescription:CreateButton("Artifact", function() EnableBar(BarsEnum.Artifact) end)
            rootDescription:CreateButton("Azerite", function() EnableBar(BarsEnum.Azerite) end)
            rootDescription:CreateButton(_G.POWER_TYPE_ANIMA or "Anima", function() EnableBar(BarsEnum.Anima) end)
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
        self.percentage = (self.nextXP ~= 0) and math.floor(100* (self.currXP / self.nextXP)) or 0
        self.level = level or -1
        self.bankedLevels = bankedLevels
        self.restedXP = exhaustion or 0
        self.isRested = (exhaustionID == 1)

        self:UpdateStatusBar(self.currXP, 0, self.nextXP, self.restedXP)
    end

        function experience_proto:OnEnter()
        local parent = self:GetParent()
        if parent:IsCapped() then return end

        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)

        GameTooltip:AddDoubleLine(LEVEL, parent.level)

        do
            local color = BarColors[BarsEnum.Experience]
            GameTooltip:AddDoubleLine(color:WrapTextInColorCode(XP .. ":"), EXP_PATTERN:format(parent.currXP, parent.nextXP, parent.percentage))
        end

        if (parent.isRested and parent.restedXP > 0) then
            local color = BarColors[BarsEnum.Rested]
            GameTooltip:AddDoubleLine(color:WrapTextInColorCode(TUTORIAL_TITLE26 .. ":"), RESTED_PATTERN:format(parent.restedXP, math.floor((parent.restedXP / parent.nextXP) * 100)))
        end

        GameTooltip:Show()
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
                -- local repInfo = C_GossipInfo.GetFriendshipReputation(self.factionID);
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
            self.reaction = -1
            self.minBar = 0
            self.maxBar = 1
            self.value = 0
            self.color = E.colors.reaction[5]
        end
        
        self.isCapped = (self.level and self.maxLevel) and (self.level >= self.maxLevel) or false
        self.maxBar = self.maxBar - self.minBar
        self.value = self.value - self.minBar
        if self.isCapped and self.maxBar == 0 then
            self.maxBar = 1
            self.value = 1
        end
        self.minBar = 0

        self.percentage = (self.maxBar ~= 0) and math.floor((self.value / self.maxBar) * 100) or 0
        
        self:UpdateColor(self.color)
        self:UpdateStatusBar(self.value, self.minBar, self.maxBar)
    end

    function reputation_proto:OnEnter()
        local parent = self:GetParent()

        local standing = FACTION_STANDING[parent.level or 0]

        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
        GameTooltip:AddLine(parent.name)
        GameTooltip:AddDoubleLine(
            parent.color:WrapTextInColorCode(parent.standing),
            EXP_PATTERN:format(parent.value, parent.maxBar, parent.percentage)
        )
        GameTooltip:Show()
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
        self.percentage = math.floor(100 * (self.value / self.maxBar))
        self:UpdateStatusBar(self.value, 0, self.maxBar)
    end

    function honor_proto:OnEnter()
        local parent = self:GetParent()
        
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)

        if self.maxBar == 0 then
            GameTooltip:AddLine(PVP_HONOR_PRESTIGE_AVAILABLE)
            GameTooltip:AddLine(PVP_HONOR_XP_BAR_CANNOT_PRESTIGE_HERE)
        else
            GameTooltip:AddDoubleLine("|cffee2222" .. HONOR .. ":|r", EXP_PATTERN:format(parent.value, parent.maxBar, parent.percentage))
            GameTooltip:AddDoubleLine("|cffee2222" .. RANK .. ":|r", parent.level)
        end

        GameTooltip:Show()
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
        self.maxBar = 1
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

function azerite_proto:OnEnter()
    local parent = self:GetParent()
    if not parent.name then return end

    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
    GameTooltip:AddDoubleLine(("%s (%d)"):format(parent.name, parent.level), ISLANDS_QUEUE_WEEKLY_QUEST_PROGRESS:format(parent.value, parent.maxBar), 0.90, 0.80, 0.50)
    GameTooltip:AddLine(AZERITE_POWER_TOOLTIP_BODY:format(parent.name))
    GameTooltip:Show()
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
            self.level = 0
            self.percentage = 0
            self:UpdateStatusBar(self.value, 0, self.maxBar)
        end
    end

    function artifact_proto:OnEnter()
        local parent = self:GetParent()
        if not parent.name or parent.maxBar == 0 then return end

        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
        GameTooltip:AddLine(parent.name .. " (" .. parent.level .. ")")
        GameTooltip:AddLine(ARTIFACT_POWER_BAR:format(parent.value, parent.maxBar))
        GameTooltip:Show()
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
            self.percentage = (self.maxBar ~= 0) and math.floor((self.value / self.maxBar) * 100) or 0
        else
            self.value = 0
            self.maxBar = 0
            self.percentage = 0
        end
        
        self.level = C_CovenantSanctumUI.GetRenownLevel()

        self:UpdateStatusBar(self.value, 0, self.maxBar)
    end

    function anima_proto:OnEnter()
        local parent = self:GetParent()
        if parent.maxBar == 0 then return end

        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
        GameTooltip:AddDoubleLine("|cffFF3333" .. COVENANT_SANCTUM_TAB_RENOWN .. " " .. LEVEL .. ": ", parent.level)
        GameTooltip:AddDoubleLine("|cff99CCFF" .. ANIMA_DIVERSION_CURRENCY_TOOLTIP_TITLE .. ": ", EXP_PATTERN:format(parent.value, parent.maxBar, parent.percentage))
        GameTooltip:Show()
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
        self.max = math.max(max or 1, 1)
        self.percentage = math.floor((self.value / self.max) * 100)
        self:UpdateStatusBar(self.value, 0, self.max)
    end

    function pet_experience_proto:OnEnter()
        local parent = self:GetParent()
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -1, 5)
        GameTooltip:AddDoubleLine("|cff0090FF" .. PET .. " " .. XP .. ":|r", parent.value .. " / " .. parent.max .. " (" .. parent.percentage .. "%)")
        GameTooltip:Show()
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
    exp:SetFrameLevel(3)
    exp:SetOrientation("HORIZONTAL")
    exp:SetMinMaxValues(0, 1)
    exp:SetValue(0)
    exp:EnableMouse()
    exp:SetScript("OnEnter", element.OnEnter)
    exp:SetScript("OnLeave", element.OnLeave)
    exp:SetScript("OnMouseUp", element.OnMouseUp)
    element.Exp = exp

    if index == BarsEnum.Experience then
        local restedColor = BarColors[BarsEnum.Rested]

        local rested = CreateFrame("StatusBar", element:GetName() .. "Rested", exp)
        rested:SetAllPoints()
        rested:SetStatusBarTexture(texture)
        rested:SetStatusBarColor(restedColor:GetRGB())
        rested:SetFrameStrata("MEDIUM")
        rested:SetFrameLevel(exp:GetFrameLevel() - 1)
        rested:SetOrientation("HORIZONTAL")
        rested:SetMinMaxValues(0, 1)
        rested:SetValue(0)
        rested:SetReverseFill(false)
        rested:SetClipsChildren(true)
        element.Rested = rested
    end

    element:UpdateColor(color)

    element:Hide()

    bars[index] = element
end

frame:SetScript("OnEvent", frame.OnEvent)
