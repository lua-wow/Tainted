local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- SHAMAN
--------------------------------------------------
local tempest_proto = {}

function tempest_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed >= 0.1) then
		local remaining = (self.tempestExpirationTime or 0) - GetTime()
		if (remaining > 0) then
            if self.TimerBar then
			    self.TimerBar:SetValue(remaining)
            end

            if self.Timer then
			    self.Timer:SetFormattedText("%d s", remaining)
            end
		else
			if self.TimerBar then
			    self.TimerBar:SetValue(0)
            end

            if self.Timer then
			    self.Timer:SetText("")
            end
		end
		self.elapsed = 0
	end
end

function tempest_proto:PostUpdate()
    local element = self

    if element.Value then
        if element.tempestReady then
            element.Value:SetText("Tempest Ready!")
        else
            element.Value:SetFormattedText("%d / %d (%d / %d)", element.maelstromStacks, element.maelstromSpentTotal, element.tempestStacks, element.awakeningStacks)
        end
    end

    if element.TimerBar then
        if element.tempestReady and element.tempestDuration and element.tempestExpirationTime then
            element.TimerBar:SetMinMaxValues(0, element.tempestDuration)
            element.TimerBar:Show()
            element:SetScript("OnUpdate", element.OnUpdate)
        else
            element.TimerBar:Hide()
            element:SetScript("OnUpdate", nil)
        end
    end

    if element.Timer then
        if element.tempestReady and element.tempestDuration and element.tempestExpirationTime then
            -- element.TimerBar:SetMinMaxValues(0, element.tempestDuration)
            element.Timer:Show()
            element:SetScript("OnUpdate", element.OnUpdate)
        else
            element.Timer:Hide()
            element:SetScript("OnUpdate", nil)
        end
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

    local statusbar = CreateFrame("StatusBar", nil, element)
    -- statusbar:SetAllPoints(element)
    statusbar:SetPoint("BOTTOM", element, "BOTTOM", 0, 0)
    statusbar:SetPoint("BOTTOMRIGHT", element, "BOTTOMRIGHT", 0, 0)
    statusbar:SetHeight(2)
    statusbar:SetStatusBarTexture(texture)
    statusbar:SetFrameLevel(element:GetFrameLevel() + 1)
    statusbar:SetStatusBarColor(1.00, 1.00, 1.00, 0.6)
    statusbar:SetMinMaxValues(0, 1)
    statusbar:SetValue(0)
    -- statusbar:SetAlpha(0.5)
    statusbar:Hide()
    element.TimerBar = statusbar

    local timer = element:CreateFontString(nil, "OVERLAY")
    timer:SetPoint("RIGHT", element, "RIGHT", -5, 0)
    timer:SetFontObject(fontObject)
    timer:SetTextColor(0.84, 0.75, 0.65)
    timer:SetJustifyH("CENTER")
    element.Timer = timer

    return element
end

function UnitFrames:SHAMAN(frame)
    if E.isRetail then
        frame.Tempest = self:CreateTempest(frame)
    end
end
