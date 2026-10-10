local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- UIWidget
--------------------------------------------------
if not C.blizzard.uiwidgets then return end

local UIWidgets = {}

function UIWidgets:Setup()
    if self:IsForbidden() then return end
    
    local bar = self.Bar
    if (not bar or bar:IsForbidden()) then return end

    local texture = A.textures.blank

    if (not bar.isSkinned) then
        -- hide border textures
        if (bar.BGLeft) then bar.BGLeft:SetAlpha(0) end
        if (bar.BGRight) then bar.BGRight:SetAlpha(0) end
        if (bar.BGCenter) then bar.BGCenter:SetAlpha(0) end
        if (bar.BorderLeft) then bar.BorderLeft:SetAlpha(0) end
        if (bar.BorderRight) then bar.BorderRight:SetAlpha(0) end
        if (bar.BorderCenter) then bar.BorderCenter:SetAlpha(0) end
        if (bar.GlowLeft) then bar.GlowLeft:SetAlpha(0) end
        if (bar.GlowRight) then bar.GlowRight:SetAlpha(0) end
        if (bar.GlowCenter) then bar.GlowCenter:SetAlpha(0) end
        if (bar.BackgroundGlow) then bar.BackgroundGlow:SetAlpha(0) end
        if (bar.Spark) then bar.Spark:SetAlpha(0) end
        
        -- add backdrop
        bar:CreateBackdrop()
        -- bar.Backdrop:SetOutside()

        -- create a background
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(bar)
        bar.bg:SetTexture(texture)
        bar.bg.multiplier = C.general.background.multiplier or 0.15

        bar.isSkinned = true
    end

    -- every Setup: a pooled bar reused for another texture kit gets Blizzard's fill atlas back
    bar:SetStatusBarTexture(texture)

    local r, g, b = bar:GetStatusBarColor()
    if (bar.bg) then
        local mu = bar.bg.multiplier or 1
        bar.bg:SetVertexColor((r or 1) * mu, (g or 1) * mu, (b or 1) * mu)
    end
end

-- the power bar container stays where Blizzard puts it: it exists only on mainline, inside EncounterBar
function UIWidgets:Init()
    hooksecurefunc(UIWidgetTemplateStatusBarMixin, "Setup", self.Setup)
end

MODULE.UIWidgets = UIWidgets
