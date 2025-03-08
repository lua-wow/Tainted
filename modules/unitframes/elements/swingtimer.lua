local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- SwingTimer
--------------------------------------------------
function UnitFrames:CreateSwingTimer(frame)
    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)

    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 20
    local spacing = C.unitframes.classpower.spacing or 5

    local element = CreateFrame("Frame", nil, frame)
    element:SetPoint(unpack(C.unitframes.classpower.anchor))
    element:SetSize(width, (2 * height) + spacing)

    do
        local statusbar = CreateFrame("StatusBar", nil, element)
        statusbar:SetSize(width, height)
        statusbar:SetPoint("TOP", element, "TOP", 0, 0)
        statusbar:SetStatusBarTexture(texture)
        statusbar:SetStatusBarColor(0.8, 0.4, 0.4)
        statusbar:CreateBackdrop()

        local bg = statusbar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(statusbar)
        bg:SetTexture(texture)
        bg.multiplier = C.general.background.multiplier or 0.15
        statusbar.bg = bg

        local text = statusbar:CreateFontString(nil, "OVERLAY")
        text:SetPoint("RIGHT", statusbar, "RIGHT", -spacing, 0)
        text:SetFontObject(fontObject)
        text:SetText("0.0s")
        statusbar.Text = text

        element.MainHand = statusbar
    end

    do
        local statusbar = CreateFrame("StatusBar", nil, element)
        statusbar:SetPoint("TOP", element.MainHand or element, "BOTTOM", 0, -spacing)
        statusbar:SetSize(width, height)
        statusbar:SetStatusBarTexture(texture)
        statusbar:SetStatusBarColor(0.8, 0.4, 0.4)
        statusbar:CreateBackdrop()

        local bg = statusbar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(statusbar)
        bg:SetTexture(texture)
        bg.multiplier = C.general.background.multiplier or 0.15
        statusbar.bg = bg

        local text = statusbar:CreateFontString(nil, "OVERLAY")
        text:SetPoint("RIGHT", statusbar, "RIGHT", -spacing, 0)
        text:SetFontObject(fontObject)
        text:SetText("0.0s")
        statusbar.Text = text

        element.OffHand = statusbar
    end

    return element
end
