local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

-- percentages at which bar should change color
local STAGGER_YELLOW_TRANSITION =  _G.STAGGER_YELLOW_TRANSITION or 0.3
local STAGGER_RED_TRANSITION = _G.STAGGER_RED_TRANSITION or 0.6

-- table indices of bar colors
local STAGGER_GREEN_INDEX = _G.STAGGER_GREEN_INDEX or 1
local STAGGER_YELLOW_INDEX = _G.STAGGER_YELLOW_INDEX or 2
local STAGGER_RED_INDEX = _G.STAGGER_RED_INDEX or 3

--------------------------------------------------
-- Stagger
--------------------------------------------------
local element_proto = {}

function element_proto:GetColor(cur, max)
    local perc = cur / max
	if (perc >= STAGGER_RED_TRANSITION) then
		return E.colors.power[STAGGER_RED_INDEX]
    elseif (perc > STAGGER_YELLOW_TRANSITION) then
        return E.colors.power[STAGGER_YELLOW_INDEX]
    end
    return E.colors.power[STAGGER_GREEN_INDEX]
end

function element_proto:PostUpdate(cur, max)
	local color = self:GetColor(cur, max)

	self:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)

    if (self.Value) then
	    self.Value:SetFormattedText("%s / %s - %d%%", E.ShortValue(cur), E.ShortValue(max), 100 * (cur / max))
    end

	if (cur ~= 0) then
		self:Show()
	else
		self:Hide()
	end
end

function UnitFrames:CreateStagger(frame)
    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)

    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 18

    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Stagger", frame), element_proto)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, height)
    element:SetStatusBarTexture(texture)
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
