local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local INVSLOT_FIRST_EQUIPPED = _G.INVSLOT_FIRST_EQUIPPED or 1
local INVSLOT_LAST_EQUIPPED = _G.INVSLOT_LAST_EQUIPPED or 19

local MAX_SPELL_SCHOOLS = _G.MAX_SPELL_SCHOOLS or 7

local CR_UNUSED_1 = _G.CR_UNUSED_1 or 1
local CR_DEFENSE_SKILL = _G.CR_DEFENSE_SKILL or 2
local CR_DODGE = _G.CR_DODGE or 3
local CR_PARRY = _G.CR_PARRY or 4
local CR_BLOCK = _G.CR_BLOCK or 5
local CR_HIT_MELEE = _G.CR_HIT_MELEE or 6
local CR_HIT_RANGED = _G.CR_HIT_RANGED or 7
local CR_HIT_SPELL = _G.CR_HIT_SPELL or 8
local CR_CRIT_MELEE = _G.CR_CRIT_MELEE or 9
local CR_CRIT_RANGED = _G.CR_CRIT_RANGED or 10
local CR_CRIT_SPELL = _G.CR_CRIT_SPELL or 11
local CR_CORRUPTION = _G.CR_CORRUPTION or 12
local CR_CORRUPTION_RESISTANCE = _G.CR_CORRUPTION_RESISTANCE or 13
local CR_SPEED = _G.CR_SPEED or 14
local COMBAT_RATING_RESILIENCE_CRIT_TAKEN = _G.COMBAT_RATING_RESILIENCE_CRIT_TAKEN or 15
local COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN = _G.COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN or 16
local CR_LIFESTEAL = _G.CR_LIFESTEAL or 17
local CR_HASTE_MELEE = _G.CR_HASTE_MELEE or 18
local CR_HASTE_RANGED = _G.CR_HASTE_RANGED or 19
local CR_HASTE_SPELL = _G.CR_HASTE_SPELL or 20
local CR_AVOIDANCE = _G.CR_AVOIDANCE or 21
local CR_UNUSED_2 = _G.CR_UNUSED_2 or 22
local CR_WEAPON_SKILL_RANGED = _G.CR_WEAPON_SKILL_RANGED or 23
local CR_EXPERTISE = _G.CR_EXPERTISE or 24
local CR_ARMOR_PENETRATION = _G.CR_ARMOR_PENETRATION or 25
local CR_MASTERY = _G.CR_MASTERY or 26
local CR_UNUSED_3 = _G.CR_UNUSED_3 or 27
local CR_UNUSED_4 = _G.CR_UNUSED_4 or 28
local CR_VERSATILITY_DAMAGE_DONE = _G.CR_VERSATILITY_DAMAGE_DONE or 29
local CR_VERSATILITY_DAMAGE_TAKEN = _G.CR_VERSATILITY_DAMAGE_TAKEN or 31

local UnitName = _G.UnitName
local UnitLevel = _G.UnitLevel
local UnitClass = _G.UnitClass
local UnitStat = _G.UnitStat
local GetAverageItemLevel = _G.GetAverageItemLevel
local GetSpellCritChance = _G.GetSpellCritChance
local GetRangedCritChance = _G.GetRangedCritChance
local GetCritChance = _G.GetCritChance
local GetCombatRating = _G.GetCombatRating
local GetCombatRatingBonus = _G.GetCombatRatingBonus
local GetHaste = _G.GetHaste
local GetMasteryEffect = _G.GetMasteryEffect
local GetAvoidance = _G.GetAvoidance
local GetLifesteal = _G.GetLifesteal
local GetSpeed = _G.GetSpeed
local GetBlockChance = _G.GetBlockChance
local GetShieldBlock = _G.GetShieldBlock
local GetDodgeChance = _G.GetDodgeChance
local GetParryChance = _G.GetParryChance
local GetInventoryItemID = _G.GetInventoryItemID
local GetInventoryItemDurability = _G.GetInventoryItemDurability

-- Mine
local DATATEXT_STRING = "%s %s"
local PERCENTAGE_STRING = "(%.0f%%)"

