local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- SHAMAN
--------------------------------------------------
local tempest_proto = {}

function tempest_proto:PostUpdate()
    local element = self

    if element.Value then
        element.Value:SetFormattedText("%d / %d (%d)", element.value, element.total, element.tempest)
    end
end

function UnitFrames:CreateTempest(frame)
    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)

    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 18

    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Tempest", frame), tempest_proto)
    if frame.Totems then
        element:SetPoint("TOPLEFT", frame.Totems, "BOTTOMLEFT", 0, -5)
    else
        element:SetPoint(unpack(C.unitframes.classpower.anchor))
    end
    element:SetSize(width, height)
    element:SetStatusBarTexture(texture)
    element:SetMinMaxValues(0, 40)
    element:SetValue(20)
    element:CreateBackdrop()

    local bg = element:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg

    local value = element:CreateFontString(nil, "OVERLAY")
    value:SetPoint("CENTER", element, "CENTER", 0, 0)
    value:SetFontObject(fontObject)
    value:SetTextColor(0.84, 0.75, 0.65)
    value:SetJustifyH("CENTER")
    element.Value = value

    return element
end

function UnitFrames:SHAMAN(frame)
    if E.isRetail then
        frame.Tempest = self:CreateTempest(frame)
    end
end
