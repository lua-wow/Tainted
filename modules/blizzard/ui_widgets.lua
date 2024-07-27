local addon, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:GetModule("Blizzard")

-- Blizzard
local UIWidgetPowerBarContainerFrame = _G.UIWidgetPowerBarContainerFrame
local UIWidgetBelowMinimapContainerFrame = _G.UIWidgetBelowMinimapContainerFrame
local IsInJailersTower = _G.IsInJailersTower

--------------------------------------------------
-- UIWidget
--------------------------------------------------
if not C.blizzard.uiwidgets then return end

local UIWidgets = CreateFrame("Frame", addon .. "UIWidgets")

function UIWidgets:CreateHolder()
    local element = CreateFrame("Frame", E.name .. "Widgets", UIParent)
    element:SetPoint("TOP", 0, -100)
    element:SetSize(220, 30)
    return element
end

function UIWidgets:Setup(widgetInfo, widgetContainer)
    if self:IsForbidden() then return end
    
    local bar = self.Bar
    if (not bar or bar:IsForbidden()) then return end

    local isTorghast = IsInJailersTower and IsInJailersTower() or false

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
        bar.Backdrop:SetOutside()

        -- create a background
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(bar)
        bar.bg:SetTexture(texture)
        bar.bg.multiplier = C.general.background.multiplier or 0.15

        local texture = A.textures.blank

        if (not isTorghast) then
            bar:SetStatusBarTexture(texture)
        end

        bar.isSkinned = true
    end

    local r, g, b = bar:GetStatusBarColor()
    if (bar.bg) then
        local mu = bar.bg.multiplier or 1
        bar.bg:SetVertexColor((r or 1) * mu, (g or 1) * mu, (b or 1) * mu)
    end

	-- Just hate that thing to be in objective tracker
	if (isTorghast) then
		-- local Container = self:GetParent()
		-- Container:SetParent(UIWidgets.Holder)
		-- Container:ClearAllPoints()
		-- Container:SetPoint("TOP", UIWidgets.Holder, "TOP", 0, 0)
		widgetContainer:ClearAllPoints()
		widgetContainer:SetPoint("TOP", UIParent, "TOP", 0, -70)
	end
end

function UIWidgets:UpdatePowerBarPosition()
    if UIWidgetPowerBarContainerFrame then
        UIWidgetPowerBarContainerFrame:SetParent(self.Holder)
        UIWidgetPowerBarContainerFrame:ClearAllPoints()
        UIWidgetPowerBarContainerFrame:SetPoint("CENTER")
	end

	-- Skin status bars
	hooksecurefunc(UIWidgetTemplateStatusBarMixin, "Setup", self.Setup)
end

function UIWidgets:Init()
    self.Holder = self:CreateHolder()
    self:UpdatePowerBarPosition()
end

MODULE.UIWidgets = UIWidgets
