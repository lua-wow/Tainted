local _, ns = ...
local E, C, L = ns.E, ns.C, ns.L

-- Blizzard
local GetDifficultyColor = _G.GetDifficultyColor
local GetGuildInfo = _G.GetGuildInfo
local GetItemQualityColor = _G.GetItemQualityColor
local GetPetHappiness = _G.GetPetHappiness  -- only classic
-- local GetSpecialization = _G.GetSpecialization
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitEffectiveLevel = _G.UnitEffectiveLevel
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsAFK = _G.UnitIsAFK
local UnitIsBattlePet = _G.UnitIsBattlePet
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsDND = _G.UnitIsDND
-- local UnitIsEnemy = _G.UnitIsEnemy
-- local UnitIsFriend = _G.UnitIsFriend
local UnitIsGhost = _G.UnitIsGhost
local UnitIsOtherPlayersBattlePet = _G.UnitIsOtherPlayersBattlePet
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitPVPName = _G.UnitPVPName
local UnitQuestTrivialLevelRange = _G.UnitQuestTrivialLevelRange
local UnitRace = _G.UnitRace
local UnitReaction = _G.UnitReaction
local UnitRealmRelationship = _G.UnitRealmRelationship
local TooltipDataProcessor = _G.TooltipDataProcessor

local TooltipDataAccessor = {
    ["GetUnitAura"] = function(...)
        local data = C_UnitAuras.GetAuraDataByIndex(unpack(...))
        if data then
            return data.sourceUnit
        end
    end,
    ["GetUnitBuff"] = function(...)
        local data = C_UnitAuras.GetBuffDataByIndex(unpack(...))
        if data then
            return data.sourceUnit
        end
    end,
    ["GetUnitBuffByAuraInstanceID"] = function(...)
        local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unpack(...))
        if data then
            return data.sourceUnit
        end
    end,
    ["GetUnitDebuff"] = function(...)
        local data = C_UnitAuras.GetDebuffDataByIndex(unpack(...))
        if data then
            return data.sourceUnit
        end
    end,
    ["GetUnitDebuffByAuraInstanceID"] = function(...)
        local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unpack(...))
        if data then
            return data.sourceUnit
        end
    end
}

--------------------------------------------------
-- Tooltips
--------------------------------------------------
if not C.tooltips.enabled then return end

local MODULE = E:CreateModule("Tooltips")

local isInit = false

local IN_BAG = E.colors.yellow:WrapTextInColorCode("In Bag") .. " %d"
local SPELL_ID = E.colors.yellow:WrapTextInColorCode("SpellID") .. " %d"
local SOURCE = E.colors.yellow:WrapTextInColorCode(_G.SOURCE) .. " %s"
local TARGET = E.colors.yellow:WrapTextInColorCode(_G.TARGET .. ":") .. " %s"
local STATUS = E.colors.gray:WrapTextInColorCode("<%s> ")
local AFK = STATUS:format(_G.AFK or "AFK")
local DND = STATUS:format(_G.DND or "DND")
local DEAD = STATUS:format(_G.DEAD or "Dead")
local GHOST = STATUS:format(L.GHOST or "Ghost")
local OFFLINE = STATUS:format(L.OFFLINE or "Offline")
local NAME_FORMAT = "%s%s"
local PLAYER_LEVEL = "%s %s (" .. _G.PLAYER .. ")"
local BATTLE_PET_LEVEL = "%s %s%s"
local CREATURE_LEVEL = "%s %s"

local function GetRelativeDifficultyColor(unitLevel, challengeLevel)
    local diff = challengeLevel - unitLevel
    if diff >= 5 then
        return E.colors.difficulty["impossible"]
    elseif diff >= 3 then
        return E.colors.difficulty["very_difficult"]
    elseif diff >= -4 then
        return E.colors.difficulty["difficult"]
    elseif -diff <= UnitQuestTrivialLevelRange("player") then
        return E.colors.difficulty["standard"]
    else
        return E.colors.difficulty["trivial"]
    end
end

local function GetTooltipLine(tooltip, offset, pattern)
    for i = offset, tooltip:NumLines() do
        local text = _G["GameTooltipTextLeft" .. i]:GetText()
        if text and text:match(pattern) then
            return _G["GameTooltipTextLeft" .. i], i + 1
        end
    end
end

