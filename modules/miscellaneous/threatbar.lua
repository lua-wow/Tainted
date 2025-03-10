local _, ns = ...
local E, C = ns.E, ns.C

-- Blizzard
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitDetailedThreatSituation = _G.UnitDetailedThreatSituation
local UnitIsDead = _G.UnitIsDead
local UnitName = _G.UnitName

--------------------------------------------------
-- Threat Bar
--------------------------------------------------
if not C.miscellaneous.threatbar then return end

local element_proto = {
    unit = "player"
}

function element_proto:UpdateAnchor()
    local anchor = _G["TaintedChatRightDataText"]
    if anchor then
        self:ClearAllPoints()
        self:SetAllPoints(anchor)
    end
end

function element_proto:Update()
    if not UnitAffectingCombat("player") then return end

    local isTanking, status, percentage, _, _ = UnitDetailedThreatSituation(self.unit, "target")
    
    if not percentage then
        percentage = 0
    end

    if status then
        self:SetValue(percentage)
        
        if self.Text then
            self.Text:SetFormattedText("%.2f%%", percentage)
        end
        
        if self.Value then
            self.Value:SetText(UnitName("target") or "")
        end
        
        local color = E.ColorGradient(percentage, E.colors.threat[1], E.colors.threat[2], E.colors.threat[3])
        if color then
            self:SetStatusBarColor(color.r, color.g, color.b)
            
            if self.bg then
                local mu = self.bg.multiplier or 1
                self.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
            end
        end
        
        self:SetAlpha(1)
    else
        self:SetAlpha(0)
    end
end

function element_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.75 then
        self:Update()
        self.elapsed = 0
    end
end

function element_proto:OnShow()
    self:SetScript("OnUpdate", self.OnUpdate)
end

function element_proto:OnHide()
    self:SetScript("OnUpdate", nil)
end

function element_proto:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        if self.isInit then return end
        
        self:UnregisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_DEAD")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        -- self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
        -- self:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
        self:Hide()
        self.isInit = true
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateAnchor()
        self:Hide()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not self:IsShown() then
            self:Show()
            self:Update()
        end
    else
        if self:IsShown() then
            self:Hide()
        end
    end
end

local fontObject = E.GetFont(C.miscellaneous.font)

local frame = Mixin(CreateFrame("StatusBar", "TaintedThreatBar", E.PetHider), element_proto)
frame:SetPoint("TOP", 0, -10)
frame:SetSize(230, 18)
frame:SetFrameStrata("HIGH")
frame:SetStatusBarTexture(C.miscellaneous.texture)
frame:SetMinMaxValues(0, 100)
frame:CreateBackdrop()
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnShow", frame.OnShow)
frame:SetScript("OnHide", frame.OnHide)
frame:SetScript("OnEvent", frame.OnEvent)

local bg = frame:CreateTexture(nil, "BORDER")
bg:SetPoint("TOPLEFT", frame, 0, 0)
bg:SetPoint("BOTTOMRIGHT", frame, 0, 0)
bg:SetTexture(C.miscellaneous.texture)
bg:SetColorTexture(0, 0, 0)
bg.multiplier = C.general.background.multiplier or 0.15

local text = frame:CreateFontString(nil, "OVERLAY")
text:SetPoint("RIGHT", frame, -10, 0)
text:SetFontObject(fontObject)

local value = frame:CreateFontString(nil, "OVERLAY")
value:SetPoint("LEFT", frame, 10, 0)
value:SetFontObject(fontObject)

frame.bg = bg
frame.Text = text
frame.Value = value

E.ThreatBar = frame
