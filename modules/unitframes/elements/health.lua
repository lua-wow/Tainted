local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Health
--------------------------------------------------
do
    local element_proto = {
        colorDisconnected = true,
        colorTapping = E.isClassic,
        colorClass = true,
        colorReaction = true
    }

    function element_proto:SetColor(color)
        local element = self
        element:SetStatusBarColor(color.r, color.g, color.b)
        
        local bg = element.bg
        if (bg) then
            local mu = bg.multiplier or 1
            bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
        end
    end

    function element_proto:SetMonochromeColor()
        self:SetColor(C.unitframes.color)
    end

    function element_proto:SetTargetColor()
        local color = E:CreateColor(0.40, 0.20, 0.80)
        self:SetColor(color)
    end

    function element_proto:PostUpdateColor(unit, color)
        -- nameplates should not be monochrome
        if unit:match("^nameplate%d") then return end
        if C.unitframes.monochrome then
            self:SetMonochromeColor()
        end
    end

    function UnitFrames:CreateHealth(frame, textParent)
        local ref = textParent or element
        local texture = C.unitframes.texture
        local fontObject = E.GetFont(C.unitframes.font)

        local temploss = CreateFrame("StatusBar", nil, frame)
        temploss:SetPoint("TOP", frame, "TOP", 0, 0)
        temploss:SetPoint("LEFT", frame, "LEFT", 0, 0)
        temploss:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        temploss:SetPoint("BOTTOM", frame, "BOTTOM", 0, C.unitframes.power.height)
        temploss:SetReverseFill(true)
        temploss:SetMinMaxValues(0, 1)
        temploss:SetClipsChildren(true)
        temploss:SetFrameLevel(frame:GetFrameLevel() + 1)
        temploss:SetStatusBarTexture(texture)

        temploss._texture = temploss:GetStatusBarTexture()
        temploss._texture:SetTexture(C.unitframes.health.temploss.texture, "REPEAT", "REPEAT")
        temploss._texture:SetHorizTile(true)
        temploss._texture:SetVertTile(true)

        local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Health", frame), element_proto)
        element:SetStatusBarTexture(texture)
        element:SetFrameLevel(frame:GetFrameLevel() + 1)
        element:SetPoint("LEFT", frame, "LEFT", 0, 0)
        element:SetPoint("TOPRIGHT", temploss._texture, "TOPLEFT", 0, 0)
        element:SetPoint("BOTTOMRIGHT", temploss._texture, "BOTTOMLEFT", 0, 0)
        element:SetClipsChildren(false)
        
        element.TempLoss = temploss
        
        -- local bg = element:CreateTexture(nil, "BACKGROUND")
        -- bg:SetAllPoints(element)
        -- bg:SetTexture(texture)
        -- bg.multiplier = C.general.background.multiplier or 0.15
        -- element.bg = bg

        local tag = frame.__config.tags.health
        if (tag) then
            local value = ref:CreateFontString(nil, "OVERLAY")
            value:SetPoint("RIGHT", ref, "RIGHT", -5, 0)
            value:SetFontObject(fontObject)
            value:SetJustifyH("RIGHT")
            value:SetWordWrap(false)

            frame:Tag(value, tag)

            element.Value = value
        end
       
        -- options
        if C.unitframes.monochrome then
            element.colorDisconnected = false
            element.colorTapping = false
            element.colorClass = false
            element.colorReaction = false
        end

        self:CreateHealthPrediction(element, frame.__config.width or 200)

        return element
    end
end

