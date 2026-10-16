local _, ns = ...
local E = ns.E

-- Blizzard
local UnitClass = _G.UnitClass
local GetNumTalentTabs = _G.GetNumTalentTabs
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo

-- talent tab indexes on Era, TBC and WotLK
local SPEC_DRUID_BALANCE = 1
local SPEC_DRUID_FERAL = 2
local SPEC_DRUID_RESTORATION = 3
local SPEC_PALADIN_HOLY = 1
local SPEC_PALADIN_PROTECTION = 2
local SPEC_PALADIN_RETRIBUTION = 3
local SPEC_PRIEST_DISCIPLINE = 1
local SPEC_PRIEST_HOLY = 2
local SPEC_PRIEST_SHADOW = 3
local SPEC_SHAMAN_ELEMENTAL = 1
local SPEC_SHAMAN_ENHANCEMENT = 2
local SPEC_SHAMAN_RESTORATION = 3

-- Mine
local TANK = "TANK"
local HEALER = "HEALER"
local DAMAGE = "DAMAGER"

-- Era, TBC and WotLK have no spec role, so it is inferred from talent points
local useTalentPoints = E.isVanilla or E.isTBC or E.isWrath

local element_proto = {
    unit = "player"
}

function element_proto:OnEvent(event, ...)
    if self[event] then
        self[event](self, event, ...)
    else
        E:error("No method for event", event)
    end
end

function element_proto:PLAYER_LOGIN()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    if useTalentPoints then
        self:RegisterEvent("PLAYER_TALENT_UPDATE")
        self:RegisterEvent("CHARACTER_POINTS_CHANGED")
    else
        self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", self.unit)
    end
end

function element_proto:PLAYER_ENTERING_WORLD(...)
    self:UpdateClass()
    self:Update()
end

function element_proto:PLAYER_TALENT_UPDATE()
    self:Update()
end

function element_proto:CHARACTER_POINTS_CHANGED()
    self:Update()
end

function element_proto:PLAYER_SPECIALIZATION_CHANGED()
    self:Update()
end

function element_proto:UpdateClass()
    local _, class = UnitClass(self.unit)
    self.class = class
end

if useTalentPoints then
    function element_proto:GetRole()
        self:UpdateTalents()

        if self.class == "DRUID" then
            local resto = self.talents[SPEC_DRUID_RESTORATION] or 0
            local feral = self.talents[SPEC_DRUID_FERAL] or 0
            local balance = self.talents[SPEC_DRUID_BALANCE] or 0
            if feral > resto and feral > balance then
                return TANK
            elseif resto > feral and resto > balance then
                return HEALER
            end
        elseif self.class == "PALADIN" then
            local holy = self.talents[SPEC_PALADIN_HOLY] or 0
            local prot = self.talents[SPEC_PALADIN_PROTECTION] or 0
            local retr = self.talents[SPEC_PALADIN_RETRIBUTION] or 0
            if holy > prot and holy > retr then
                return HEALER
            elseif prot > holy and prot > retr then
                return TANK
            end
        elseif self.class == "PRIEST" then
            local disc = self.talents[SPEC_PRIEST_DISCIPLINE] or 0
            local holy = self.talents[SPEC_PRIEST_HOLY] or 0
            local shadow = self.talents[SPEC_PRIEST_SHADOW] or 0
            if disc + holy > shadow then
                return HEALER
            end
        elseif self.class == "SHAMAN" then
            local elem = self.talents[SPEC_SHAMAN_ELEMENTAL] or 0
            local enha = self.talents[SPEC_SHAMAN_ENHANCEMENT] or 0
            local resto = self.talents[SPEC_SHAMAN_RESTORATION] or 0
            if resto > elem and resto > enha then
                return HEALER
            end
        elseif self.class == "WARRIOR" then
            -- every warrior tanks on Classic Era; use `/tainted dps` to swap
            return TANK
        end
        return DAMAGE
    end

    function element_proto:UpdateTalents()
        self.talents = table.wipe(self.talents or {})

        local tabs = GetNumTalentTabs(false)
        for index = 1, tabs do
            local _, _, _, _, _, _, pointsSpent = GetSpecializationInfo(index, false, false)
            self.talents[index] = pointsSpent
        end
    end
else
    function element_proto:GetRole()
        local spec = GetSpecialization()
        local role = spec and select(5, GetSpecializationInfo(spec))
        return role or DAMAGE
    end
end

-- `self.OnRoleChanged(role)` is called when the role changes; the raid holder sets it
function element_proto:Update()
    local role = (E.db and E.db.role) or self:GetRole()
    if role ~= self.role then
        self.role = role
        if self.OnRoleChanged then
            self.OnRoleChanged(role)
        end
    end
end

function element_proto:IsTank()
    return self.role == TANK
end

function element_proto:IsHealer()
    return self.role == HEALER
end

function element_proto:IsDamage()
    return self.role == DAMAGE
end

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

E:SetModule("Talents", frame)

-- manual role override, stored per character; nil uses the detected role
local function SetRole(role)
    E.db.role = role
    frame:Update()
    E:print("Role:", frame.role, role and "(manual)" or "(detected)")
end

E:AddCommand("healer", function() SetRole(HEALER) end, "Set healer role (raid frames in the centre).")
E:AddCommand("tank", function() SetRole(TANK) end, "Set tank role (raid frames above the chat).")
E:AddCommand("dps", function() SetRole(DAMAGE) end, "Set damage role (raid frames above the chat).")
E:AddCommand("auto", function() SetRole(nil) end, "Clear the manual role; use the detected one.")
