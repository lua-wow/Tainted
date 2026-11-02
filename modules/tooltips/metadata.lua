local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("Tooltips")

-- Blizzard
local GetActionInfo = _G.GetActionInfo

-- Mine
local METADATA = E.colors.yellow:WrapTextInColorCode("%s") .. " %s"
local SPELL_ID = "SpellID"
local ITEM_ID = "ItemID"
local TALENT_ID = "TalentID"

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

-- tooltip -> set of metadata labels it shows; created when its OnTooltipCleared is hooked
local added = {}

local function OnTooltipCleared(tooltip)
    table.wipe(added[tooltip])
end

-- several hooks can fire for the same content (e.g. SetHyperlink and OnTooltipSetSpell)
local function AddLine(tooltip, label, id)
    if not id then return end

    local labels = added[tooltip]
    if not labels then
        labels = {}
        added[tooltip] = labels
        tooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    elseif labels[label] then
        return
    end

    -- one spacer above all metadata lines (e.g. SpellID and TalentID)
    if not next(labels) then
        tooltip:AddLine(" ")
    end
    labels[label] = true

    tooltip:AddLine(METADATA:format(label, id), 1, 1, 1)
    tooltip:Show()
end

local function OnSetHyperlink(tooltip, link)
    local id = link:match("^spell:(%d+)")
    if id then
        AddLine(tooltip, SPELL_ID, id)
    end
end

-- UnitAura/UnitBuff/UnitDebuff are deprecation fallbacks on Classic (loadDeprecationFallbacks)
local function Gametooltip_SetUnitAura(tooltip, ...)
    local data = C_UnitAuras.GetAuraDataByIndex(...)
    AddLine(tooltip, SPELL_ID, data and data.spellId)
end

local function Gametooltip_SetUnitBuff(tooltip, ...)
    local data = C_UnitAuras.GetBuffDataByIndex(...)
    AddLine(tooltip, SPELL_ID, data and data.spellId)
end

local function Gametooltip_SetUnitDebuff(tooltip, ...)
    local data = C_UnitAuras.GetDebuffDataByIndex(...)
    AddLine(tooltip, SPELL_ID, data and data.spellId)
end

-- oUF and Blizzard's buff frame set auras by instance ID
local function Gametooltip_SetUnitAuraByAuraInstanceID(tooltip, unit, auraInstanceID)
    local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
    AddLine(tooltip, SPELL_ID, data and data.spellId)
end

local function Gametooltip_SetAction(tooltip, slot)
    local kind, id = GetActionInfo(slot)
    if kind == "spell" then
        AddLine(tooltip, SPELL_ID, id)
    end
end

-- SetTalent (classic talent frames) and SetPvpTalent (retail) take the talent ID first
local function Gametooltip_SetTalent(tooltip, id)
    AddLine(tooltip, TALENT_ID, id)
end

local function OnTooltipSetSpell(tooltip)
    local _, id = tooltip:GetSpell()
    AddLine(tooltip, SPELL_ID, id)
end

local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    if not link then return end

    local id = link:match("item:(%d+)")
    if id ~= "0" then
        AddLine(tooltip, ITEM_ID, id)
    end
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- Spell and PetAction data carry the spell ID (PetAction unverified)
local function TooltipDataProcessor_Spell(tooltip, data)
    if tooltip == _G.GameTooltip or tooltip == _G.ItemRefTooltip or tooltip == _G.EmbeddedItemTooltip then
        if not IsSecret(data.id) then
            AddLine(tooltip, SPELL_ID, data.id)
        end
    end
end

-- tooltip -> true for the tooltips that show the ItemID line (the Item post-call fires for every tooltip)
local itemTooltips = {}

local function TooltipDataProcessor_Item(tooltip, data)
    if itemTooltips[tooltip] and not IsSecret(data.id) then
        AddLine(tooltip, ITEM_ID, data.id)
    end
end

-- macro data has no spell: resolve the action like Blizzard's action buttons do
local function TooltipDataProcessor_Macro(tooltip, data)
    if tooltip ~= _G.GameTooltip then return end

    local info = tooltip.processingInfo
    if info and info.getterName == "GetAction" and info.getterArgs then
        local kind, id, subType = GetActionInfo(info.getterArgs[1])
        if kind == "macro" and subType == "spell" and not IsSecret(id) then
            AddLine(tooltip, SPELL_ID, id)
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
                AddLine(tooltip, SPELL_ID, id)
            end
        end
    end
end

local ITEM_TOOLTIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }

function MODULE:AddMetadata()
    -- talent tooltips can also show a SpellID line; secure hooks run after Blizzard's post-calls
    hookfunction(GameTooltip, "SetTalent", Gametooltip_SetTalent)
    hookfunction(GameTooltip, "SetPvpTalent", Gametooltip_SetTalent)

    -- tooltip data post-calls only fire where GameTooltip uses TooltipDataHandlerMixin (mainline)
    if GameTooltip.ProcessInfo then
        -- display spellID
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.PetAction, TooltipDataProcessor_Spell)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, TooltipDataProcessor_Macro)

        -- display aura spellID and source name
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, TooltipDataProcessor_UnitAura)

        -- display itemID
        for _, name in ipairs(ITEM_TOOLTIPS) do
            if _G[name] then
                itemTooltips[_G[name]] = true
            end
        end
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipDataProcessor_Item)
        return
    end

    -- Hyperlink hooks
    hookfunction(GameTooltip, "SetHyperlink", OnSetHyperlink)
    hookfunction(ItemRefTooltip, "SetHyperlink", OnSetHyperlink)

    -- Buffs/Debuffs/Auras
    hookfunction(GameTooltip, "SetUnitAura", Gametooltip_SetUnitAura)
    hookfunction(GameTooltip, "SetUnitBuff", Gametooltip_SetUnitBuff)
    hookfunction(GameTooltip, "SetUnitDebuff", Gametooltip_SetUnitDebuff)
    hookfunction(GameTooltip, "SetUnitAuraByAuraInstanceID", Gametooltip_SetUnitAuraByAuraInstanceID)
    hookfunction(GameTooltip, "SetUnitBuffByAuraInstanceID", Gametooltip_SetUnitAuraByAuraInstanceID)
    hookfunction(GameTooltip, "SetUnitDebuffByAuraInstanceID", Gametooltip_SetUnitAuraByAuraInstanceID)

    -- Action Bar: Action buttons
    if GetActionInfo then
        hookfunction(GameTooltip, "SetAction", Gametooltip_SetAction)
    end

    -- also covers the spellbook (SetSpellBookItem)
    hookscript(GameTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)
    hookscript(ItemRefTooltip, "OnTooltipSetSpell", OnTooltipSetSpell)

    -- display itemID
    for _, name in ipairs(ITEM_TOOLTIPS) do
        hookscript(_G[name], "OnTooltipSetItem", OnTooltipSetItem)
    end
end
