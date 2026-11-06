local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Swing Timer (Forever)
--------------------------------------------------
-- Blizzard keeps the swing/range logic and Edit Mode the scale, opacity and visibility; Tainted owns
-- the look, size and position (stacked below the class power). Never write frame.visibility: Blizzard
-- reads it before comparing UnitAttackSpeed, which is secret in combat, and errors under taint.
if not C.blizzard.swingtimer then return end

local texture = C.unitframes.texture
local font = A.fonts.normal

local width = C.unitframes.classpower.width
local height = C.unitframes.classpower.height
local spacing = C.unitframes.classpower.spacing or 5

local SwingTimer = CreateFrame("Frame", "TaintedSwingTimer", UIParent)
-- stands in for the class power: Blizzard tweaks initialise before the unit frames
SwingTimer:SetPoint(unpack(C.unitframes.classpower.anchor))
SwingTimer:SetSize(width, height)

local frames = {}

-- shown timers stack downward without gaps; Base methods skip Edit Mode's overrides (and our hook)
local function Layout()
    local previous = SwingTimer
    for _, frame in ipairs(frames) do
        if frame:IsShown() then
            frame:ClearAllPointsBase()
            frame:SetPointBase("TOP", previous, "BOTTOM", 0, -E.Scale(spacing))
            previous = frame
        end
    end
end

-- Edit Mode re-applies its width/height on every layout update
local function Resize(frame)
    frame:SetSize(width, height)
end

local function Skin(frame)
    -- Blizzard only changes their alpha afterwards
    frame.Background:Hide()
    frame.Border:Hide()
    frame:CreateBackdrop()

    local bar = frame.StatusBar
    bar:SetInside(frame, 0, 0)
    bar:SetStatusBarTexture(texture)
    bar.Pip:SetAlpha(0)
    bar.TypeLabelShadow:SetTexture(nil)
    bar.TypeLabel:SetFont(font, 10, nil)
    bar.TimeLabel:SetFont(font, 10, nil)

    local color = E.colors.swing[frame.swingType]
    bar:SetStatusBarColor(color.r, color.g, color.b)

    -- on the bar so Blizzard's out-of-range alpha dims it too
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture(texture)
    local mu = C.general.background.multiplier or 0.15
    bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
end

function SwingTimer:Init()
    frames[1] = _G.SwingTimerMainHandFrame
    frames[2] = _G.SwingTimerOffHandFrame
    frames[3] = _G.SwingTimerRangedFrame

    for _, frame in ipairs(frames) do
        Skin(frame)
        Resize(frame)

        hooksecurefunc(frame, "UpdateSystemSettingWidth", Resize)
        hooksecurefunc(frame, "UpdateSystemSettingHeight", Resize)
        -- the bottom managed container and Edit Mode place it through the SetPoint override
        hooksecurefunc(frame, "SetPoint", Layout)
        frame:HookScript("OnShow", Layout)
        frame:HookScript("OnHide", Layout)
    end

    Layout()
end

MODULE.SwingTimer = SwingTimer
