local _, ns = ...
local oUF = ns.oUF or _G.oUF
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

local DIRECTION_FORMAT = {
    ["moon"] = "< %d",
    ["sun"] = "%d >",
}

--------------------------------------------------
-- Eclipse Bar (Mists)
--------------------------------------------------
local element_proto = {}

function element_proto:UpdateText()
    if (self.Value and self.cur) then
        self.Value:SetFormattedText(DIRECTION_FORMAT[self.direction] or "%d", math.abs(self.cur))
    end
end

function element_proto:PostUpdate(cur)
    self.cur = cur
    self:UpdateText()
end

function element_proto:PostUpdateDirection(direction)
    self.direction = direction
    self:UpdateText()
end

local function CreateBar(parent, texture, color, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(texture)
    bar:SetStatusBarColor(color:GetRGB())
    return bar
end

function UnitFrames:CreateEclipseBar(frame)
    if (not E.isMists) then return end

    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)
    local colors = oUF.colors.power.ECLIPSE

    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 18

    local element = Mixin(CreateFrame("Frame", frame:GetName() .. "EclipseBar", frame), element_proto)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, height)
    element:CreateBackdrop()

    -- lunar fills from the left up to the current power, solar fills the rest
    -- local lunar = CreateBar(element, texture, colors.moon, width, height)
    local lunar = CreateFrame("StatusBar", nil, element)
    lunar:SetPoint("LEFT", element, "LEFT", 0, 0)
    lunar:SetSize(width, height)
    lunar:SetStatusBarTexture(texture)
    lunar:SetStatusBarColor(colors.moon:GetRGB())
    element.LunarBar = lunar

    -- local solar = CreateBar(element, texture, colors.sun, width, height)
    local solar = CreateFrame("StatusBar", nil, element)
    solar:SetPoint("LEFT", lunar:GetStatusBarTexture(), "RIGHT", 0, 0)
    solar:SetSize(width, height)
    solar:SetStatusBarTexture(texture)
    solar:SetStatusBarColor(colors.sun:GetRGB())
    element.SolarBar = solar

    local value = solar:CreateFontString(nil, "OVERLAY")
    value:SetPoint("CENTER", element, "CENTER", 0, 0)
    value:SetFontObject(fontObject)
    value:SetTextColor(0.84, 0.75, 0.65)
    value:SetJustifyH("CENTER")
    element.Value = value

    return element
end
