local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

local issecretvalue = _G.issecretvalue

--------------------------------------------------
-- Stagger
--------------------------------------------------
local element_proto = {}

function element_proto:PostUpdateColor(color)
    local element = self
    if (color and not issecretvalue(color)) then
        local bg = element.bg
        if (bg) then
            local mu = bg.multiplier or 1
            bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
        end
    end
end

function element_proto:PostUpdate(cur, max)
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
    if E.isMists and frame.ClassPower then
        element:SetPoint("BOTTOM", frame.ClassPower, "TOP", 0, 5)
    else
        element:SetPoint(unpack(C.unitframes.classpower.anchor))
    end
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
