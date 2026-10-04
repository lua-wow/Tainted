local _, ns = ...
local E = ns.E
local MODULE = E:GetModule("Tooltips")

-- Blizzard
local GetTalentInfoByID = _G.GetTalentInfoByID
local GetPvpTalentInfoByID = _G.GetPvpTalentInfoByID
local GetActionInfo = _G.GetActionInfo
local UnitDebuff = _G.UnitDebuff
local UnitBuff = _G.UnitBuff
local UnitAura = _G.UnitAura

-- Mine
local METADATA = E.colors.yellow:WrapTextInColorCode("%s") .. " %s"

local kinds = {
    spell = "SpellID",
    unit = "Npc ID",
}

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

--[[
hooksecurefunc("CastSpellByName", print); -- Hooks the global CastSpellByName
hooksecurefunc(GameTooltip, "SetUnitBuff", print); -- Hooks GameTooltip.SetUnitBuff
]]
local function hookfunction(tbl, fn, cb)
    if tbl and tbl[fn] then
        hooksecurefunc(tbl, fn, cb)
    end
end

local function hookscript(tbl, fn, cb)
    if tbl and tbl:HasScript(fn) then
        tbl:HookScript(fn, cb)
    end
end

local function GetTooltipName(tooltip)
    return tooltip:GetName() or nil
end

local function AddLine(tooltip, id, kind)
    if not id or id == "" or not tooltip or not tooltip.GetName then return end

    local label = kinds[kind]
    if not label then return end

    -- get the tooltip name safely
    local ok, name = pcall(GetTooltipName, tooltip)
    if not ok or not name then return end

    -- check if line already added
    for i = tooltip:NumLines(), 1, -1 do
        local frame = _G[name .. "TextLeft" .. i]
        if frame then
            local text = frame:GetText()
            if type(text) == "string" and text:find(label) then return end
        end
    end

    local text = METADATA:format(label, id)
    tooltip:AddLine(" ")
    tooltip:AddLine(text, 1, 1, 1)
    tooltip:Show()
end

local function OnSetHyperlink(tooltip, link)
    local kind, id = string.match(link,"^(%a+):(%d+)")
    if kind and id then
        AddLine(tooltip, id, kind)
    end
end

local function Gametooltip_SetUnitAura(tooltip, ...)
    local id = select(10, UnitAura(...))
    AddLine(tooltip, id, "spell")
end

local function Gametooltip_SetUnitBuff(tooltip, ...)
    local id = select(10, UnitBuff(...))
    AddLine(tooltip, id, "spell")
end

local function Gametooltip_SetUnitDebuff(tooltip, ...)
    local id = select(10, UnitDebuff(...))
    AddLine(tooltip, id, "spell")
end

local function Gametooltip_SetAction(tooltip, slot)
    local kind, id = GetActionInfo(slot)
    AddLine(tooltip, id, kind)
end

local function GameTooltip_SetTalent(tooltip, id)
    local spellID = select(6, GetTalentInfoByID(id))
    AddLine(tooltip, id, "talent")
    AddLine(tooltip, spellID, "spell")
end

local function GameTooltip_SetPvpTalent(tooltip, id)
    local spellID = select(6, GetPvpTalentInfoByID(id))
    AddLine(tooltip, id, "talent")
    AddLine(tooltip, spellID, "spell")
end

local function GameTooltip_SetRecipeResultItem(tooltip, id)
    AddLine(tooltip, id, "spell")
end

local function GameTooltip_SetRecipeRankInfo(tooltip, id)
    AddLine(tooltip, id, "spell")
end

local function OnTooltipSetSpell(tooltip)
    local _, id = tooltip:GetSpell()
    AddLine(tooltip, id, "spell")
end

local function SpellButton_OnEnter(btn)
    if not btn then return end
    local slot = SpellBook_GetSpellBookSlot(btn)
    local _, spellID = GetSpellBookItemInfo(slot, SpellBookFrame.bookType)
    AddLine(GameTooltip, spellID, "spell")
end

local function PetBattleAbilityButton_OnEnter(btn)
    local petIndex = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY)
    if btn:GetEffectiveAlpha() > 0 then
        local id = select(1, C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, petIndex, btn:GetID()))
        if id then
            local oldText = PetBattlePrimaryAbilityTooltip.Description:GetText(id)
            PetBattlePrimaryAbilityTooltip.Description:SetText(oldText .. "\r\r" .. kinds.ability .. "|cffffffff " .. id .. "|r")
        end
    end
end

