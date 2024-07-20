local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

-- Blizzard
local UnitIsFriend = _G.UnitIsFriend
local UnitIsEnemy = _G.UnitIsEnemy

--------------------------------------------------
-- Auras
--------------------------------------------------
local element_proto = {
    -- color = E:CreateColor(0.81, 0.71, 0.23)
}

function UnitFrames:CreateAtonement(frame)
    local parent = frame.Health
    local texture = C.unitframes.texture

    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Atonement", parent), element_proto)
    element:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    element:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    element:SetHeight((C.unitframes.power.height or 4) - 1)
    element:SetStatusBarTexture(texture)

    local bg = element:CreateTexture(nil, "BORDER")
    bg:SetAllPoints()
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg

    return element
end
