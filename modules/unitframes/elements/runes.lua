local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

-- Blizzard
local GetRuneType = _G.GetRuneType
local GetRuneCooldown = _G.GetRuneCooldown

--------------------------------------------------
-- Runes
--------------------------------------------------
local MAX_RUNES = _G.MAX_RUNES or 6

local element_proto = {
    colorSpec = false
}

-- function element_proto:PostUpdate(runemap)
--     local element = self
--     for index, runeID in next, runemap do
--         local rune = element[index]
--         local start, duration, runeReady = GetRuneCooldown(runeID)
--         if (runeReady) then
--             rune:SetAlpha(1)
--         else
--             rune:SetAlpha(0.5)
--         end
--     end
-- end

if (E.isCata) then
    function element_proto:UpdateColor(...)
        local element = self.Runes
        for i = 1, #element do
            local type = GetRuneType(i)
            local color = E.colors.runes[type]
            local bar = element[i]
            bar:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
end

function UnitFrames:CreateRunes(frame)
    local texture = C.unitframes.texture
    local width = C.unitframes.classpower.width
    local height = C.unitframes.classpower.height

    local element = Mixin(CreateFrame("Frame", frame:GetName() .. "RuneBar", frame), element_proto)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, height)

    local spacing = 3
    local sizes = E.CalcSegmentsSizes(MAX_RUNES, width, spacing)
    
    for i = 1, MAX_RUNES do
        local size = sizes[i]
        
        local row = CreateFrame("StatusBar", element:GetName() .. i, element)
        row:SetSize(size, height - 2)
        row:SetStatusBarTexture(texture)
        row:CreateBackdrop()

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetTexture(texture)
        row.bg:SetAlpha(0.75)
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
