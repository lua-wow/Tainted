local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- SHAMAN
--------------------------------------------------
local tempest_proto = {}

function tempest_proto:OnUpdate(elapsed)
    local duration = self.duration
    if (not duration) then return end

    self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed >= 0.1) then
		local remaining = duration:GetRemainingDuration(0)
		if (remaining) then
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

function tempest_proto:PostUpdate(cur, max, total, ready)
    local element = self

    local duration = element.tempest and element.tempest.duration
    element.duration = duration

    if element.TimerBar then
        if ready and duration then
            element.TimerBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            element.TimerBar:Show()
            element:SetScript("OnUpdate", element.OnUpdate)
        else
            element.TimerBar:Hide()
            element:SetScript("OnUpdate", nil)
        end
    end

    if element.Timer then
        if ready and duration then
            -- element.Timer:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            element.Timer:Show()
            -- element:SetScript("OnUpdate", element.OnUpdate)
        else
            element.Timer:Hide()
            -- element:SetScript("OnUpdate", nil)
        end
    end
end

function UnitFrames:CreateTempest(frame)
    -- oUF_Tempest loads on Retail only
    if not E.isStandard then return end

    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)

    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 18

    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Tempest", frame), tempest_proto)
    if frame.ClassPower then
        element:SetPoint("TOPLEFT", frame.ClassPower, "BOTTOMLEFT", 0, -5)
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
    local tempest = self:CreateTempest(frame)
    if not tempest then return end
    frame.Tempest = tempest

    -- totems sit below tempest while it is shown, otherwise at the class power anchor
    local totems = frame.Totems
    if totems then
        tempest:HookScript("OnShow", function()
            totems:ClearAllPoints()
            totems:SetPoint("TOPLEFT", tempest, "BOTTOMLEFT", 0, -5)
        end)
        tempest:HookScript("OnHide", function()
            totems:ClearAllPoints()
            totems:SetPoint(unpack(C.unitframes.classpower.anchor))
        end)
    end
end
