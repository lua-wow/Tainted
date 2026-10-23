local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Power
--------------------------------------------------
do
    local element_proto = {
        frequentUpdates = true,
        colorDisconnected = true,
        colorPower = true
    }
        
    function UnitFrames:CreatePower(frame, textParent)
        local ref = textParent or frame.Health
        local texture = C.unitframes.texture
        local font = E.GetFont(C.unitframes.font)
        local color = C.unitframes.power.prediction.color

        local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Power", frame), element_proto)
        element:SetStatusBarTexture(texture)
        element:SetFrameLevel(frame:GetFrameLevel() + 1)
        element:SetPoint("TOP", frame.Health, "BOTTOM", 0, -1)
        element:SetPoint("LEFT", frame, "LEFT", 0, 0)
        element:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        element:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
        element:SetClipsChildren(false)
        
        local prediction = CreateFrame("StatusBar", nil, element)
        prediction:SetReverseFill(true)
        prediction:SetPoint("TOP")
        prediction:SetPoint("BOTTOM")
        prediction:SetPoint("RIGHT", element:GetStatusBarTexture(), "RIGHT")
        prediction:SetStatusBarTexture(texture)
        prediction:SetStatusBarColor(color:GetRGBA())
        element.CostPrediction = prediction

        local tag = frame.__config.tags.power
        if (tag) then
            local value = ref:CreateFontString(nil, "OVERLAY")
            value:SetPoint("LEFT", ref, "LEFT", 5, 0)
            value:SetFontObject(font)
            value:SetJustifyH("LEFT")
            value:SetWordWrap(false)

            frame:Tag(value, tag)

            element.Value = value
        end

        return element
    end
end

--------------------------------------------------
-- Additional Power
-- example: Druid Balance Mana
--------------------------------------------------
do
    local element_proto = {
        -- smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut,
        frequentUpdates = true,
        colorPower = true,
        colorPowerSmooth = false
    }
        
    function UnitFrames:CreateAdditionalPower(frame)
        local height = (C.unitframes.power.height or 5) - 1
        local texture = C.unitframes.texture
        local color = C.unitframes.power.prediction.color

        local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "AdditionalPower", frame), element_proto)
        element:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
        element:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -3)
        element:SetHeight(height)
        element:SetStatusBarTexture(texture)
        element:CreateBackdrop()

        local prediction = CreateFrame("StatusBar", nil, element)
        prediction:SetReverseFill(true)
        prediction:SetPoint("TOP")
        prediction:SetPoint("BOTTOM")
        prediction:SetPoint("RIGHT", element:GetStatusBarTexture(), "RIGHT")
        prediction:SetStatusBarTexture(texture)
        prediction:SetStatusBarColor(color:GetRGBA())
        element.CostPrediction = prediction

        return element
    end
end

--------------------------------------------------
-- Alternative Power
-- e.g: encounter, quest-related (hour glass charnges Murozond dungeon End Time)
--------------------------------------------------
do
    local GetUnitPowerBarStrings = _G.GetUnitPowerBarStrings
    local GetUnitPowerBarStringsByID = _G.GetUnitPowerBarStringsByID
    local UnitPowerBarID = _G.UnitPowerBarID

    local element_proto = {
        -- smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut,
        colorPower = true,
        colorPowerSmooth = false
    }

    function element_proto:PostUpdate(unit, cur, min, max)
        -- bar is hidden / no alternative power
        if (not cur) then
            return
        end

        local barID = UnitPowerBarID(unit)
        local name = GetUnitPowerBarStringsByID(barID) or GetUnitPowerBarStrings(unit)

        if (self.Text) then
            self.Text:SetText(name)
        end

        if (self.Value) then
            -- UnitPower/UnitPowerMax are secret when power is restricted (Retail)
            if (issecretvalue(cur) or issecretvalue(max)) then
                self.Value:SetText("")
            elseif (max and max ~= 0) then
                local perc = 100 * ((cur - min) / (max - min))
                self.Value:SetFormattedText("%d%%", perc)
            else
                self.Value:SetText("")
            end
        end
    end
        
    function UnitFrames:CreateAlternativePower(frame)
        local texture = C.unitframes.texture

        local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "AlternativePower", frame), element_proto)
        element:SetStatusBarTexture(texture)
        element:CreateBackdrop()
        element:EnableMouse(true)
        
        if (frame.__key == "player") then
            local font = A.fonts.normal

            element:SetPoint("TOP", E.PetHider, "TOP", 0, -10)
            element:SetSize(250, 20)

            local text = element:CreateFontString(nil, "OVERLAY")
            text:SetPoint("LEFT", element, "LEFT", 5, 0)
            text:SetFont(font, 10, "")
            
            local value = element:CreateFontString(nil, "OVERLAY")
            value:SetPoint("RIGHT", element, "RIGHT", -5, 0)
            value:SetFont(font, 10, "")
            
            element.Text = text
            element.Value = value
        else
            local height = (C.unitframes.power.height or 5) - 1
            element:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
            element:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -3)
            element:SetHeight(height)
        end
        
        return element
    end
end
