local _, ns = ...
local E = ns.E

-- Blizzard
local UnitClass = _G.UnitClass
local GetNumTalentTabs = _G.GetNumTalentTabs
local GetTalentTabInfo = _G.GetTalentTabInfo
local GetSpecialization = _G.GetSpecialization
local GetSpecializationRole = _G.GetSpecializationRole

local SPEC_DRUID_BALANCE = 3
local SPEC_MAGE_ARCANE = _G.SPEC_MAGE_ARCANE or 1
local SPEC_PRIEST_DISCIPLINE = _G.SPEC_PRIEST_DISCIPLINE or 1
local SPEC_PRIEST_HOLY = _G.SPEC_PRIEST_HOLY or 2
local SPEC_PRIEST_SHADOW = _G.SPEC_PRIEST_SHADOW or 3
-- local SPEC_MONK_MISTWEAVER = _G.SPEC_MONK_MISTWEAVER or 2
-- local SPEC_MONK_BREWMASTER = _G.SPEC_MONK_BREWMASTER or 1
-- local SPEC_MONK_WINDWALKER = _G.SPEC_MONK_WINDWALKER or 3
local SPEC_PALADIN_RETRIBUTION = _G.SPEC_PALADIN_RETRIBUTION or 3
local SPEC_WARLOCK_AFFLICTION = _G.SPEC_WARLOCK_AFFLICTION or 1
local SPEC_WARLOCK_DEMONOLOGY = _G.SPEC_WARLOCK_DEMONOLOGY or 2
local SPEC_WARLOCK_DESTRUCTION = _G.SPEC_WARLOCK_DESTRUCTION or 3

local SPEC_DRUID_RESTORATION = 1
local SPEC_DRUID_FERAL_COMBAT = 2
local SPEC_PALADIN_HOLY = 1
local SPEC_PALADIN_PROTECTION = 2
local SPEC_SHAMAN_RESTORATION = _G.SPEC_SHAMAN_RESTORATION or 3
local SPEC_WARRIOR_PROTECTION = 3

-- Mine
local element_proto = {}

function element_proto:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    else
        self:Update()
    end
end

if E.isClassic then
    local function SortTalentPoints(a, b)
        if a.points ~= b.points then
            return a.points > b.points
        end
        return a.index < b.index
    end

    function element_proto:Update()
        local _, class = UnitClass("player")

        local talent_points = {}

        local tabs = GetNumTalentTabs(false)
        for index = 1, tabs do
            local id, name, description, icon, pointsSpent, background, previewPointsSpent, isUnlocked = GetTalentTabInfo(index, false)
            table.insert(talent_points, { index = index, id = id, name = name, points = pointsSpent })
        end

        table.sort(talent_points, SortTalentPoints)

        self.class = class
        self.tab = talent_points[1].index
    end

    function element_proto:IsTank()
        if self.class == "DRUID" then
            return self.tab == SPEC_DRUID_FERAL_COMBAT
        elseif self.class == "PALADIN" then
            return self.tab == SPEC_PALADIN_PROTECTION
        elseif self.class == "WARRIOR" then
            return self.tab == SPEC_WARRIOR_PROTECTION
        end
        return false
    end
    
    function element_proto:IsHealer()
        if self.class == "DRUID" then
            return self.tab == SPEC_DRUID_RESTORATION
        elseif self.class == "PALADIN" then
            return self.tab == SPEC_PALADIN_HOLY
        elseif self.class == "PRIEST" then
            return self.tab == SPEC_PRIEST_DISCIPLINE
                or self.tab == SPEC_PRIEST_HOLY
        elseif self.class == "SHAMAN" then
            return self.tab == SPEC_SHAMAN_RESTORATION
        end
        return false
    end
    
    function element_proto:IsDamage()
        return not self:IsHealer() and not self:IsTank()
    end
else
    function element_proto:Update()
        self.spec = GetSpecialization(false, false)
        self.role = GetSpecializationRole(self.spec)
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
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

E:SetModule("Talents", frame)