function MODULE:Update(element)
    if element:IsForbidden() then return end

    if not element.isSkinned then
        element:StripTextures()
        element:CreateBackdrop("transparent")

		if element.NineSlice then
			element.NineSlice:SetAlpha(0)
		end

        element.isSkinned = true
    end
end

do
    local element_proto = {}

    function element_proto:OnValueChanged(value, smooth)
        local _, unit = self:GetParent():GetUnit()
        if unit then
            if UnitIsDeadOrGhost(unit) then
                if self.Text then
                    self.Text:SetText(DEAD)
                end
            else
                local cur, max = UnitHealth(unit), UnitHealthMax(unit)
                local text = (cur and max and E.ShortValue(cur) .. " / " .. E.ShortValue(max)) or "???"
                if self.Text then
                    self.Text:SetText(text)

                    if not self.Text:IsShown() then
                        self.Text:Show()
                    end
                end
            end
        end
    end

    function MODULE:UpdateStatusBar()
        local element = Mixin(_G.GameTooltipStatusBar, element_proto)
        element:ClearAllPoints()
        element:SetPoint("BOTTOMLEFT", element:GetParent(), "TOPLEFT", 0, 3)
        element:SetPoint("BOTTOMRIGHT", element:GetParent(), "TOPRIGHT", 0, 3)
        element:SetHeight(5)
        element:SetStatusBarTexture(C.tooltips.texture)
        element:CreateBackdrop()
        element:SetScript("OnValueChanged", element.OnValueChanged)

        if not element.Text then
            local fontObject = E.GetFont(C.tooltips.font)

            local text = element:CreateFontString(nil, "OVERLAY")
            text:SetFontObject(fontObject)
            text:SetPoint("CENTER", element, "CENTER", 0, 6)
            element.Text = text
        end
    end
end

