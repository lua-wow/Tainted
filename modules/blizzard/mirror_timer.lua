local addon, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:GetModule("Blizzard")

-- Blizzard
local GetMirrorTimerProgress = _G.GetMirrorTimerProgress
local MirrorTimerContainer = _G.MirrorTimerContainer
local MirrorTimerAtlas = _G.MirrorTimerAtlas

--------------------------------------------------
-- Mirror Timers (Underwater Breath, etc.)
--------------------------------------------------
local MirrorTimer = CreateFrame("Frame", addon .. "MirrorTimer")

function MirrorTimer:SetupTimer(timer, value, maxvalue, paused, label)
    local element = self:GetActiveTimer(timer) or self:GetAvailableTimer(timer)
    if (not element) then return end

    -- local texture = MirrorTimerAtlas[timer]
    local texture = C.unitframes.texture
    local font = A.fonts.normal

    if (not element.isSkinned) then
        element:SetHeight(18)
        element:StripTextures()
        element:CreateBackdrop()
        element:SetClipsChildren(true)

        local bg = element:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(element)
        bg:SetTexture(texture)
        bg.multiplier = C.general.background.multiplier or 0.15
        element.bg = bg

        if (element.StatusBar) then
            element.StatusBar:ClearAllPoints()
            element.StatusBar:SetInside()
        end

        if (element.Text) then
            element.Text:ClearAllPoints()
            element.Text:SetPoint("CENTER", element.StatusBar, "CENTER", 0, 0)
            element.Text:SetFont(font, 10, nil)
        end

        if (element.Border) then
            element.Border:SetTexture(nil)
        end

        if (element.TextBorder) then
            element.TextBorder:SetTexture(nil)
        end

        element.isSkinned = true
    end

    if (element.StatusBar) then
        local color = E.colors.mirror[timer]
        element.StatusBar:SetStatusBarTexture(texture)
        element.StatusBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        
        if (element.bg) then
            local mu = element.bg.multiplier or 1
            element.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu, color.a or 1)
        end
    end
end

function MirrorTimer:Init()
    hooksecurefunc(_G.MirrorTimerContainer, "SetupTimer", self.SetupTimer)
end

MODULE.MirrorTimer = MirrorTimer
