local _, ns = ...
local E = ns.E

-- Blizzard
local UnitClass = _G.UnitClass
local GetNumTalentTabs = _G.GetNumTalentTabs
local GetTalentTabInfo = _G.GetTalentTabInfo
local GetSpecialization = _G.GetSpecialization
local GetSpecializationRole = _G.GetSpecializationRole

local SPEC_DEATHKNIGHT_BLOOD = 1
local SPEC_DEATHKNIGHT_FROST = 2
local SPEC_DEATHKNIGHT_UNHOLY = 3
local SPEC_DRUID_RESTORATION = 1
local SPEC_DRUID_FERAL_COMBAT = 2
local SPEC_DRUID_BALANCE = 3
local SPEC_MAGE_ARCANE = _G.SPEC_MAGE_ARCANE or 1
local SPEC_MONK_BREWMASTER = _G.SPEC_MONK_BREWMASTER or 1
local SPEC_MONK_MISTWEAVER = _G.SPEC_MONK_MISTWEAVER or 2
local SPEC_MONK_WINDWALKER = _G.SPEC_MONK_WINDWALKER or 3
local SPEC_PALADIN_HOLY = 1
local SPEC_PALADIN_PROTECTION = 2
local SPEC_PALADIN_RETRIBUTION = _G.SPEC_PALADIN_RETRIBUTION or 3
local SPEC_PRIEST_DISCIPLINE = _G.SPEC_PRIEST_DISCIPLINE or 1
local SPEC_PRIEST_HOLY = _G.SPEC_PRIEST_HOLY or 2
local SPEC_PRIEST_SHADOW = _G.SPEC_PRIEST_SHADOW or 3
local SPEC_SHAMAN_ELEMENTAL = _G.SPEC_SHAMAN_ELEMENTAL or 1
local SPEC_SHAMAN_ENHANCEMENT = _G.SPEC_SHAMAN_ENHANCEMENT or 2
local SPEC_SHAMAN_RESTORATION = _G.SPEC_SHAMAN_RESTORATION or 3
local SPEC_WARLOCK_AFFLICTION = _G.SPEC_WARLOCK_AFFLICTION or 1
local SPEC_WARLOCK_DEMONOLOGY = _G.SPEC_WARLOCK_DEMONOLOGY or 2
local SPEC_WARLOCK_DESTRUCTION = _G.SPEC_WARLOCK_DESTRUCTION or 3
local SPEC_WARRIOR_ARMS = 1
local SPEC_WARRIOR_FURY = 2
local SPEC_WARRIOR_PROTECTION = 3

-- Mine
local element_proto = {}

function element_proto:OnEvent(event, ...)
    if self[event] then
        self[event](self, event, ...)
    else
        E:error("No method for event", event)
    end
end

function element_proto:PLAYER_LOGIN()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    if E.isRetail then
        self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    else
        self:RegisterEvent("PLAYER_TALENT_UPDATE")
    end
end

function element_proto:PLAYER_ENTERING_WORLD(...)
    self:UpdateClass()
    self:Update()
end

function element_proto:PLAYER_TALENT_UPDATE()
    self:Update()
end

function element_proto:PLAYER_SPECIALIZATION_CHANGED()
    self:Update()
end

function element_proto:UpdateClass()
    local _, class = UnitClass("player")
    self.class = class
end

if E.isClassic then
    function element_proto:GetRole()
        if self.class == "DRUID" then
            local resto = self.talents[SPEC_DRUID_RESTORATION] or 0
            local feral = self.talents[SPEC_DRUID_FERAL_COMBAT] or 0
            local balance = self.talents[SPEC_DRUID_BALANCE] or 0
            if feral > resto and feral > balance then
                return "TANK"
            elseif resto > feral and resto > balance then
                return "HEALER"
            end
        elseif self.class == "PALADIN" then
            local holy = self.talents[SPEC_PALADIN_HOLY] or 0
            local prot = self.talents[SPEC_PALADIN_PROTECTION] or 0
            local retr = self.talents[SPEC_PALADIN_RETRIBUTION] or 0
            if holy > prot and holy > retr then
                return "HEALER"
            elseif prot > holy and prot > retr then
                return "TANK"
            end
        elseif self.class == "PRIEST" then
            local disc = self.talents[SPEC_PRIEST_DISCIPLINE] or 0
            local holy = self.talents[SPEC_PRIEST_HOLY] or 0
            local shadow = self.talents[SPEC_PRIEST_SHADOW] or 0
            if disc + holy > shadow then
                return "HEALER"
            end
        elseif self.class == "SHAMAN" then
            local elem = self.talents[SPEC_SHAMAN_ELEMENTAL] or 0
            local enha = self.talents[SPEC_SHAMAN_ENHANCEMENT] or 0
            local resto = self.talents[SPEC_SHAMAN_RESTORATION] or 0
            if resto > elem and resto > enha then
                return "HEALER"
            end
        elseif self.class == "WARRIOR" then
            local arms = self.talents[SPEC_WARRIOR_ARMS] or 0
            local fury = self.talents[SPEC_WARRIOR_FURY] or 0
            local prot = self.talents[SPEC_WARRIOR_PROTECTION] or 0
            if (fury + prot) > arms then
                return "TANK"
            end
        end
        return "DAMAGE"
    end

    function element_proto:UpdateTalents()
        self.talents = table.wipe(self.talents or {})
        
        local tabs = GetNumTalentTabs(false)
        for index = 1, tabs do
            local _, name, _, _, pointsSpent, _, _, _ = GetTalentTabInfo(index, false)
            self.talents[index] = pointsSpent
        end
    end

    function element_proto:Update()
        self:UpdateTalents()
        self.role = self:GetRole()
    end
elseif E.isCata then
    function element_proto:GetRole()
        self.spec = GetPrimaryTalentTree(false, false)
        if self.class == "DRUID" then
            if self.spec == SPEC_DRUID_RESTORATION then
                return "HEALER"
            elseif self.spec == SPEC_DRUID_FERAL_COMBAT then
                return "TANK"
            end
        elseif self.class == "DEATHKNIGHT" and self.spec == SPEC_DEATHKNIGHT_FROST then
            return "TANK"
        elseif self.class == "PALADIN" and self.spec == SPEC_PALADIN_HOLY then
            return "HEALER"
        elseif self.class == "PRIEST" and self.spec ~= SPEC_PRIEST_SHADOW then
            return "HEALER"
        elseif self.class == "SHAMAN" and self.spec == SPEC_SHAMAN_RESTORATION then
            return "HEALER"
        elseif self.class == "WARRIOR" and self.spec == SPEC_WARRIOR_PROTECTION then
            return "TANK"
        end
        return "DAMAGE"
    end

    function element_proto:Update()
        self.role = self:GetRole()
        E:print("Talents Updated", self.class, self.spec, self.role)
    end
else
    function element_proto:Update()
        self.spec = GetSpecialization(false, false)
        self.role = GetSpecializationRole(self.spec)
    end
end

function element_proto:IsTank()
    return self.role == "TANK"
end

function element_proto:IsHealer()
    return self.role == "HEALER"
end

function element_proto:IsDamage()
    return self.role == "DAMAGE"
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

E:SetModule("Talents", frame)
