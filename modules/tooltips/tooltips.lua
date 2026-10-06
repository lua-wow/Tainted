local _, ns = ...
local E, C, L = ns.E, ns.C, ns.L

-- Blizzard
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
local UnitRace = _G.UnitRace
local UnitReaction = _G.UnitReaction
local UnitRealmRelationship = _G.UnitRealmRelationship
local TooltipDataProcessor = _G.TooltipDataProcessor
local GetQuestDifficultyColor = _G.GetQuestDifficultyColor

--------------------------------------------------
-- Tooltips
--------------------------------------------------
if not C.tooltips.enabled then return end



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

local function GetTooltipLine(tooltip, offset, pattern)
    for i = offset, tooltip:NumLines() do
        local text = _G["GameTooltipTextLeft" .. i]:GetText()
        if text and text:match(pattern) then
            return _G["GameTooltipTextLeft" .. i], i + 1
        end
    end
end

local function GetDifficultyColor(unit, level)
    if C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer then
        local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit) or "none"
        return E.colors.difficulty[difficulty] or E.colors.white
    else
        local a, b = GetQuestDifficultyColor(level)
        return E:CreateColor(a.r, a.g, a.b)
    end
end

local tooltip_proto = {}

do
    local statusbar_proto = {}

    function statusbar_proto:OnValueChanged(value, smooth)
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

    function tooltip_proto:UpdateStatusBar()
        local element = Mixin(_G.GameTooltipStatusBar, statusbar_proto)
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

local GameTooltip_UnitColor = function(unit)
    local color = E.colors.white

    local isPlayer = UnitIsPlayer(unit)
    local isFriend = UnitIsFriend("player", unit)

    if UnitPlayerControlled(unit) then
        if UnitCanAttack(unit, "player") then
            -- hostile players are red
            if UnitCanAttack("player", unit) then
                color = E.colors.reaction[2]
            else
                local _, class = UnitClass(unit)
                if class then
                    color = E.colors.class[class]
                end
            end
        elseif UnitCanAttack("player", unit) then
            -- players we can attack but which are not hostile are yellow
            color = E.colors.reaction[4]
        elseif UnitIsPVP(unit) then
            -- players we can assist but are PvP flagged are green
            -- color = E.colors.reaction[6]
            local _, class = UnitClass(unit)
            if class then
                color = E.colors.class[class]
            end
        else
            local _, class = UnitClass(unit)
            if class then
                color = E.colors.class[class]
            end
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

local OnTooltipCleared = function(tooltip)
    local borderColor = C.general.border.color
    local statusbarColor = E:CreateColor(0, 1, 0)

    if tooltip.Backdrop then
        tooltip.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
    end

    -- the health bar belongs to GameTooltip only
    local GameTooltipStatusBar = _G.GameTooltipStatusBar
    if tooltip == _G.GameTooltip and GameTooltipStatusBar then
        GameTooltipStatusBar:SetStatusBarColor(statusbarColor.r, statusbarColor.g, statusbarColor.b)
        
        if GameTooltipStatusBar.Text then
            GameTooltipStatusBar.Text:Hide()
        end

        if GameTooltipStatusBar.Backdrop then
            GameTooltipStatusBar.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
        end
    end
end

local GetTooltipItemLink = function(tooltip)
    if tooltip.GetItem then
        local name, link, id = tooltip:GetItem()
        return id, link, nil
    elseif tooltip.GetTooltipData then
        local data = tooltip:GetTooltipData()
        if data then
            return data.id, C_Item.GetItemLinkByGUID(data.guid), data.guid
        end
    end
    return nil, nil, nil
end

local SetItemBorderColor = function(tooltip, quality)
    if not tooltip.Backdrop then return end

    if quality then
        local r, g, b = GetItemQualityColor(quality)
        tooltip.Backdrop:SetBackdropBorderColor(r, g, b)
    else
        local color = C.general.backdrop.color
        tooltip.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
    end
end

local SetItemTooltipBorderColorByQuality = function(tooltip)
    if not tooltip then return end

    local itemID, itemLink, itemGUID = GetTooltipItemLink(tooltip)

    if itemLink then
        local _, _, quality, itemLevel, _, itemType, itemSubtype, _, _, _, _, _, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(itemLink)
        SetItemBorderColor(tooltip, quality)
    end
end

local SetCraftingReagentsQuantityInBag = function(tooltip, id)
    local count = C_Item.GetItemCount(id)
    if count then
        tooltip:AddLine(" ")
        tooltip:AddLine(IN_BAG:format(count), 1.0, 1.0, 1.0)
    end
end

