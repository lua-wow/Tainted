local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

-- Blizzard
local IsPlayerSpell = _G.IsPlayerSpell
local UnitClass = _G.UnitClass

local SPELL_POWER_CHI = _G.SPELL_POWER_CHI or 12

--------------------------------------------------
-- Class Power
--------------------------------------------------
local NUM_MAX = {
    ["ALL"] = 5,        -- COMBO POINTS
    ["EVOKER"] = 6,     -- ESSENSES
    ["MAGE"] = 4,       -- ARCANE CHARGES
    ["MONK"] = E.isMoP and 5 or 6, -- CHI ORB (5 max for MoP with Ascension)
    ["PALADIN"] = 5,    -- HOLY POWER
    ["WARLOCK"] = 5     -- SOUL SHARDS
}

local element_proto = {}

function element_proto:GetElementSize(max)
    local width = C.unitframes.classpower.width
    local spacing = C.unitframes.classpower.spacing or 5
    return E.CalcSegmentsSizes(max, width, spacing)
end

function element_proto:PostUpdate(cur, max, hasMaxChanged, powerType)
    local element = self
    if hasMaxChanged then
        local sizes = element:GetElementSize(max)

        for i = 1, #element do
            if element[i] then
                element[i]:SetWidth(sizes[i] or 0)
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
    element.__class = frame.__class or select(2, UnitClass("player"))

    local max = NUM_MAX[frame.__class] or 5
    local sizes = element:GetElementSize(max)
    
    for i = 1, max do
        local size = sizes[i]

        local row = CreateFrame("StatusBar", element:GetName() .. i, element)
        row:SetSize(size, height - 2)
        row:SetStatusBarTexture(texture)
        row:CreateBackdrop()
        
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetTexture(texture)
        row.bg.multiplier = C.general.background.multiplier or 0.15

        if (i == 1) then
            row:SetPoint("TOPLEFT", element, "TOPLEFT", E.Scale(1), -E.Scale(1))
        else
            local previous = element[i - 1]
            row:SetPoint("LEFT", previous, "RIGHT", E.Scale(spacing), 0)
        end

        element[i] = row
    end

    return element
end