do
    function MODULE:GameTooltip_UnitColor()
        local unit = self
        local color = E.colors.white

        if UnitPlayerControlled(unit) then
            if UnitCanAttack(unit, "player") then
                -- hostile players are red
                if UnitCanAttack("player", unit) then
                    color = E.colors.reaction[2]
                end
            elseif UnitCanAttack("player", unit) then
                -- players we can attack but which are not hostile are yellow
                color = E.colors.reaction[4]
            elseif UnitIsPVP(unit) then
                -- players we can assist but are PvP flagged are green
                color = E.colors.reaction[6]
            else
                local class = select(2, UnitClass(unit))
                color = E.colors.class[class]
            end
        else
            local reaction = UnitReaction(unit, "player");
            if reaction then
                color = E.colors.reaction[reaction]
            else
                color = C.general.border.color
            end
        end

        local GameTooltip = _G.GameTooltip
        if GameTooltip.Backdrop then
            GameTooltip.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
        end

        local GameTooltipStatusBar = _G.GameTooltipStatusBar
        GameTooltipStatusBar:SetStatusBarColor(color.r, color.g, color.b)
        if GameTooltipStatusBar.Backdrop then
            GameTooltipStatusBar.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
        end

        return color.r, color.g, color.b;
    end

    function MODULE:GameTooltip_ClearMoney()
        local borderColor = C.general.border.color
        local statusbarColor = E:CreateColor(0, 1, 0)

        if self.Backdrop then
            self.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
        end

        local GameTooltipStatusBar = _G.GameTooltipStatusBar
        if GameTooltipStatusBar then
            GameTooltipStatusBar:SetStatusBarColor(statusbarColor.r, statusbarColor.g, statusbarColor.b)
            
            if GameTooltipStatusBar.Text then
                GameTooltipStatusBar.Text:Hide()
            end

            if GameTooltipStatusBar.Backdrop then
                GameTooltipStatusBar.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
            end
        end
    end

    function MODULE:AnchorShoppingTooltips(primaryShown, secondaryShown)
        local tooltip = self.tooltip;
        local primaryTooltip = tooltip.shoppingTooltips[1];
        local secondaryTooltip = tooltip.shoppingTooltips[2];
        
        primaryTooltip:SetShown(primaryShown);
        secondaryTooltip:SetShown(secondaryShown);
    
        local sideAnchorFrame = self.anchorFrame;
        if self.anchorFrame.IsEmbedded then
            sideAnchorFrame = self.anchorFrame:GetParent():GetParent();
        end
    
        local leftPos = sideAnchorFrame:GetLeft();
        local rightPos = sideAnchorFrame:GetRight();
    
        local selfLeftPos = tooltip:GetLeft();
        local selfRightPos = tooltip:GetRight();
    
        -- if we get the Left, we have the Right
        if leftPos and selfLeftPos then
            leftPos = math.min(selfLeftPos, leftPos);-- get the left most bound
            rightPos = math.max(selfRightPos, rightPos);-- get the right most bound
        else
            leftPos = leftPos or selfLeftPos or 0;
            rightPos = rightPos or selfRightPos or 0;
        end
    
        -- sometimes the sideAnchorFrame is an actual tooltip, and sometimes it's a script region, so make sure we're getting the actual anchor type
        local anchorType = sideAnchorFrame.GetAnchorType and sideAnchorFrame:GetAnchorType() or tooltip:GetAnchorType();
    
        local totalWidth = 0;
        if primaryShown then
            totalWidth = totalWidth + primaryTooltip:GetWidth();
        end
        if secondaryShown then
            totalWidth = totalWidth + secondaryTooltip:GetWidth();
        end
    
        local rightDist = 0;
        local screenWidth = GetScreenWidth();
        rightDist = screenWidth - rightPos;
    
        -- find correct side
        local side;
        if anchorType and (totalWidth < leftPos) and (anchorType == "ANCHOR_LEFT" or anchorType == "ANCHOR_TOPLEFT" or anchorType == "ANCHOR_BOTTOMLEFT") then
            side = "left";
        elseif anchorType and (totalWidth < rightDist) and (anchorType == "ANCHOR_RIGHT" or anchorType == "ANCHOR_TOPRIGHT" or anchorType == "ANCHOR_BOTTOMRIGHT") then
            side = "right";
        elseif rightDist < leftPos then
            side = "left";
        else
            side = "right";
        end
    
        -- see if we should slide the tooltip
        if totalWidth > 0 and (anchorType and anchorType ~= "ANCHOR_PRESERVE") then --we never slide a tooltip with a preserved anchor
            local slideAmount = 0;
            if ( (side == "left") and (totalWidth > leftPos) ) then
                slideAmount = totalWidth - leftPos;
            elseif ( (side == "right") and (rightPos + totalWidth) >  screenWidth ) then
                slideAmount = screenWidth - (rightPos + totalWidth);
            end
    
            if slideAmount ~= 0 then -- if we calculated a slideAmount, we need to slide
                if sideAnchorFrame.SetAnchorType then
                    sideAnchorFrame:SetAnchorType(anchorType, slideAmount, 0);
                else
                    tooltip:SetAnchorType(anchorType, slideAmount, 0);
                end
            end
        end
    
        local offset = 5
        if secondaryShown then
            primaryTooltip:SetPoint("TOP", self.anchorFrame, 0, 0);
            secondaryTooltip:SetPoint("TOP", self.anchorFrame, 0, 0);
            if side and side == "left" then
                primaryTooltip:SetPoint("RIGHT", sideAnchorFrame, "LEFT", -offset, 0);
            else
                secondaryTooltip:SetPoint("LEFT", sideAnchorFrame, "RIGHT", offset, 0);
            end
    
            if side and side == "left" then
                secondaryTooltip:SetPoint("TOPRIGHT", primaryTooltip, "TOPLEFT", -offset, 0);
            else
                primaryTooltip:SetPoint("TOPLEFT", secondaryTooltip, "TOPRIGHT", offset, 0);
            end
        else
            primaryTooltip:SetPoint("TOP", self.anchorFrame, 0, 0);
            if side and side == "left" then
                primaryTooltip:SetPoint("RIGHT", sideAnchorFrame, "LEFT", -offset, 0);
            else
                primaryTooltip:SetPoint("LEFT", sideAnchorFrame, "RIGHT", offset, 0);
            end
        end
    end

    MODULE.UpdateItemTooltip = function(tooltip, data)
        if tooltip == _G.GameTooltip or tooltip == _G.ItemRefTooltip then
            local name, link, id = tooltip:GetItem()
            if id then
                local _, _, quality, itemLevel, _, itemType, itemSubtype, _, _, _, _, _, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(link or id)
                if tooltip.Backdrop then
                    if quality then
                        local r, g, b = GetItemQualityColor(quality)
                        tooltip.Backdrop:SetBackdropBorderColor(r, g, b)
                    else
                        local color = C.general.backdrop.color
                        tooltip.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
                    end
                end

                if isCraftingReagent then
                    local count = C_Item.GetItemCount(id)
                    if count then
                        tooltip:AddLine(" ")
                        tooltip:AddLine(IN_BAG:format(count), 1.0, 1.0, 1.0)
                    end
                end
            end
        end
    end

    MODULE.UpdateSpellTooltip = function(tooltip, data)
        if tooltip == _G.GameTooltip or tooltip == _G.EmbeddedItemTooltip then
            local name, id = tooltip:GetSpell()
            if id then
                tooltip:AddLine(" ")
                tooltip:AddLine(SPELL_ID:format(id), 1, 1, 1)
            end
        end
    end
    
    MODULE.UpdateAuraTooltip = function(tooltip, data)
        if tooltip == _G.GameTooltip or tooltip == _G.EmbeddedItemTooltip then
            local id = data.id
            if id then
                local getterName = tooltip.processingInfo and tooltip.processingInfo.getterName
                local getterArgs = tooltip.processingInfo and tooltip.processingInfo.getterArgs
                local accessor = TooltipDataAccessor[getterName]
                local sourceUnit = accessor and accessor(getterArgs)

                tooltip:AddLine(" ")
                if sourceUnit then
                    local source = UnitName(sourceUnit)
                    local color = E.GetUnitColor(sourceUnit)

                    tooltip:AddDoubleLine(SPELL_ID:format(id), SOURCE:format(source), 1, 1, 1, color.r, color.g, color.b)
                else
                    tooltip:AddLine(SPELL_ID:format(id), 1, 1, 1)
                end
            end
        end
    end

    MODULE.UpdateUnitTooltip = function(tooltip, data)
        if C_PetBattles.IsInBattle() then return end
        
        local name, unit, guid = tooltip:GetUnit()
        if not unit then return end

        local realm = select(2, UnitName(unit))
        local class = select(2, UnitClass(unit))
        local level = UnitIsBattlePet(unit) and UnitBattlePetLevel(unit) or UnitLevel(unit)
        local scaledLevel = UnitIsBattlePet(unit) and UnitBattlePetLevel(unit) or UnitEffectiveLevel(unit)
        local creatureType = UnitCreatureType(unit)
        local classification = UnitClassification(unit)
        local isShiftKeyDown = IsShiftKeyDown()

        -- name
        do
            local line = _G.GameTooltipTextLeft1

            if UnitIsPlayer(unit) then
                local color = E.colors.class[class]
                local pvpName = UnitPVPName(unit)
                
                local text = name
                if pvpName and pvpName ~= "" then
                    text = pvpName
                end

                if realm and realm ~= "" then
                    text = NAME_FORMAT:format(text, " - " .. realm)
                    -- if isShiftKeyDown then
                    --     name = NAME_FORMAT:format(name, "-" .. realm)
                    -- elseif UnitRealmRelationship(unit) ~= LE_REALM_RELATION_VIRTUAL then
                    --     name = NAME_FORMAT:format(name, _G.FOREIGN_SERVER_LABEL)
                    -- end
                end

                local status = ""
                if not UnitIsConnected(unit) then
                    status = OFFLINE
                elseif UnitIsGhost(unit) then
                    status = GHOST
                elseif UnitIsDead(unit) then
                    status = DEAD
                elseif UnitIsAFK(unit) then
                    status = AFK
                elseif UnitIsDND(unit) then
                    status = DND
                end
                
                line:SetText(status .. text)
                line:SetTextColor(color.r, color.g, color.b)
            elseif not UnitIsBattlePet(unit) then
                local color = E.GetUnitColor(unit)
                line:SetText(name or "Unknown")
                line:SetTextColor(color.r, color.g, color.b)
            end
        end

        do
            local line = _G.GameTooltipTextRight1
            line:SetText(nil)
            line:Hide()
        end

        local offset = 2

        -- guild
        do
            local guildName, _, _, guildRealm = GetGuildInfo(unit)
            if guildName then
                local line, _offset = GetTooltipLine(tooltip, offset, guildName) -- offset = 3
                offset = _offset

                local guildText = guildName
                if guildRealm and guildRealm ~= "" and guildRealm ~= realm then
                    guildText = guildName .. " - " .. guildRealm
                end
                
                line:SetText(E.colors.lawngreen:WrapTextInColorCode(guildText))
                line:SetTextColor(1, 1, 1)
            end
        end

        -- level
        do
            local line, _offset = GetTooltipLine(tooltip, offset, (scaledLevel > 0) and scaledLevel or "%?%?")
            offset = _offset

            if line then
                local levelText = (level > 0) and level or "??"

                local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit)
                local difficultyColor = E.colors.difficulty[difficulty] or E.colors.white -- GetDifficultyColor(difficulty)

                if UnitIsPlayer(unit) then
                    local color = E.colors.class[class]
                    local race = UnitRace(unit)

                    line:SetText(PLAYER_LEVEL:format(difficultyColor:WrapTextInColorCode(levelText), race or "", classText))

                    -- specialization
                    local specLine = _G["GameTooltipTextLeft" .. offset]
                    if specLine then
                        local specText = string.trim(specLine:GetText() or "")
                        if specText and specText ~= "" then
                            specLine:SetTextColor(color.r, color.g, color.b)
                        end
                    end
                elseif UnitIsBattlePet(unit) then
                    local petType = UnitBattlePetType(unit)
                    
                    local teamLevel = C_PetJournal.GetPetTeamAverageLevel() or 0
                    if teamLevel then
                        difficultyColor = GetRelativeDifficultyColor(teamLevel, scaledLevel)
                    end

                    line:SetText(BATTLE_PET_LEVEL:format(difficultyColor:WrapTextInColorCode(levelText), (creatureType or ""), " (" .. _G["BATTLE_PET_NAME_" .. petType] .. ")"))
                else
                    local classificationText = E.GetClassification(classification) or ""
                    line:SetText(CREATURE_LEVEL:format(difficultyColor:WrapTextInColorCode(levelText) .. classificationText, creatureType or ""))
                end

                line:SetTextColor(1, 1, 1)
            end
        end

        -- target
        do
            local target = unit .. "target"
            if UnitExists(target) then
                local color = E.GetUnitColor(target)
                local name = color:WrapTextInColorCode(UnitName(target))
                tooltip:AddLine(TARGET:format(name), 1, 1, 1)
            end
        end

        -- hunter
        if E.isClassic and E.class == "HUNTER" and unit == "pet" and GetPetHappiness then
            local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
            if happiness then
                local color = E.colors.happiness[happiness]
                local happy = ({ "Unhappy", "Content", "Happy" })[happiness]
                local loyalty = (loyaltyRate > 0) and "gaining" or "losing"
    
                tooltip:AddLine(" ")
                tooltip:AddLine(L.PET_HAPINESS:format(color:WrapTextInColorCode(happy)), 1, 1, 1)
                tooltip:AddLine(L.PET_DAMAGE:format(color:WrapTextInColorCode(damagePercentage .. "%")), 1, 1, 1)
                tooltip:AddLine(L.PET_LOYALTY:format(color:WrapTextInColorCode(loyalty)), 1, 1, 1)
            end
        end
    end

    function MODULE:SetupHooks()
        -- update tooltip colors
        hooksecurefunc("GameTooltip_UnitColor", self.GameTooltip_UnitColor)
        hooksecurefunc("GameTooltip_ClearMoney", self.GameTooltip_ClearMoney)

        -- update comparison tooltip anchors
        hooksecurefunc(_G.TooltipComparisonManager, "AnchorShoppingTooltips", self.AnchorShoppingTooltips)

        -- color tooltip border by item quality
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, self.UpdateItemTooltip)

        -- display spellID
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, self.UpdateSpellTooltip)

        -- display aura spellID and source name
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, self.UpdateAuraTooltip)

        -- unit tooltip customization
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, self.UpdateUnitTooltip)
    end
end

function MODULE:Init()
    do
        local container = _G.GameTooltipDefaultContainer
        container:ClearAllPoints()
        container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 200)
    end

    do
        local container = _G.SharedTooltipDefaultContainer
        container:ClearAllPoints()
        container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -30, 200)
    end

    self:Update(_G.GameTooltip)
    self:Update(_G.ItemRefTooltip)
    self:Update(_G.EmbeddedItemTooltip)
    self:Update(_G.ShoppingTooltip1)
    self:Update(_G.ShoppingTooltip2)
    self:UpdateStatusBar()
    self:SetupHooks()
end