local DURABILITY = _G.DURABILITY or "Durability"
local ITEM_LEVEL = _G.ITEM_UPGRADE_STAT_AVERAGE_ITEM_LEVEL or "Item Level"
local LEVEL = _G.LEVEL or "Level"
local STATS = _G.PET_BATTLE_STATS_LABEL or "Stats"
local STAT_STRENGTH = _G.SPELL_STAT1_NAME or "Strength"
local STAT_AGILITY = _G.SPELL_STAT2_NAME or "Agility"
local STAT_INTELLECT = _G.SPELL_STAT3_NAME or "Intellect"
local STAT_STAMINA = _G.SPELL_STAT4_NAME or "Stamina"
local STAT_ARMOR = _G.STAT_ARMOR or "Armor"
local STAT_CRITICAL_STRIKE = _G.STAT_CRITICAL_STRIKE or "Critical Strike"
local STAT_HASTE = _G.STAT_HASTE or "Haste"
local STAT_MASTERY = _G.STAT_MASTERY or "Mastery"
local STAT_VERSATILITY = _G.STAT_VERSATILITY or "Versatility"
local STAT_AVOIDANCE = _G.STAT_AVOIDANCE or "Avoidance"
local STAT_LIFESTEAL = _G.STAT_LIFESTEAL or "Leech"
local STAT_SPEED = _G.STAT_SPEED or "Speed"
local STAT_BLOCK = _G.STAT_BLOCK or "Block"
local STAT_DODGE = _G.STAT_DODGE or "Dodge"
local STAT_PARRY = _G.STAT_PARRY or "Parry"

local PRIMARY_STATS = _G.PRIMARY_STATS or "Primary Stats"
local SECONDARY_STATS = _G.SECONDARY_STATS or "Secondary Stats"
local CURRENCY = _G.CURRENCY or "Currency"
local TOGGLE_CHARACTER_TEXT = L.TOGGLE_CHARACTER_TEXT

local CURRENCIES = {
    -- The War Winthin: Season 1
    { currencyID = 2813, enabled = E.isRetail },  -- Harmonized Silk
    { currencyID = 3028, enabled = E.isRetail },  -- Restored Coffer Key
    { currencyID = 3008, enabled = E.isRetail },  -- Valorstones
    { currencyID = 2914, enabled = E.isRetail },  -- Weathered Harbringer Crest
    { currencyID = 2915, enabled = E.isRetail },  -- Carved Harbringer Crest
    { currencyID = 2916, enabled = E.isRetail },  -- Runed Harbringer Crest
    { currencyID = 2917, enabled = E.isRetail },  -- Gilded Harbringer Crest
}

local slots = {}

local character_proto = {}