local UpdateItemTooltip = function(tooltip, data)
    if tooltip == _G.GameTooltip or tooltip == _G.ItemRefTooltip then
        -- on Retail, tooltip:GetItem() returns (name, link, id)
        -- on Classic, tooltip:GetItem() returns (name, link)
        local link, id, guid

        if data then
            guid = data.guid
            id = data.id
            if data.hiperlink then
                link = data.hyperlink
            elseif guid then
                link = C_Item.GetItemLinkByGUID(guid)
            end
        else
            _, link, id = tooltip:GetItem()
        end
        
        if link then
            local _, _, quality, itemLevel, _, itemType, itemSubtype, _, _, _, _, _, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(link)

            SetItemBorderColor(tooltip, quality)

            if isCraftingReagent then
                SetCraftingReagentsQuantityInBag(tooltip, link)
            end
        end
    end
end

local UpdateUnitTooltip = function(tooltip, data)
    if C_PetBattles.IsInBattle() then return end
    
    local name, unit, guid = tooltip:GetUnit()
    if not unit then return end

    guid = guid or UnitGUID(unit)
    local _, realm = UnitName(unit)
    local classText, class = UnitClass(unit)
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

            text = color:WrapTextInColorCode(text)

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
            if line then
                offset = _offset

                local guildText = guildName
                if guildRealm and guildRealm ~= "" and guildRealm ~= realm then
                    guildText = guildName .. " - " .. guildRealm
                end

                line:SetText(E.colors.lawngreen:WrapTextInColorCode(guildText))
                line:SetTextColor(1, 1, 1)
            end
        end
    end

    -- level
    do
        local line, _offset = GetTooltipLine(tooltip, offset, (scaledLevel > 0) and scaledLevel or "%?%?")
        offset = _offset

        if line then
            local levelText = (level > 0) and level or "??"

            local difficultyColor = GetDifficultyColor(unit, level)

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
                    difficultyColor = E.GetRelativeDifficultyColor(teamLevel, scaledLevel)
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
    if E.isVanilla and E.class == "HUNTER" and unit == "pet" and GetPetHappiness then
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
    
    do
        local guidType, _, _, _, _, guidID, _ = string.split("-", guid)
        if IsShiftKeyDown() and guidType == "Creature" then
            tooltip:AddDoubleLine("NPC ID", guidID, nil, nil, nil, 1.0, 1.0, 1.0)
        end
    end
end

local GameTooltip_ShowCompareItem = function(tooltip, anchorFrame)
    for index, element in next, (tooltip.shoppingTooltips or {}) do
        SetItemTooltipBorderColorByQuality(element or _G["ShoppingTooltip" .. index])
    end
end

function tooltip_proto:SetupHooks(owner)
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        tooltip:ClearAllPoints()
        tooltip:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)
    end)

    -- update tooltip colors
    hooksecurefunc("GameTooltip_UnitColor", GameTooltip_UnitColor)

    hooksecurefunc("GameTooltip_ShowCompareItem", GameTooltip_ShowCompareItem)

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- color tooltip border by item quality
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, UpdateItemTooltip)

        -- unit tooltip customization
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, UpdateUnitTooltip)
    end

    if not E.isStandard then
		GameTooltip:HookScript("OnTooltipSetItem", UpdateItemTooltip)
        GameTooltip:HookScript("OnTooltipSetUnit", UpdateUnitTooltip)
        ItemRefTooltip:HookScript("OnTooltipSetItem", UpdateItemTooltip)
    end
end


function tooltip_proto:CreateAnchor()
    local element = CreateFrame("Frame", "TaintedTooltipAnchor", UIParent)
    element:SetPoint("BOTTOMRIGHT", _G.TaintedChatRight, "TOPRIGHT", 0, C.chat.margin)
    element:SetSize(200, 20)
    element:SetFrameStrata("TOOLTIP")
	element:SetFrameLevel(20)
    element:SetClampedToScreen(true)
    element:SetMovable(false)
    return element
end

function tooltip_proto:Update(element)
    if element:IsForbidden() then return end

    if not element.isSkinned then
        element:StripTextures()
        element:CreateBackdrop("transparent")

		if element.NineSlice then
			element.NineSlice:SetAlpha(0)
		end

        -- EmbeddedItemTooltip is a plain frame without this script
        if element:HasScript("OnTooltipCleared") then
            element:HookScript("OnTooltipCleared", OnTooltipCleared)
        end

        element.isSkinned = true
    end

    if element.CloseButton then
        element.CloseButton:SkinCloseButton()
    end
end

function tooltip_proto:Init()
    self.Anchor = self:CreateAnchor()
    self:Update(_G.GameTooltip)
    self:Update(_G.ItemRefTooltip)
    self:Update(_G.EmbeddedItemTooltip)
    self:Update(_G.ShoppingTooltip1)
    self:Update(_G.ShoppingTooltip2)
    self:UpdateStatusBar()
    self:SetupHooks(self.Anchor)
    self:AddMetadata()
end

E:CreateModule("Tooltips", tooltip_proto)
