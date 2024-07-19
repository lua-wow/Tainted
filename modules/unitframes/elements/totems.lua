local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

-- Blizzard
local GetTotemInfo = _G.GetTotemInfo
local GetSpellInfo = _G.GetSpellInfo

--------------------------------------------------
-- Totems
--------------------------------------------------
local MAX_TOTEMS = _G.MAX_TOTEMS or 4
local FIRE_TOTEM_SLOT = _G.FIRE_TOTEM_SLOT or 1;
local EARTH_TOTEM_SLOT = _G.EARTH_TOTEM_SLOT or 2;
local WATER_TOTEM_SLOT = _G.WATER_TOTEM_SLOT or 3;
local AIR_TOTEM_SLOT = _G.AIR_TOTEM_SLOT or 4;

-- STANDARD_TOTEM_PRIORITIES = {1, 2, 3, 4};
-- SHAMAN_TOTEM_PRIORITIES = { EARTH_TOTEM_SLOT, FIRE_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT };

local element_proto = {}

function element_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if (self.elapsed >= 0.1) then
        local remaining = self.expirationTime - GetTime()
        if (remaining >= 0) then
            self:SetValue(remaining)
            if self.Timer then
                self.Timer:SetText(E.FormatTime(remaining))
                if (remaining <= 5) then
                    self.Timer:SetTextColor(0.99, 0.31, 0.31)
                else
                    self.Timer:SetTextColor(1, 1, 1)
                end
            end
        else
            self:SetValue(0)
            if self.Timer then
                self.Timer:SetText("")
            end
        end
        self.elapsed = 0
    end
end

function element_proto:Override(event, slot)
    local element = self.Totems
    if (slot > #element) then return end

    local totem = element[slot]
    local haveTotem, name, start, duration, icon = GetTotemInfo(slot)
    local spellID = select(7, GetSpellInfo(name))
    if (haveTotem and duration and duration > 0) then
        totem.slot = slot
        totem.start = start or 0
        totem.duration = duration
        totem.expirationTime = start + duration
        totem.spellID = spellID

        if (totem:IsObjectType("StatusBar")) then
            totem:SetMinMaxValues(0, duration)
            totem:SetValue(duration)
            totem:SetScript("OnUpdate", element.OnUpdate)

            
        else
            if (totem.Icon) then
                totem.Icon:SetTexture(icon)
            end
    
            if (totem.Cooldown) then
                totem.Cooldown:SetCooldown(start, duration)
            end
        end

        totem:Show()
    else
        if (totem.SetValue) then
            totem:SetScript("OnUpdate", nil)
        end

        totem:Hide()
    end
end

function UnitFrames:CreateTotems(frame)
    local texture = C.unitframes.texture
    local fontObject = E.GetFont(C.unitframes.font)
    local width = C.unitframes.classpower.width or 200
    local height = C.unitframes.classpower.height or 18

    local element = Mixin(CreateFrame("Frame", frame:GetName() .. "TotemBar", frame), element_proto)
    element:SetSize(width, height)

    if (frame.__class == "SHAMAN") then
        element:SetPoint(unpack(C.unitframes.classpower.anchor))
    else
        element:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -1, -3)
    end

    local spacing = 3
    local sizes = E.CalcSegmentsSizes(MAX_TOTEMS, width, spacing)
    
    for i = 1, MAX_TOTEMS do
        if (C.unitframes.totems.icon) then
            local size = C.unitframes.totems.size

            local totem = CreateFrame("Button", element:GetName() .. i, element)
            totem:SetSize(size, size)

            local icon = totem:CreateTexture(nil, "OVERLAY")
            icon:SetInside()
            icon:SetAlpha(1)
            icon:SetTexCoord(unpack(E.IconCoord))
            totem.Icon = icon

            local cooldown = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate")
            cooldown:SetInside()
            cooldown:SetFrameLevel(totem:GetFrameLevel())
            totem.Cooldown = cooldown

            element[i] = totem
        else
            local size = sizes[i]
            local color = E.colors.totems[i]

            local totem = CreateFrame("StatusBar", element:GetName() .. i, element)
            totem:SetSize(size, height)
            totem:SetStatusBarTexture(texture)
            totem:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
            totem:SetMinMaxValues(0, 1)
            totem:SetValue(0)
            totem:CreateBackdrop()

            local multiplier = C.general.background.multiplier or 0.15
            local bg = totem:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(totem)
            bg:SetTexture(texture)
            bg:SetVertexColor(color.r * multiplier, color.g * multiplier, color.b * multiplier, color.a or 1)
            totem.bg = bg

            local timer = totem:CreateFontString(nil, "OVERLAY", nil, 7)
            timer:SetFontObject(fontObject)
            timer:SetPoint("CENTER", 0, 0)
            totem.Timer = timer

            element[i] = totem
        end
        
        if (i == 1) then
            element[i]:SetPoint("TOPLEFT", element, "TOPLEFT", E.Scale(1), -E.Scale(1))
        else
            element[i]:SetPoint("LEFT", element[i - 1], "RIGHT", E.Scale(spacing), 0)
        end
    end

    return element
end
