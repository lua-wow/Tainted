local _, ns = ...
local E = ns.E
local MODULE = E:GetModule("Tooltips")

-- Blizzard
local GetActionInfo = _G.GetActionInfo
local UnitDebuff = _G.UnitDebuff
local UnitBuff = _G.UnitBuff
local UnitAura = _G.UnitAura

-- Mine
local METADATA = E.colors.yellow:WrapTextInColorCode("%s") .. " %s"
local SPELL_ID = "SpellID"

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

-- tooltip -> true while it shows the SpellID line, false once its OnTooltipCleared is hooked
local added = {}

local function OnTooltipCleared(tooltip)
    added[tooltip] = false
end

-- several hooks can fire for the same content (e.g. SetHyperlink and OnTooltipSetSpell)
local function AddLine(tooltip, id)
    if not id or added[tooltip] then return end

    if added[tooltip] == nil then
        tooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    end
    added[tooltip] = true

    tooltip:AddLine(" ")
    tooltip:AddLine(METADATA:format(SPELL_ID, id), 1, 1, 1)
    tooltip:Show()
end

local function OnSetHyperlink(tooltip, link)
    local id = link:match("^spell:(%d+)")
    if id then
        AddLine(tooltip, id)
    end
end

local function Gametooltip_SetUnitAura(tooltip, ...)
    local id = select(10, UnitAura(...))
    AddLine(tooltip, id)
end

local function Gametooltip_SetUnitBuff(tooltip, ...)
    local id = select(10, UnitBuff(...))
    AddLine(tooltip, id)
end

local function Gametooltip_SetUnitDebuff(tooltip, ...)
    local id = select(10, UnitDebuff(...))
    AddLine(tooltip, id)
end

local function Gametooltip_SetAction(tooltip, slot)
    local kind, id = GetActionInfo(slot)
    if kind == "spell" then
        AddLine(tooltip, id)
    end
end

local function OnTooltipSetSpell(tooltip)
    local _, id = tooltip:GetSpell()
    AddLine(tooltip, id)
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

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- Spell and PetAction data carry the spell ID (PetAction unverified)
local function TooltipDataProcessor_Spell(tooltip, data)
    if tooltip == _G.GameTooltip or tooltip == _G.ItemRefTooltip or tooltip == _G.EmbeddedItemTooltip then
        if not IsSecret(data.id) then
            AddLine(tooltip, data.id)
        end
    end
end

-- macro data has no spell: resolve the action like Blizzard's action buttons do
local function TooltipDataProcessor_Macro(tooltip, data)
    if tooltip ~= _G.GameTooltip then return end

    local info = tooltip.processingInfo
    if info and info.getterName == "GetAction" and info.getterArgs then
        local kind, id, subType = GetActionInfo(info.getterArgs[1])
        if kind == "macro" and subType == "spell" and not IsSecret(id) then
            AddLine(tooltip, id)
        end
    end
end

local function TooltipDataProcessor_UnitAura(tooltip, data)
    if tooltip == _G.GameTooltip or tooltip == _G.EmbeddedItemTooltip then
        local id = data.id
        if id and not IsSecret(id) then
            -- aura data can't be queried from tainted code while auras are secret: show only the ID
            local accessor = not C_Secrets.ShouldAurasBeSecret() and tooltip.processingInfo and TooltipDataAccessor[tooltip.processingInfo.getterName]
            local sourceUnit = accessor and accessor(tooltip.processingInfo.getterArgs)

            if sourceUnit then
                local source = UnitName(sourceUnit)
                local color = E.GetUnitColor(sourceUnit)

                local left = METADATA:format(SPELL_ID, tostring(id))
                local right = METADATA:format(_G.SOURCE, source)
                tooltip:AddLine(" ")
                tooltip:AddDoubleLine(left, right, 1, 1, 1, color.r, color.g, color.b)
            else
                AddLine(tooltip, id)
            end
        end
    end
end

function MODULE:AddMetadata()
    -- tooltip data post-calls only fire where GameTooltip uses TooltipDataHandlerMixin (mainline)
    if GameTooltip.ProcessInfo then
        -- display spellID
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.PetAction, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, TooltipDataProcessor_Macro)

        -- display aura spellID and source name
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, TooltipDataProcessor_UnitAura)
        return
    end

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

    -- also covers the spellbook (SetSpellBookItem)
    hookscript(GameTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)
    hookscript(ItemRefTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)

    if E.isVanilla then
        hookscript(_G.GameTooltip, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefTooltip, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefShoppingTooltip1, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ItemRefShoppingTooltip2, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ShoppingTooltip1, "OnTooltipSetItem", OnTooltipSetItem)
        hookscript(_G.ShoppingTooltip2, "OnTooltipSetItem", OnTooltipSetItem)

        -- TEMP: does Blizzard add a sell price away from a vendor? remove after checking
        hookscript(_G.GameTooltip, "OnTooltipAddMoney", function(_, cost, maxCost)
            print("Tainted OnTooltipAddMoney", cost, maxCost, _G.MerchantFrame:IsShown())
        end)
    end
end
