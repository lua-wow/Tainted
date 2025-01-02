local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:GetModule("Blizzard")

-- Blizzard
local GetMirrorTimerProgress = _G.GetMirrorTimerProgress
local MirrorTimerContainer = _G.MirrorTimerContainer
local MirrorTimerAtlas = _G.MirrorTimerAtlas

local MIRRORTIMER_NUMTIMERS = _G.MIRRORTIMER_NUMTIMERS

--------------------------------------------------
-- Mirror Timers (Underwater Breath, etc.)
--------------------------------------------------
local texture = C.unitframes.texture
local font = A.fonts.normal

local MirrorTimer = CreateFrame("Frame", "TaintedMirrorTimer")

function MirrorTimer:Skin(element)
    element:SetHeight(18)
    element:StripTextures()
    element:CreateBackdrop()
    element:SetClipsChildren(true)

    local bg = element:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(element)
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg

    local statusBar = element.StatusBar or _G[element:GetName() .. "StatusBar"]
    if (statusBar) then
        statusBar:ClearAllPoints()
        statusBar:SetInside()
        statusBar:SetStatusBarTexture(texture)
    end
    
    local text = element.Text or _G[element:GetName() .. "Text"]
    if (text) then
        text:ClearAllPoints()
        text:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
        text:SetFont(font, 10, nil)
    end
    
    local border = element.Border or _G[element:GetName() .. "Border"]
    if (border) then
        border:SetTexture(nil)
    end
    
    local border = element.TextBorder or _G[element:GetName() .. "TextBorder"]
    if (textBorder) then
        textBorder:SetTexture(nil)
    end

    element.__skinned = true
end

if not E.isRetail then
    MirrorTimer.MirrorTimer_Show = function(timer, value, maxvalue, scale, paused, label)
        for index = 1, MIRRORTIMER_NUMTIMERS, 1 do
            local frame = _G["MirrorTimer" .. index];
            if frame then
                if not frame.__skinned then
                    MirrorTimer:Skin(frame)
                end
    
                if frame.timer then
                    local color = E.colors.mirror[frame.timer]
                    local statusBar = frame.StatusBar or _G[frame:GetName() .. "StatusBar"]
                    if statusBar then
                        statusBar:SetStatusBarTexture(texture)
                        statusBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    
                        if (frame.bg) then
                            local mu = frame.bg.multiplier or 1
                            frame.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu, color.a or 1)
                        end
                    end
                end
            end
        end
    end

    function MirrorTimer:Init()
        hooksecurefunc("MirrorTimer_Show", self.MirrorTimer_Show)
    end
else
    function MirrorTimer:SetupTimer(timer, value, maxvalue, paused, label)
        local element = self:GetActiveTimer(timer) or self:GetAvailableTimer(timer)
        if (not element) then return end
    
        -- local texture = MirrorTimerAtlas[timer]
    
        if (not element.__skinned) then
            MirrorTimer:Skin(element)
        end
    
        local statusBar = element.StatusBar
        if (statusBar) then
            local color = E.colors.mirror[timer]
            E:print(timer, color)
            statusBar:SetStatusBarTexture(texture)
            statusBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
            
            if (element.bg) then
                local mu = element.bg.multiplier or 1
                element.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu, color.a or 1)
            end
        end
    end

    function MirrorTimer:Init()
        hooksecurefunc(_G.MirrorTimerContainer, "SetupTimer", self.SetupTimer)
    end
end

MODULE.MirrorTimer = MirrorTimer