--------------------------------------------------
-- Health Prediction
--------------------------------------------------
do
    function UnitFrames:CreateHealthPrediction(parent, width)
        local level = parent:GetFrameLevel()
        local texture = C.unitframes.texture

        local healingColor = C.unitframes.health.prediction.colors.healing
        local absorbColor = C.unitframes.health.prediction.colors.absorb

        local HealingAll = CreateFrame("StatusBar", nil, parent)
        HealingAll:SetPoint("TOP")
        HealingAll:SetPoint("BOTTOM")
        HealingAll:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        -- HealingAll:SetWidth(width)
        HealingAll:SetStatusBarTexture(texture)
        HealingAll:SetStatusBarColor(healingColor:GetRGBA())
        parent.HealingAll = HealingAll
        
        local HealingPlayer = CreateFrame("StatusBar", nil, parent)
        HealingPlayer:SetPoint("TOP")
        HealingPlayer:SetPoint("BOTTOM")
        HealingPlayer:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        HealingPlayer:SetWidth(width)
        HealingPlayer:SetStatusBarTexture(texture)
        HealingPlayer:SetStatusBarColor(healingColor:GetRGBA())
        parent.HealingPlayer = HealingPlayer
        
        local HealingOther = CreateFrame("StatusBar", nil, parent)
        HealingOther:SetPoint("TOP")
        HealingOther:SetPoint("BOTTOM")
        HealingOther:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        HealingOther:SetWidth(width)
        HealingOther:SetStatusBarTexture(texture)
        HealingOther:SetStatusBarColor(healingColor:GetRGBA())
        parent.HealingOther = HealingOther
        
        local OverHealIndicator = CreateFrame("StatusBar", nil, parent)
        OverHealIndicator:SetPoint("TOP")
        OverHealIndicator:SetPoint("BOTTOM")
        OverHealIndicator:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        OverHealIndicator:SetWidth(width)
        OverHealIndicator:SetStatusBarTexture(texture)
        OverHealIndicator:SetStatusBarColor(healingColor:GetRGBA())
        parent.OverHealIndicator = OverHealIndicator
        
        local DamageAbsorb = CreateFrame("StatusBar", nil, parent)
        DamageAbsorb:SetPoint("TOP")
        DamageAbsorb:SetPoint("BOTTOM")
        DamageAbsorb:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        DamageAbsorb:SetWidth(width)
        DamageAbsorb:SetStatusBarTexture(texture)
        DamageAbsorb:SetStatusBarColor(absorbColor:GetRGBA())
        parent.DamageAbsorb = DamageAbsorb
        
        local OverDamageAbsorbIndicator = CreateFrame("StatusBar", nil, parent)
        OverDamageAbsorbIndicator:SetPoint("TOP")
        OverDamageAbsorbIndicator:SetPoint("BOTTOM")
        OverDamageAbsorbIndicator:SetPoint("LEFT", parent:GetStatusBarTexture(), "RIGHT")
        OverDamageAbsorbIndicator:SetWidth(5)
        OverDamageAbsorbIndicator:SetStatusBarTexture(texture)
        OverDamageAbsorbIndicator:SetStatusBarColor(absorbColor:GetRGBA())
        parent.OverDamageAbsorbIndicator = OverDamageAbsorbIndicator
        
        local HealAbsorb = CreateFrame("StatusBar", nil, parent)
        HealAbsorb:SetPoint("TOP")
        HealAbsorb:SetPoint("BOTTOM")
        HealAbsorb:SetPoint("LEFT", parent:GetStatusBarTexture())
        HealAbsorb:SetWidth(width)
        HealAbsorb:SetStatusBarTexture(texture)
        HealAbsorb:SetStatusBarColor(absorbColor:GetRGBA())
        parent.HealAbsorb = HealAbsorb
        
        local OverHealAbsorbIndicator = CreateFrame("StatusBar", nil, parent)
        OverHealAbsorbIndicator:SetPoint("TOP")
        OverHealAbsorbIndicator:SetPoint("BOTTOM")
        OverHealAbsorbIndicator:SetPoint("RIGHT", parent:GetStatusBarTexture(), "LEFT")
        OverHealAbsorbIndicator:SetWidth(5)
        OverHealAbsorbIndicator:SetStatusBarTexture(texture)
        OverHealAbsorbIndicator:SetStatusBarColor(absorbColor:GetRGBA())
        parent.OverHealAbsorbIndicator = OverHealAbsorbIndicator

        parent.HealingAll = HealingAll               
        parent.HealingPlayer = HealingPlayer            
        parent.HealingOther = HealingOther             
        parent.OverHealIndicator = OverHealIndicator        
        parent.DamageAbsorb = DamageAbsorb             
        parent.OverDamageAbsorbIndicator = OverDamageAbsorbIndicator
        parent.HealAbsorb = HealAbsorb               
        parent.OverHealAbsorbIndicator = OverHealAbsorbIndicator
    end
end
