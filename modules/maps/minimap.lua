local addon, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Blizzard
local UnitOnTaxi = _G.UnitOnTaxi
local TaxiRequestEarlyLanding = _G.TaxiRequestEarlyLanding
local VehicleExit = _G.VehicleExit
local CanExitVehicle = _G.CanExitVehicle
local C_Calendar = _G.C_Calendar

--------------------------------------------------
-- Minimap
--------------------------------------------------
-- flavor specific code lives in 'minimap_mainline.lua' and 'minimap_classic.lua',
-- which define 'MODULE:OnMouseClick' and 'MODULE:StyleBlizzard'.
if not C.maps.enabled then return end

local MODULE = E:CreateModule("Minimap")

-- LibDBIcon and similar libraries read this global to place their buttons
_G.GetMinimapShape = function()
    return "SQUARE"
end

do
    local button_proto = {}

    function button_proto:OnClick()
        if UnitOnTaxi("player") then
            TaxiRequestEarlyLanding();
        else
            VehicleExit();
        end
        self:Hide()
    end

    function button_proto:OnEvent(event, ...)
        if CanExitVehicle() then
            if (UnitOnTaxi("player")) then
                self.Text:SetText("|cffFF0000" .. TAXI_CANCEL .. "|r")
            else
                self.Text:SetText("|cffFF0000" .. BINDING_NAME_VEHICLEEXIT .. "|r")
            end
            self:Show()
        else
            self:Hide()
        end
    end

    function MODULE:AddTaxiRequestEarlyLandingButton()
        local Minimap = _G.Minimap
        local level = (self.DataText or Minimap):GetFrameLevel()

        local button = Mixin(CreateFrame("Button", addon .. "TaxiRequestEarlyLandingButton", Minimap), button_proto)
        button:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -3)
        button:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -3)
        button:SetHeight(20)
        button:SetFrameLevel(level + 3)
        button:SetFrameStrata("MEDIUM")
        button:SkinButton()
        button:RegisterForClicks("AnyUp")
        button:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
        button:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
        button:RegisterEvent("UNIT_ENTERED_VEHICLE")
        button:RegisterEvent("UNIT_EXITED_VEHICLE")
        button:RegisterEvent("VEHICLE_UPDATE")
        button:RegisterEvent("PLAYER_ENTERING_WORLD")
        -- button:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
        button:SetScript("OnClick", button.OnClick)
        button:SetScript("OnEvent", button.OnEvent)
        button:Hide()

        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetFontObject(E.GetFont(C.maps.font))
        button.Text = text

        return button
    end
end

do
    local invite_proto = {}

    function invite_proto:OnEvent()
        self:SetShown(C_Calendar.GetNumPendingInvites() > 0)
    end

    function invite_proto:OnClick()
        _G.ToggleCalendar()
    end

    function invite_proto:OnEnter()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(_G.GAMETIME_TOOLTIP_CALENDAR_INVITES)
        GameTooltip:Show()
    end

    function invite_proto:OnLeave()
        GameTooltip:Hide()
    end

    -- replaces the pending invites icon of the killed 'GameTimeFrame'
    function MODULE:CreateInviteIndicator()
        -- vanilla and tbc clients have no calendar
        if not (C_Calendar and C_Calendar.GetNumPendingInvites and _G.ToggleCalendar) then return end

        local Minimap = _G.Minimap

        local button = Mixin(CreateFrame("Button", nil, Minimap), invite_proto)
        button:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -3, 3)
        button:SetSize(14, 16)
        button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        button:RegisterForClicks("AnyUp")
        button:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
        button:RegisterEvent("PLAYER_ENTERING_WORLD")
        button:SetScript("OnEvent", button.OnEvent)
        button:SetScript("OnClick", button.OnClick)
        button:SetScript("OnEnter", button.OnEnter)
        button:SetScript("OnLeave", button.OnLeave)
        button:Hide()

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture([[Interface\Calendar\EventNotification]])
        icon:SetTexCoord(0.03125, 0.6484375, 0.03125, 0.8671875)
        button.Icon = icon

        return button
    end
end

