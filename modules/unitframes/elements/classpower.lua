local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

-- Constants
local POWER_TYPE_MAELSTROM = 'MAELSTROM'

local SPELL_MAELSTROM_WEAPON = 344179

local INTERPOLATION = Enum.StatusBarInterpolation.Immediate
local DIRECTION = Enum.StatusBarTimerDirection.RemainingTime

local CLASS_POWER_MAX = 10

--------------------------------------------------
-- Class Power
--------------------------------------------------
local element_proto = {}

function element_proto:GetElementSize(max)
    local width = C.unitframes.classpower.width
    local spacing = C.unitframes.classpower.spacing or 5
    return E.CalcSegmentsSizes(max, width, spacing)
end

function element_proto:PostUpdateColor(color)
    local element = self

    if (color and not issecretvalue(color)) then
        local mu = C.general.background.multiplier or 0.15

        for i = 1, #element do
            local bg = element[i].bg
            if (bg) then
                bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu, color.a or 1)
            end
        end
    end
end

function element_proto:PostUpdate(cur, max, hasMaxChanged, powerType, ...)
    local element = self

    local changedPoints = ...

    if hasMaxChanged then
        local sizes = element:GetElementSize(max)

        for i = 1, #element do
            element[i]:SetWidth(sizes[i] or 0)
        end
    end

    if powerType == POWER_TYPE_MAELSTROM then
        local data = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_MAELSTROM_WEAPON)
        local duration = data and C_UnitAuras.GetAuraDuration("player", data.auraInstanceID)
        if duration then
            for i = 1, #element do
                if i <= cur then
                    element[i]:SetTimerDuration(duration, INTERPOLATION, DIRECTION)
                else
                    element[i]:SetMinMaxValues(0, 1)
                    element[i]:SetValue(0)
                end
            end
        else
            for i = 1, #element do
                element[i]:SetMinMaxValues(0, 1)
                element[i]:SetValue(0)
            end
        end
    end
end
    
function UnitFrames:CreateClassPower(frame)
    local texture = C.unitframes.texture
    local width = C.unitframes.classpower.width
    local height = C.unitframes.classpower.height
    local spacing = C.unitframes.classpower.spacing or 5

    local element = Mixin(CreateFrame("Frame", frame:GetName() .. "ClassPower", frame), element_proto)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, height)
    element.__class = frame.__class or "NONE"

    local max = CLASS_POWER_MAX
    local sizes = element:GetElementSize(max)

    for i = 1, max do
        local size = sizes[i]

        local segment = CreateFrame("StatusBar", element:GetName() .. i, element)
        segment:SetSize(size, height - 2)
        segment:SetStatusBarTexture(texture)
        segment:CreateBackdrop()
        
        local bg = segment:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(segment)
        bg:SetTexture(texture)
        bg.multiplier = C.general.background.multiplier or 0.15
        segment.bg = bg

        if (i == 1) then
            segment:SetPoint("TOPLEFT", element, "TOPLEFT", E.Scale(1), -E.Scale(1))
        else
            local previous = element[i - 1]
            segment:SetPoint("LEFT", previous, "RIGHT", E.Scale(spacing), 0)
        end

        element[i] = segment
    end

    return element
end
