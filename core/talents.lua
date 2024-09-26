local _, ns = ...
local E = ns.E

local element_proto = {}

function element_proto:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    else
        self:Update()
    end
end

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

local frame = Mixin(CreateFrame("Frame"), element_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", frame.OnEvent)

E:SetModule("Talents", frame)