function MODULE:Style()
    local MinimapCluster = _G.MinimapCluster
    -- the emptied cluster still sits over the minimap
    MinimapCluster:EnableMouse(false)

    local BorderTop = MinimapCluster.BorderTop
    if BorderTop then
        BorderTop:Hide()
    end

    local margin = C.general.margin or 10

    local Minimap = _G.Minimap
    Minimap:SetParent(E.PetHider)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPRIGHT", -margin, -margin)
    Minimap:SetMaskTexture(A.textures.blank)
    Minimap:CreateBackdrop()
    Minimap:SetMovable(false)
    Minimap:SetScript("OnMouseUp", self.OnMouseClick)

    local MinimapBackdrop = _G.MinimapBackdrop
    MinimapBackdrop:Hide()

    local MinimapCompassTexture = _G.MinimapCompassTexture
    MinimapCompassTexture:Hide()

    -- calendar
    local GameTimeFrame = _G.GameTimeFrame
    GameTimeFrame:Kill()

    -- clock
    local TimeManagerClockButton = _G.TimeManagerClockButton
    if TimeManagerClockButton then
        TimeManagerClockButton:Kill()
    end

    local ZoneTextButton = MinimapCluster.ZoneTextButton or _G.MinimapZoneTextButton
    if (ZoneTextButton) then
        ZoneTextButton:Hide()
    end

    if MinimapZoneText then
        MinimapZoneText:Hide()
    end

    if (self.StyleBlizzard) then
        self:StyleBlizzard()
    end

    if (self.PostStyle) then
        self:PostStyle()
    end
end

function MODULE:CreateZoneButton()
    -- display only: must not block clicks or the indicator icons under it
    local Zone = CreateFrame("Frame", addon .. "MinimapZone", Minimap)
    Zone:EnableMouse(false)
    Zone:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 3, -3)
    Zone:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -3, -3)
    Zone:SetHeight(20)
    Zone:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    Zone:CreateBackdrop()
    Zone:SetAlpha(0)
    Minimap.Zone = Zone

    local fontObject = E.GetFont(C.maps.font)

    local Text = Zone:CreateFontString(Zone:GetName() .. "Text", "OVERLAY")
    Text:SetAllPoints()
    Text:SetFontObject(fontObject)
    Text:SetJustifyH("CENTER")
    Text:SetJustifyV("MIDDLE")
    Text:SetWordWrap(false)
    Zone.Text = Text

    hooksecurefunc("Minimap_Update", function(self)
        local zonetext = GetMinimapZoneText()
        Text:SetText(zonetext)

        local pvpType, isSubZonePvP, factionName = C_PvP.GetZonePVPInfo()
        local pvpColor = E.colors.pvp[pvpType or "none"] or NORMAL_FONT_COLOR
        Text:SetTextColor(pvpColor.r, pvpColor.g, pvpColor.b)
    end)

    local Animation = Zone:CreateAnimationGroup()
    Animation:SetLooping("NONE")
    Animation:SetToFinalAlpha(true)

    local FadeIn = Animation:CreateAnimation("Alpha")
    FadeIn:SetFromAlpha(0)
    FadeIn:SetToAlpha(1)
    FadeIn:SetDuration(0.50)
    FadeIn:SetSmoothing("IN")

    Zone.Animation = Animation

    Minimap:HookScript("OnEnter", function(self)
        Animation:Stop()
        if not Animation:IsPlaying() then
            Animation:Play()
        end
    end)

    Minimap:HookScript("OnLeave", function(self)
        Animation:Stop()
        if not Animation:IsPlaying() then
            Animation:Play(true)
        end
    end)
end

function MODULE:CreateDataText()
    local parent = _G.Minimap
    local element = CreateFrame("Frame", "TaintedMinimapDataText", parent)
    element:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -3)
    element:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, -3)
    element:SetHeight(20)
    element:CreateBackdrop()

    self.DataText = element
end

function MODULE:Init()
    self:Style()
    self:CreateZoneButton()
    self:CreateDataText()
    self.InviteIndicator = self:CreateInviteIndicator()
    self.TaxiRequestEarlyLandingButton = self:AddTaxiRequestEarlyLandingButton()

    -- Blizzard's first update runs before Tainted loads
    Minimap_Update()
end
