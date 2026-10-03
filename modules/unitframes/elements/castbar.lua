local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

local issecretvalue = _G.issecretvalue

local element_proto = {
    timeToHold = 0.4,
    smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut,
}

-- Classic/Mists oUF only (duration is a number); retail oUF drives Time via Time.binding
function element_proto:CustomDelayText(duration)
    self.Time:SetFormattedText("%.1f |cffaf5050%s %.1f|r", self.channeling and duration or (self.max - duration), self.channeling and "- " or "+", self.delay)
end

function element_proto:CustomTimeText(duration)
    self.Time:SetFormattedText("%.1f / %.1f", self.channeling and duration or (self.max - duration), self.max)
end

function element_proto:UpdateStatusBarColor(color)
    local element = self
    element:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)

    local bg = element.bg
    if (bg) then
        local mu = bg.multiplier or 1
        bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
    end
end

-- retail oUF keeps casting/channeling/empowering state internal, so derive it from the API
function element_proto:UpdateColor(unit, notInterruptible)
    local element = self
    local colors = C.unitframes.castbar.colors

    local color = colors.casting
    local channel, _, _, _, _, _, _, _, isEmpowered = UnitChannelInfo(unit)
    if (channel) then
        color = isEmpowered and colors.empowering or colors.channeling
    end

    -- classic/mists oUF don't pass it, but still expose it on the element
    if (notInterruptible == nil) then
        notInterruptible = element.notInterruptible
    end

    if (not issecretvalue(notInterruptible) and notInterruptible) then
        color = colors.notInterruptible
    end

    element:UpdateStatusBarColor(color)
end

function element_proto:PostCastInterruptible(unit, _, notInterruptible)
    self:UpdateColor(unit, notInterruptible)
end

function element_proto:PostCastStart(unit, _, notInterruptible)
    self:UpdateColor(unit, notInterruptible)
    -- 	if C.NamePlates.ClassIcon and unit:find("nameplate") and self.Button and self.Button.Shadow then
    -- 		self.Button.Shadow:SetBackdropBorderColor(self:GetStatusBarColor())
    -- 	end
end

function UnitFrames:CreateCastbar(frame, parent)
    if not frame.__config.castbar then return end

    local owner = parent or frame.Power
    local mode = frame.__config.castbar.mode or "embedded"
    local height = frame.__config.castbar.height or frame.__config.height or 20
    local texture = A.textures.blank
    local fontObject = E.GetFont(C.unitframes.castbar.font)

    local element = Mixin(CreateFrame("StatusBar", frame:GetName() .. "Castbar", frame), element_proto)
    element:SetStatusBarTexture(texture)
    
    local iconOwner = nil
    if mode == "detached" then
        element:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -3)
        element:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -3)
        element:SetHeight(height)
        element:CreateBackdrop()

        iconOwner = element
    else
        element:SetAllPoints(owner)
        element:SetFrameLevel(owner:GetFrameLevel() + 6)

        iconOwner = frame
    end

    local bg = element:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    element.bg = bg
    
    if frame.__config.castbar.icon then
        local iconBG = CreateFrame("Frame", nil, element)
        iconBG:SetPoint("RIGHT", iconOwner, "LEFT", -3, 0)
        iconBG:SetSize(height, height)
        iconBG:CreateBackdrop()
        
        local icon = iconBG:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        icon:SetTexCoord(unpack(E.IconCoord))
    
        element.IconBG = iconBG
        element.Icon = icon
    end
    
    local spark = element:CreateTexture(nil, "OVERLAY")
    spark:SetPoint("CENTER", element:GetStatusBarTexture(), "RIGHT", 0, 0)
    spark:SetBlendMode("ADD")
    spark:SetSize(3, height)
    
    local time = element:CreateFontString(nil, "OVERLAY")
    time:SetPoint("RIGHT", element, "RIGHT", -5, 0)
    time:SetJustifyH("RIGHT")
    time:SetFontObject(fontObject)
    time:SetTextColor(C.unitframes.castbar.colors.text:GetRGB())
    
    local text = element:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", element, "LEFT", 5, 0)
    text:SetJustifyH("LEFT")
    text:SetFontObject(fontObject)
    text:SetTextColor(C.unitframes.castbar.colors.text:GetRGB())
    
    if (frame.__key == "player") and frame.__config.castbar.latency then
        local color = C.unitframes.castbar.colors.latency
        local safezone = element:CreateTexture(nil, "OVERLAY")
        safezone:SetTexture(texture)
        safezone:SetVertexColor(color.r, color.g, color.b, color.a or 1)
        element.SafeZone = safezone
    end
    
    element.bg = bg
    element.Spark = spark
    element.Time = time
    element.Text = text
    
    return element
end
    