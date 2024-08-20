local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Class Power
--------------------------------------------------
local NUM_MAX = {
    ["ALL"] = 5,        -- COMBO POINTS
    ["EVOKER"] = 6,     -- ESSENSES
    ["MAGE"] = 4,       -- ARCANE CHARGES
    ["MONK"] = 6,       -- CHI ORB
    ["PALADIN"] = 5,    -- HOLY POWER
    ["WARLOCK"] = 5     -- SOUL SHARDS
}

local element_proto = {}

-- function element_proto:UpdateColor(powerType)
--     for i = 1, #self do
--         local color = (powerType == "COMBO_POINTS")
--             and E.colors.combopoints[i]
--             or E.colors.power[powerType]

--         local bar = self[i]
--         bar:SetStatusBarColor(color.r, color.g, color.b)

--         if (bar.bg) then
--             local mu = bar.bg.multiplier or 1
--             bar.bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
--         end
--     end
-- end
    
function UnitFrames:CreateClassPower(frame)
    local texture = C.unitframes.texture
    local width = C.unitframes.classpower.width
    local height = C.unitframes.classpower.height

    local element = Mixin(CreateFrame("Frame", frame:GetName() .. "ClassPower", frame), element_proto)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, height)

    local spacing = C.unitframes.classpower.spacing or 5
    local max = NUM_MAX[frame.__class] or 5
    local sizes = E.CalcSegmentsSizes(max, width, spacing)
    
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
