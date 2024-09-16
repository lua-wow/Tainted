local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local UnitGUID = _G.UnitGUID
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo

-- Mine
local UPDATE_INTERVAL = 2
local DPS = "DPS"
local HPS = "HPS"
local DATATEXT_STRING = "%s: %s"

local EVENTS = {
    ["damage"] = {
        ["SWING_DAMAGE"] = true,
        ["RANGE_DAMAGE"] = true,
        ["SPELL_DAMAGE"] = true,
        ["SPELL_EXTRA_ATTACKS"] = true,
        ["SPELL_PERIODIC_DAMAGE"] = true,
        ["DAMAGE_SPLIT"] = true,
        ["DAMAGE_SHIELD"] = true,
    },
    ["healing"] = {
        ["SPELL_HEAL"] = true,
        ["SPELL_PERIODIC_HEAL"] = true,
    }
}

local meter_proto = {
    isHealer = false,
    damages = {},
    damageIndexes = {},
    heals = {},
    healIndexes = {},
    start = nil,
    damage = 0,
    healing = 0,
    overhealing = 0,
    absorbed = 0
}

local Sort = function(a, b)
    if a.percentage ~= b.percentage then
        return a.percentage > b.percentage
    end
    return a.amount > b.amount
end

function meter_proto:CreateTooltip(tooltip)
    tooltip:AddLine("Damage")
    tooltip:AddDoubleLine("Overall", E.ShortValue(self.damage or 0), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddDoubleLine("Dps", E.ShortValue(self:GetDps()), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddLine(" ")
    
    if IsShiftKeyDown() then
        table.sort(self.damageIndexes, Sort)
        
        local len = math.min(#self.damageIndexes, 7)
        for i = 1, len do
            local row = self.damageIndexes[i]
            if row then
                tooltip:AddDoubleLine(row.spellName, ("%s (%.1f%%)"):format(E.ShortValue(row.amount), (row.amount / self.damage) * 100))
                -- tooltip:AddDoubleLine(" ", ("%s | %s"):format(E.ShortValue(row.min), E.ShortValue(row.max)))
            end
        end
        tooltip:AddLine(" ")
    end

    tooltip:AddLine("Heals")
    tooltip:AddDoubleLine("Healing", E.ShortValue(self.healing or 0), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddDoubleLine("Over Healing", E.ShortValue(self.overhealing or 0), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddDoubleLine("Absorbed", E.ShortValue(self.absorbed or 0), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddDoubleLine("Hps", E.ShortValue(self:GetHps()), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    
    if IsShiftKeyDown() then
        tooltip:AddLine(" ")
        
        table.sort(self.healIndexes, Sort)
        
        local len = math.min(#self.healIndexes, 10)
        for i = 1, len do
            local row = self.healIndexes[i]
            if row then
                tooltip:AddDoubleLine(row.spellName, ("%s (%.1f%%)"):format(E.ShortValue(row.amount), (row.amount / self.healing) * 100))
                -- tooltip:AddDoubleLine(" ", ("%s | %s"):format(E.ShortValue(row.min), E.ShortValue(row.max)))
            end
        end
    end
    
    tooltip:AddLine(" ")
    tooltip:AddLine("(Hold Shift) Details")
end

function meter_proto:OnEvent(event, ...)
    if not self[event] then return end
    self[event](self, ...)
end

function meter_proto:IsDamage(subtype)
    return EVENTS["damage"][subtype]
end

function meter_proto:IsHealing(subtype)
    return EVENTS["healing"][subtype]
end

function meter_proto:GetElpased()
    local start = self.start or time()
    local elapsed = (time() - start)
    return (elapsed > 0) and elapsed or 1
end

function meter_proto:GetDps()
    local elapsed = self:GetElpased()
    local amount = self.damage or 0
    return (amount / elapsed)
end

function meter_proto:GetHps()
    local elapsed = self:GetElpased()
    local amount = (self.healing or 0) - (self.overhealing or 0) + (self.absorbed)
    return (amount / elapsed)
end

function meter_proto:CollectDamage(spellId, spellName, subevent, amount)
    -- update damage done
    self.damage = (self.damage or 0) + amount

    -- damage logs
    if not self.damages[spellId] then
        local data = {
            spellId = spellId,
            spellName = spellName,
            subevent = subevent,
            amount = amount,
            min = amount,
            max = amount
        }
        self.damages[spellId] = data
        table.insert(self.damageIndexes, data)
    else
        local data = self.damages[spellId]
        data.subevent = data.subevent
        data.amount = data.amount + amount
        data.min = math.min(data.min, amount)
        data.max = math.max(data.max, amount)
    end
end

function meter_proto:CollectHeal(spellId, spellName, amount, overhealing, absorbed)
    -- sum overall values
    self.healing = (self.healing or 0) + amount
    self.overhealing = (self.overhealing or 0) + (overhealing or 0)
    self.absorbed = (self.absorbed or 0) + (overhealing or 0)

    -- heals logs
    if not self.heals[spellId] then
        local data = {
            spellId = spellId,
            spellName = spellName,
            amount = amount,
            overhealing = overhealing,
            absorbed = absorbed,
            min = amount,
            max = amount
        }
        self.heals[spellId] = data
        table.insert(self.healIndexes, data)
    else
        local data = self.heals[spellId]
        data.amount = data.amount + amount
        data.min = math.min(data.min, amount)
        data.max = math.max(data.max, amount)
    end
end



function meter_proto:PLAYER_ENTERING_WORLD()
    local inCombat = UnitAffectingCombat(self.unit)
    if inCombat then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function meter_proto:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    if sourceGUID == self.guid or sourceGUID == self.pet_guid then
        
        if self:IsHealing(subevent) then
            local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
            self.healing = (self.healing or 0) + (amount or 0)
            self.overhealing = (self.overhealing or 0) + (overhealing or 0)
            self:CollectHeal(spellId, spellName, amount, overhealing, absorbed)
        elseif self:IsDamage(subevent) and destGUID ~= self.guid then
            if subevent == "SWING_DAMAGE" then
                local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
                self:CollectDamage(0, "Melee", subevent, amount + (overkill or 0))
            else
                local spellId, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo())
                local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(15, CombatLogGetCurrentEventInfo())
                self:CollectDamage(spellId, spellName, subevent, amount + (overkill or 0))
            end
        end

        if not self.start then
            self.start = timestamp
        end
    end
end

function meter_proto:PLAYER_REGEN_ENABLED()
    self.__combat = false
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function meter_proto:PLAYER_REGEN_DISABLED()
    self.__combat = true
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:Init()
end

function meter_proto:UNIT_PET(unit)
    self.pet_guid = UnitGUID(unit)
end

function meter_proto:Init()
    local inCombat = UnitAffectingCombat(self.unit) or self.__combat
    if inCombat then
        self:Reset()
        self:SetScript("OnUpdate", self.OnUpdate)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:SetScript("OnUpdate", nil)
    end
end

function meter_proto:Reset()
    local spec = GetSpecialization(false, false)
    local specRole = GetSpecializationRole(spec)
    self.isHealer = (specRole == "HEALER")

    self.damages = table.wipe(self.damages or {})
    self.damageIndexes = table.wipe(self.damageIndexes or {})
    self.heals = table.wipe(self.heals or {})
    self.healIndexes = table.wipe(self.healIndexes or {})

    -- self.start = time()
    self.start = nil
    self.damage = 0
    self.healing = 0
    self.overhealing = 0
    self.absorbed = 0
end

function meter_proto:UpdateText()
    if self.Text then
        if self.isHealer then
            local value = self.color:WrapTextInColorCode(E.ShortValue(self:GetHps()))
            self.Text:SetFormattedText(DATATEXT_STRING, HPS, value)
        else
            local value = self.color:WrapTextInColorCode(E.ShortValue(self:GetDps()))
            self.Text:SetFormattedText(DATATEXT_STRING, DPS, value)
        end
    end
end

function meter_proto:OnUpdate(elapsed)
    self.updateInterval = self.updateInterval - (elapsed or 1)
    if self.updateInterval <= 0 then
        if self.__combat then
            self:UpdateText()
        end
        self.updateInterval = UPDATE_INTERVAL
    end
end

function meter_proto:Update()
    self:OnEvent("ForceUpdate")
end

function meter_proto:Enable()
    self.guid = UnitGUID("player")
    self.pet_guid = UnitGUID("pet")

    self.updateInterval = 0

    self:Init()
    self:UpdateText()
	-- self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_PET")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Show()
end

function meter_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
    self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Meter", meter_proto)