function character_proto:CreateTooltip(tooltip)
    PaperDollFrame_UpdateStats()

    -- player info
    local name = UnitName(self.unit)
    local level = UnitLevel(self.unit)
    local class = select(2, UnitClass(self.unit))
    local classColor = E.colors.class[class]
    tooltip:AddDoubleLine(name, E.realm, classColor.r, classColor.g, classColor.b, 1.0, 1.0, 1.0)
    tooltip:AddLine(" ")

    tooltip:AddLine(STATS)
    tooltip:AddDoubleLine(LEVEL, level, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    
    local averageItemLevel = GetAverageItemLevel()
    tooltip:AddDoubleLine(ITEM_LEVEL, ("%.2f"):format(averageItemLevel), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    
    tooltip:AddLine(" ")
    
    -- primary stats
    do
        tooltip:AddLine(PRIMARY_STATS)

        local strength = UnitStat(self.unit, _G.LE_UNIT_STAT_STRENGTH or 1)
        tooltip:AddDoubleLine(STAT_STRENGTH, strength, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

        local agility = UnitStat(self.unit, _G.LE_UNIT_STAT_AGILITY or 2)
        tooltip:AddDoubleLine(STAT_AGILITY, agility, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

        local intellect = UnitStat(self.unit, _G.LE_UNIT_STAT_INTELLECT or 4)
        tooltip:AddDoubleLine(STAT_INTELLECT, intellect, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

        local stamina = UnitStat(self.unit, _G.LE_UNIT_STAT_STAMINA or 3)
        tooltip:AddDoubleLine(STAT_STAMINA, stamina, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        
        do
            local baselineArmor, effectiveArmor, armor, bonusArmor = UnitArmor(self.unit)
            tooltip:AddDoubleLine(STAT_ARMOR, armor, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end
        
        tooltip:AddLine(" ")
    end
    
    -- secondary stats
    do
        tooltip:AddLine(SECONDARY_STATS)

        -- critical strike
        local criticalStrike, criticalStrikeRating, criticalStrikeRatingBonus = self:GetCriticalStrike()
        tooltip:AddDoubleLine(STAT_CRITICAL_STRIKE, ("%d (%0.2f%%)"):format(criticalStrikeRating, criticalStrike), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        
        -- haste
        local haste, hasteRating, hasteRatingBonus = self:GetHaste()
        tooltip:AddDoubleLine(STAT_HASTE, ("%d (%0.2f%%)"):format(hasteRating, haste), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        
        -- mastery
        local mastery, masteryRating, masteryBonus = self:GetMastery()
        tooltip:AddDoubleLine(STAT_MASTERY, ("%d (%0.2f%%)"):format(masteryRating, mastery), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        
        -- versatility
        local versatility, versatilityDamageBonus, versatilityDamageTakenReduction = self:GetVersatility()
        tooltip:AddDoubleLine(STAT_VERSATILITY, ("%d (%0.2f%% / %0.2f%%)"):format(versatility, versatilityDamageBonus, versatilityDamageTakenReduction), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        
        -- avoidance
        local avoidance, avoidanceRating, avoidanceRatingBonus = self:GetAvoidance()
        if avoidanceRating ~= 0 then
            tooltip:AddDoubleLine(STAT_AVOIDANCE, ("%d (%0.2f%%)"):format(avoidanceRating, avoidance), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        -- leech
        local lifesteal, lifestealRating, lifestealRatingBonus = self:GetLeech()
        if lifestealRating ~= 0 then
            tooltip:AddDoubleLine(STAT_LIFESTEAL, ("%d (%0.2f%%)"):format(lifestealRating, lifesteal), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        -- speed
        local speed, speedRating, speedRatingBonus = self:GetSpeed()
        if speedRating ~= 0 then
            tooltip:AddDoubleLine(STAT_SPEED, ("%d (%0.2f%%)"):format(speedRating, speed), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        -- block
        local block, shieldBlock = self:GetBlock()
        if block ~= 0 then
            tooltip:AddDoubleLine(STAT_BLOCK, ("%0.2f%%"):format(block), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        -- dodge
        local dodge, dodgeRating, dodgeRatingBonus = self:GetDodge()
        if dodgeRating ~= 0 then
            tooltip:AddDoubleLine(STAT_DODGE, ("%d (%0.2f%%)"):format(dodgeRating, dodge), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        -- parry
        local parry, parryRating, parryRatingBonus = self:GetParry()
        if parryRating ~= 0 then
            tooltip:AddDoubleLine(STAT_PARRY, ("%d (%0.2f%%)"):format(parryRating, parry), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        end

        tooltip:AddLine(" ")
    end
    
    tooltip:AddLine(DURABILITY)
    
    local r, g, b = 0, 0, 0
    for k, row in next, slots do
        g = math.max(row.percentage * 2, 1)
        r = (1 - g) + 0.5
        tooltip:AddDoubleLine(row.slotName, ("%.0f%%"):format(row.percentage * 100), 1.0, 1.0, 1.0, r, g, b)
    end
    
    tooltip:AddLine(" ")
    tooltip:AddLine(CURRENCY)
    
    for _, row in next, CURRENCIES do
        if row.enabled then
            local currency = C_CurrencyInfo.GetCurrencyInfo(row.currencyID)
            if currency then
                local icon = "|T" .. currency.iconFileID .. ":16:16:0:0:64:64:4:60:4:60|t "
                local quantityText = currency.quantity
                if currency.maxQuantity > 0 then
                    quantityText = quantityText .. " / " .. currency.maxQuantity
                end
                if currency.canEarnPerWeek == true then
                    quantityText = quantityText .. (" (%d/%d Weekly)"):format(currency.quantityEarnedThisWeek, currency.maxWeeklyQuantity)
                end
                tooltip:AddDoubleLine(icon .. currency.name, quantityText, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
            end
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOGGLE_CHARACTER_TEXT)
end

function character_proto:GetCriticalStrike()
    local holySchool = 2 -- start at 2 to skip physical damage
    local minCrit = GetSpellCritChance(holySchool)
    
    self.spellCrit = table.wipe(self.spellCrit or {})
    self.spellCrit[holySchool] = minCrit
    for school = (holySchool+1), MAX_SPELL_SCHOOLS do
        spellCrit = GetSpellCritChance(school)
        minCrit = min(minCrit, spellCrit)
        self.spellCrit[school] = spellCrit
    end
    
    local spellCrit = minCrit
    local rangedCrit = GetRangedCritChance()
    local meleeCrit = GetCritChance()
    
    local rating, critChance
    if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
        critChance = spellCrit;
        rating = CR_CRIT_SPELL;
    elseif (rangedCrit >= meleeCrit) then
        critChance = rangedCrit;
        rating = CR_CRIT_RANGED;
    else
        critChance = meleeCrit;
        rating = CR_CRIT_MELEE;
    end
    
    local critChanceRating = GetCombatRating(rating)
    local critChanceRatingBonus = GetCombatRatingBonus(rating)

    return critChance, critChanceRating, critChanceRatingBonus
end

function character_proto:GetHaste()
    local rating = CR_HASTE_MELEE
    local haste = GetHaste()
    local hasteRating = GetCombatRating(rating)
    local hasteRatingBonus = GetCombatRatingBonus(rating)
    return haste, hasteRating, hasteRatingBonus
end

function character_proto:GetMastery()
    local rating = CR_MASTERY
    local mastery, bonusCoeff = GetMasteryEffect()
    local masteryRating = GetCombatRating(CR_MASTERY)
    local masteryBonus = GetCombatRatingBonus(CR_MASTERY) * bonusCoeff
    return mastery, masteryRating, masteryBonus
end

function character_proto:GetVersatility()
    local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
    local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    return versatility, versatilityDamageBonus, versatilityDamageTakenReduction
end

function character_proto:GetAvoidance()
    local rating = CR_AVOIDANCE
    local avoidance = GetAvoidance()
    local avoidanceRating = GetCombatRating(rating)
    local avoidanceRatingBonus = GetCombatRatingBonus(rating)
    return avoidance, avoidanceRating, avoidanceRatingBonus
end

function character_proto:GetLeech()
    local rating = CR_LIFESTEAL
    local lifesteal = GetLifesteal()
    local lifestealRating = GetCombatRating(rating)
    local lifestealRatingBonus = GetCombatRatingBonus(rating)
    return lifesteal, lifestealRating, lifestealRatingBonus
end

function character_proto:GetSpeed()
    local rating = CR_SPEED
    local speed = GetSpeed()
    local speedRating = GetCombatRating(rating)
    local speedRatingBonus = GetCombatRatingBonus(rating)
    return speed, speedRating, speedRatingBonus
end

function character_proto:GetBlock()
    local block = GetBlockChance()
    local shieldBlock = GetShieldBlock()
    return block, shieldBlock
end

function character_proto:GetDodge()
    local rating = CR_DODGE
    local dodge = GetDodgeChance()
    local dodgeRating = GetCombatRating(rating)
    local dodgeRatingBonus = GetCombatRatingBonus(rating)
    return dodge, dodgeRating, dodgeRatingBonus
end

function character_proto:GetParry()
    local rating = CR_PARRY
    local parry = GetParryChance()
    local parryRating = GetCombatRating(rating)
    local parryRatingBonus = GetCombatRatingBonus(rating)
    return parry, parryRating, parryRatingBonus
end

function character_proto:OnMouseDown()
    if InCombatLockdown() then
        E:print(ERR_NOT_IN_COMBAT)
    else
        ToggleCharacter("PaperDollFrame") 
	end
end

local SortByDurability = function(a, b)
    if (a.percentage ~= b.percentage) then
        return a.percentage < b.percentage
    end
    return a.slot < b.slot
end

function character_proto:OnEvent(event, ...)
    slots = table.wipe(slots or {})

    local lowest = 1

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", slot)
        if itemID ~= nil then
            local durability, max = GetInventoryItemDurability(slot)
            if durability then
                local percentage = durability / max
                local row = {
                    slot = slot,
                    slotName = L.SLOTS[slot] or UNKNOWN,
                    durability = durability,
                    max = max,
                    percentage = percentage
                }
                table.insert(slots, row)

                if percentage < lowest then
                    lowest = percentage
                end
            end
        end
    end

    table.sort(slots, SortByDurability)

    local item = slots[1]
    if item then
        local durability = PERCENTAGE_STRING:format(item.percentage * 100)
        self.Text:SetFormattedText(DATATEXT_STRING, self.name, self.color:WrapTextInColorCode(durability))
    else
        self.Text:SetText(self.name)
    end
end

function character_proto:Update()
    self:OnEvent("ForceUpdate")
end

function character_proto:Enable()
    if self.Text then
        self.Text:SetText(self.name)
    end

    self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
	self:Update()
    self:Show()
end

function character_proto:Disable()
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

MODULE:AddElement("Character", character_proto)
