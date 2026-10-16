local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Auras
--------------------------------------------------
-- Retail, Forever: Atonement aura data is secret in combat, so the bar would miss every in-combat application
-- Classic: no Atonement buff and no Atonement element (oUF_Atonement is mainline only); an undriven bar draws full
local ENABLED = false

local element_proto = {
    -- color = E:CreateColor(0.81, 0.71, 0.23)
}

function UnitFrames:CreateAtonement(frame)
    if not ENABLED then return nil end

    local parent = frame.Power
    local texture = C.unitframes.texture

    -- covers the power bar while the buff is up; above its CostPrediction child, below TextParent
    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Atonement", parent), element_proto)
    element:SetAllPoints(parent)
    element:SetFrameLevel(parent:GetFrameLevel() + 2)
    element:SetStatusBarTexture(texture)

    local bg = element:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg

    return element
end
