local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Health
--------------------------------------------------
do
    local element_proto = {
        colorDisconnected = true,
        colorTapping = false,
        colorClass = true,
        colorReaction = true
    }

    function element_proto:PostUpdateColor(unit, r, g, b)
        if unit:match("^nameplate%d") then return end
        
        local element = self
        if (C.unitframes.monochrome) then
            local color = C.unitframes.color
            element:SetStatusBarColor(color.r, color.g, color.b)
            
            local bg = element.bg
            if (bg) then
                local mu = bg.multiplier or 1
                bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
            end
        end
    end

    function UnitFrames:CreateHealth(frame)
        local texture = C.unitframes.texture
        local fontObject = E.GetFont(C.unitframes.font)

        local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Health", frame), element_proto)
        element:SetStatusBarTexture(texture)
        element:SetFrameLevel(frame:GetFrameLevel() + 1)
        element:SetClipsChildren(true)
        element:SetPoint("TOP", frame, "TOP", 0, 0)
        element:SetPoint("LEFT", frame, "LEFT", 0, 0)
        element:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        element:SetPoint("BOTTOM", frame, "BOTTOM", 0, C.unitframes.power.height)
        element:SetClipsChildren(false)
        
        local bg = element:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(element)
        bg:SetTexture(texture)
        bg.multiplier = C.general.background.multiplier or 0.15
        element.bg = bg

        local tag = frame.__config.tags.health
        if (tag) then
            local value = element:CreateFontString(nil, "OVERLAY")
            value:SetPoint("RIGHT", element, "RIGHT", -5, 0)
            value:SetFontObject(fontObject)
            value:SetJustifyH("RIGHT")
            value:SetWordWrap(false)

            frame:Tag(value, tag)

            element.Value = value
        end
       
        -- options
        if (C.unitframes.monochrome) then
            element.colorDisconnected = false
            element.colorTapping = false
            element.colorClass = false
            element.colorReaction = false
        end

        if (frame.__unit == "nameplate") then
            element.colorDisconnected = true
            element.colorTapping = false
            element.colorClass = true
            element.colorReaction = true
            element.colorThreat = (frame.__unit == "nameplate")
            element.colorSelection = (frame.__unit == "nameplate")
        end

        return element
    end
end

--------------------------------------------------
-- Health Prediction
--------------------------------------------------
do
    local element_proto = {
        maxOverflow = 1
    }

    function UnitFrames:CreateHealthPrediction(frame)
        local parent = frame.Health
        local level = parent:GetFrameLevel()
        local width = frame.__config.width or 200
        local texture = C.unitframes.texture

        local myBar = CreateFrame("StatusBar", nil, parent)
        myBar:SetPoint("TOP")
        myBar:SetPoint("BOTTOM")
        myBar:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        myBar:SetWidth(width)
        myBar:SetStatusBarTexture(texture)
        do
            local color = C.unitframes.health.prediction.colors.self
            myBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 0.30)
        end

        local otherBar = CreateFrame("StatusBar", nil, parent)
        otherBar:SetPoint("TOP")
        otherBar:SetPoint("BOTTOM")
        otherBar:SetPoint("LEFT", myBar:GetStatusBarTexture(), "RIGHT")
        otherBar:SetWidth(width)
        otherBar:SetStatusBarTexture(texture)
        do
            local color = C.unitframes.health.prediction.colors.other
            otherBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 0.30)
        end

        local absorbBar = CreateFrame("StatusBar", nil, parent)
        absorbBar:SetPoint("TOP")
        absorbBar:SetPoint("BOTTOM")
        absorbBar:SetPoint("LEFT", otherBar:GetStatusBarTexture(), "RIGHT")
        absorbBar:SetWidth(width)
        absorbBar:SetStatusBarTexture(texture)
        do
            local color = C.unitframes.health.prediction.colors.absorb
            absorbBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 0.30)
        end

        local healAbsorbBar = CreateFrame("StatusBar", nil, parent)
        healAbsorbBar:SetPoint("TOP")
        healAbsorbBar:SetPoint("BOTTOM")
        healAbsorbBar:SetPoint("RIGHT", parent:GetStatusBarTexture())
        healAbsorbBar:SetWidth(width)
        healAbsorbBar:SetReverseFill(true)
        healAbsorbBar:SetStatusBarTexture(texture)
        do
            local color = C.unitframes.health.prediction.colors.healAbsorb
            healAbsorbBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 0.30)
        end

        -- local overAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
        -- overAbsorb:SetPoint("TOP")
        -- overAbsorb:SetPoint("BOTTOM")
        -- overAbsorb:SetPoint("LEFT", self.Health, "RIGHT")
        -- overAbsorb:SetWidth(10)

        -- local overHealAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
        -- overHealAbsorb:SetPoint("TOP")
        -- overHealAbsorb:SetPoint("BOTTOM")
        -- overHealAbsorb:SetPoint("RIGHT", self.Health, "LEFT")
        -- overHealAbsorb:SetWidth(10)

        return Mixin({
            myBar = myBar,
            otherBar = otherBar,
            absorbBar = absorbBar,
            healAbsorbBar = healAbsorbBar,
            overAbsorb = nil,
            overHealAbsorb = nil
        }, element_proto)
    end
end
