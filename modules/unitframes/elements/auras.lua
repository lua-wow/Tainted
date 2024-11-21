local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

local LibDispel = LibStub("LibDispel")
assert(LibDispel, "Filger requires LibDispel")

-- Blizzard
local UnitIsFriend = _G.UnitIsFriend
local UnitIsEnemy = _G.UnitIsEnemy

--------------------------------------------------
-- Auras
--------------------------------------------------
local button_proto = {}

function button_proto:UpdateTooltip()
    if (GameTooltip:IsForbidden()) then return end

    local unit = self:GetParent().__owner.unit
	if self.auraIndex then
		GameTooltip:SetUnitAura(unit, self.auraIndex, self.isHarmful and "HARMFUL" or "HELPFUL")
	elseif self.isHarmful then
		GameTooltip:SetUnitDebuffByAuraInstanceID(unit, self.auraInstanceID)
	else
		GameTooltip:SetUnitBuffByAuraInstanceID(unit, self.auraInstanceID)
	end
end

function button_proto:OnEnter()
    if (GameTooltip:IsForbidden() or not self:IsVisible()) then return end

    -- Avoid parenting GameTooltip to frames with anchoring restrictions,
    -- otherwise it'll inherit said restrictions which will cause issues with
    -- its further positioning, clamping, etc
    GameTooltip:SetOwner(self, self:GetParent().__restricted and 'ANCHOR_CURSOR' or self:GetParent().tooltipAnchor)
    self:UpdateTooltip()
end

function button_proto:OnLeave()
    if (GameTooltip:IsForbidden()) then return end
    GameTooltip:Hide()
end

local aura_proto = {}

function aura_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed

    if (self.elapsed >= 0.1) then
        local remainingTime = (self.expirationTime or 0) - GetTime()

        if (remainingTime > 0) then
            self.Timer:SetText(E.FormatTime(remainingTime))
            if (remainingTime <= 5) then
                self.Timer:SetTextColor(0.99, 0.31, 0.31)
            else
                self.Timer:SetTextColor(1, 1, 1)
            end
        else
            self.Timer:Hide()
        end

        self.elapsed = 0
    end
end

function aura_proto:CreateButton(index)
    local element = self

    local font = A.fonts.normal

    local button = Mixin(CreateFrame("Button", element:GetDebugName() .. "Button" .. index, element), button_proto)
    button:CreateBackdrop()

    button:SetScript("OnEnter", button.OnEnter)
    button:SetScript("OnLeave", button.OnLeave)

    local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetReverse(true)
    cd:SetHideCountdownNumbers(true)
    cd.noOCC = true
    cd.noCooldownCount = true
    button.Cooldown = cd

    local timer = cd:CreateFontString(nil, "OVERLAY", nil, 7)
    timer:SetFont(font, 12, "THINOUTLINE")
    timer:SetPoint("CENTER", 0, 0)
    button.Timer = timer

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(unpack(E.IconCoord))
    button.Icon = icon

    local countFrame = CreateFrame("Frame", nil, button)
    countFrame:SetAllPoints(button)
    countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

    local count = countFrame:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 1)
    count:SetFont(font, 9, "THINOUTLINE")
    button.Count = count

    do
        local animation = button:CreateAnimationGroup()
        animation:SetLooping("BOUNCE")

        local fadeout = animation:CreateAnimation("Alpha")
        fadeout:SetFromAlpha(1)
        fadeout:SetToAlpha(0.20)
        fadeout:SetDuration(0.60)
        fadeout:SetSmoothing("IN_OUT")

        button.Animation = animation
        button.Animation.FadeOut = fadeout
    end

    if (element.PostCreateButton) then element:PostCreateButton(button) end

    return button
end

