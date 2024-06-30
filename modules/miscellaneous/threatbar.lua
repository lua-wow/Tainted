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

function element_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if (self.elapsed < 1) then return end

    if UnitAffectingCombat("player") then
        local isTanking, status, threatPercentage, rawPercentage, threatValue = UnitDetailedThreatSituation(self.unit, "target")

        self:SetValue(threatPercentage or 0)

        if self.Text then
            self.Text:SetFormattedText("%.2f%%", threatPercentage or 0)
        end

        if self.Value then
            self.Value:SetText(UnitName("target") or "")
        end

        local color = E.ColorGradient(threatPercentage or 0, E.colors.threat[1], E.colors.threat[2], E.colors.threat[3])
        if color then
            self:SetStatusBarColor(color.r, color.g, color.b)

            if self.bg then
                local mu = self.bg.multiplier or 1
                self.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
            end
        end
    end

    self.elapsed = 0
end

function element_proto:OnShow()
    self:SetScript("OnUpdate", self.OnUpdate)
end

function element_proto:OnHide()
    self:SetScript("OnUpdate", nil)
end

function element_proto:OnEvent(event, ...)
    self[event](self, ...)
end

function element_proto:PLAYER_DEAD()
    self:Hide()
end

function element_proto:PLAYER_ENTERING_WORLD()
    self:Hide()
end

function element_proto:PLAYER_REGEN_ENABLED()
    self:Hide()
end

function element_proto:PLAYER_REGEN_DISABLED()
    self:Show()
end

function element_proto:UNIT_THREAT_SITUATION_UPDATE(unit)
end

function element_proto:UNIT_THREAT_LIST_UPDATE(unit)
end

local fontObject = E.GetFont(C.miscellaneous.font)

local frame = Mixin(CreateFrame("StatusBar", "TaintedThreatBar", E.PetHider), element_proto)
frame:SetPoint("TOP", 0, -10)
frame:SetSize(230, 18)
-- frame:SetFrameLevel(T.DataTexts.Panels.Right:GetFrameLevel() + 2)
frame:SetFrameStrata("HIGH")
frame:SetStatusBarTexture(C.miscellaneous.texture)
frame:SetMinMaxValues(0, 100)
-- frame:SetAlpha(0)
frame:CreateBackdrop()
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
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
-- frame.Text:SetShadowColor(0, 0, 0)
-- frame.Text:SetShadowOffset(1.25, -1.25)

local value = frame:CreateFontString(nil, "OVERLAY")
value:SetPoint("LEFT", frame, 10, 0)
value:SetFontObject(fontObject)
-- frame.Value:SetShadowColor(0, 0, 0)
-- frame.Value:SetShadowOffset(1.25, -1.25)

frame.bg = bg
frame.Text = text
frame.Value = value

E.ThreatBar = frame