local function PetBattleAura_OnEnter(frame)
    local parent = frame:GetParent()
    local id = select(1, C_PetBattles.GetAuraInfo(parent.petOwner, parent.petIndex, frame.auraIndex))
    if id then
        local oldText = PetBattlePrimaryAbilityTooltip.Description:GetText(id)
        PetBattlePrimaryAbilityTooltip.Description:SetText(oldText .. "\r\r" .. kinds.ability .. "|cffffffff " .. id .. "|r")
    end
end

local OnTooltipSetItem = function(self)
    if self.GetItem then
        local _, itemLink = self:GetItem()
        if itemLink then
            local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink)
            if vendorPrice and vendorPrice > 0 then
                -- Format the price into gold, silver, and copper
                local gold = math.floor(vendorPrice / 10000)
                local silver = math.floor((vendorPrice % 10000) / 100)
                local copper = vendorPrice % 100

                -- Create a formatted price string
                local priceText = ""
                if gold > 0 then
                    priceText = priceText .. gold .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
                end
                if silver > 0 then
                    priceText = priceText .. silver .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
                end
                if copper > 0 then
                    priceText = priceText .. copper .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
                end

                -- Add the vendor price to the tooltip
                self:AddLine("Vendor Price: " .. priceText, 1, 1, 1)
                self:Show()
            end
        end
    end
end

local function TooltipDataProcessor_Spell(tooltip, data)
    if tooltip == _G.GameTooltip or tooltip == _G.EmbeddedItemTooltip then
        local name, id = tooltip:GetSpell()
        if id then
            AddLine(tooltip, id, "spell")
        end
    end
end

local function TooltipDataProcessor_UnitAura(tooltip, data)
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

                local left = METADATA:format(kinds.spell, tostring(id))
                local right = METADATA:format(_G.SOURCE, source)
                tooltip:AddDoubleLine(left, right, 1, 1, 1, color.r, color.g, color.b)
            else
                AddLine(tooltip, id, "spell")
            end
        end
    end
end

function MODULE:AddMetadata()
    -- Hyperlink hooks
    hookfunction(GameTooltip, "SetHyperlink", OnSetHyperlink)
    hookfunction(ItemRefTooltip, "SetHyperlink", OnSetHyperlink)

    -- Buffs/Debuffs/Auras
    if UnitAura then
        hookfunction(GameTooltip, "SetUnitAura", Gametooltip_SetUnitAura)
    end

    if UnitBuff then
        hookfunction(GameTooltip, "SetUnitBuff", Gametooltip_SetUnitBuff)
    end

    if UnitDebuff then
        hookfunction(GameTooltip, "SetUnitDebuff", Gametooltip_SetUnitDebuff)
    end

    -- Action Bar: Action buttons
    if GetActionInfo then
        hookfunction(GameTooltip, "SetAction", Gametooltip_SetAction)
    end

    -- Talents
    if GetTalentInfoByID then
        hookfunction(GameTooltip, "SetTalent", GameTooltip_SetTalent)
    end

    if GetPvpTalentInfoByID then
        hookfunction(GameTooltip, "SetPvpTalent", GameTooltip_SetPvpTalent)
    end

    hookfunction(GameTooltip, "SetRecipeResultItem", GameTooltip_SetRecipeResultItem)
    hookfunction(GameTooltip, "SetRecipeRankInfo", GameTooltip_SetRecipeRankInfo)

    hookscript(GameTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)
    hookscript(ItemRefTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)

    -- SpellBook
    if SpellBook_GetSpellBookSlot then
        hookfunction(_G, "SpellButton_OnEnter", SpellBook_GetSpellBookSlot)
    end

    -- Pet Battle abilities if available
    if C_PetBattles and C_PetBattles.GetAuraInfo then
        hookfunction(_G, "PetBattleAura_OnEnter", PetBattleAura_OnEnter)

        if C_PetBattles.GetActivePet then
            hookfunction(_G, "PetBattleAbilityButton_OnEnter", PetBattleAbilityButton_OnEnter)
        end
    end

    if E.isVanilla then
        hookscript(_G.GameTooltip, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefTooltip, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefShoppingTooltip1, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefShoppingTooltip2, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ShoppingTooltip1, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ShoppingTooltip2, "OnTooltipSetItem", OnTooltipSetItem)
    end

    -- Handle TooltipDataProcessor (Dragonflight+)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- display spellID
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.AzeriteEssence, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.PetAction, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.EnhancedConduit, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.RecipeRankInfo, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Totem, TooltipDataProcessor_Spell)

        -- display aura spellID and source name
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, TooltipDataProcessor_UnitAura)
    end
end