function aura_proto:PostUpdateButton(button, unit, data, position)
    local duration = data.duration or 0
    button.duration = duration
    button.expirationTime = data.expirationTime

    local timer = button.Timer
    if (timer) then
        local size = button:GetSize()
        if (duration and duration > 0 and size > 20) then
            timer:Show()
            button:SetScript("OnUpdate", self.OnUpdate)
        else
            timer:Hide()
            button:SetScript("OnUpdate", nil)
        end
    end

    if button.Backdrop then
        if (data.isHarmful and UnitCanAssist(unit, "player")) or (data.isHelpful and UnitCanAttack(unit, "player") and UnitCanAttack("player", unit)) then
            local mu = 0.8
            local color = E.colors.debuff[data.dispelName or "none"]
            button.Backdrop:SetBackdropBorderColor(color.r * mu, color.g * mu, color.b * mu, color.a or 1)
        else
            local color = C.general.border.color
            button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
        end
    end

    if button.Icon then
        button.Icon:SetDesaturated(data.isHarmful and (not data.isPlayerAura) and not UnitIsUnit(unit, "player"))
    end

    if (button.Animation) then
        if data.isDispelable or data.isStealable then
            if not button.Animation:IsPlaying() then
                button.Animation:Play()
            end
        else
            if button.Animation:IsPlaying() then
                button.Animation:Stop()
            end
        end
    end
end

function aura_proto:PostProcessAuraData(unit, data)
    data.isDispelable = LibDispel:IsDispelable(unit, data.spellId, data.dispelName, data.isHarmful)
    return data
end

--------------------------------------------------
-- Buffs
--------------------------------------------------
do
    local element_proto = Mixin({
        showStealableBuffs = true,
        onlyShowPlayer = false,
        size = 27,
        spacing = 3,
        initialAnchor = "BOTTOMLEFT",
        ["growth-x"] = "RIGHT",
        ["growth-y"] = "UP"
    }, aura_proto)

    function UnitFrames:CreateBuffs(frame)
        local width = frame.__config.width or 252
        local size = C.unitframes.auras.size or 27
        local spacing = C.unitframes.auras.spacing or 3

        local isCompact = (frame.__unit ~= "player" and frame.__unit ~= "target" and frame.__unit ~= "nameplate")

        if isCompact then
            size = math.max(size - 4, 20)
            width = math.floor(width / 2)
        end

        -- calculate aura size
        local num = E.CalcSegmentsNumber(width, size, spacing)

        local element = Mixin(CreateFrame("Frame", frame:GetName() .. "Buffs", frame), element_proto)
        element:SetSize(width, size)

        if isCompact then
            element:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 3)
        else
            element:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 8)
        end

        -- options
        element.num = num or 5
        element.size = size
        element.spacing = spacing
        element.onlyShowPlayer = frame.__config.buffs and frame.__config.buffs.selfBuffs or false
        element.showStealableBuffs = (frame.unit ~= "player")

        return element
    end
end

--------------------------------------------------
-- Debuffs
--------------------------------------------------
do
    local element_proto = Mixin({
        showStealableBuffs = nil,
        onlyShowPlayer = false,
        size = 27,
        spacing = 3,
        initialAnchor = "TOPRIGHT",
        ["growth-x"] = "LEFT",
        ["growth-y"] = "UP"
    }, aura_proto)

    function UnitFrames:CreateDebuffs(frame)
        local width = frame.__config.width or 252
        local size = C.unitframes.auras.size or 27
        local spacing = C.unitframes.auras.spacing or 3

        local isCompact = (frame.__unit ~= "player" and frame.__unit ~= "target" and frame.__unit ~= "nameplate")

        if isCompact then
            size = math.max(size - 4, 20)
            width = math.floor(width / 2)
        end

        -- calculate aura size
        local num = E.CalcSegmentsNumber(width, size, spacing)

        local element = Mixin(CreateFrame("Frame", frame:GetName() .. "Debuffs", frame), element_proto)
        element:SetSize(width, size)

        if isCompact then
            element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 3)
        elseif (frame.__unit == "nameplate") then
            element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 5)
        else
            if (frame.Buffs) then
                element:SetPoint("BOTTOMLEFT", frame.Buffs, "TOPLEFT", 0, 3)
            else
                element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 3)
            end
        end

        -- options
        element.num = num
        element.size = size
        element.spacing = spacing
        element.onlyShowPlayer = (frame.__unit == "nameplate")

        return element
    end
end
