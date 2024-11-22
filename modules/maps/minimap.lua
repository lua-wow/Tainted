local addon, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Blizzard
local UnitOnTaxi = _G.UnitOnTaxi
local TaxiRequestEarlyLanding = _G.TaxiRequestEarlyLanding
local VehicleExit = _G.VehicleExit
local CanExitVehicle = _G.CanExitVehicle

--------------------------------------------------
-- Minimap
--------------------------------------------------
if not C.maps.enabled then return end

local MODULE = E:CreateModule("Minimap")

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

if E.isClassic then
    function MODULE:OnMouseClick(button)
        local Minimap = _G.Minimap
        Minimap_OnClick(Minimap)
    end
else
    function MODULE:OnMouseClick(button)
        local MinimapCluster = _G.MinimapCluster
        local ExpansionLandingPageMinimapButton = _G.ExpansionLandingPageMinimapButton
        if (button == "RightButton") then
            local button = MinimapCluster and MinimapCluster.Tracking and MinimapCluster.Tracking.Button
            if button then
                button:OpenMenu()
                if button.menu then
                    button.menu:ClearAllPoints()
                    button.menu:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -5, 0);
                end
            else
                ToggleDropDownMenu(1, nil, MinimapCluster.TrackingFrame.DropDown, MinimapCluster.TrackingFrame, 8, 5);
            end
        elseif (button == "MiddleButton" and ExpansionLandingPageMinimapButton) then
            ExpansionLandingPageMinimapButton:ToggleLandingPage()
        else
            local Minimap = _G.Minimap
            if Minimap.OnClick then
                Minimap:OnClick()
            else
                Minimap_OnClick(Minimap)
            end
        end
    end
end

function MODULE:Style()
    local MinimapCluster = _G.MinimapCluster
    
    local BorderTop = MinimapCluster.BorderTop or _G.MinimapBorderTop
    if BorderTop then
        BorderTop:Hide()
    end

    local ToggleButton = _G.MinimapToggleButton
    if ToggleButton then
        ToggleButton:Hide()
    end

    local Tracking = MinimapCluster.Tracking
    if Tracking then
        MinimapCluster.Tracking:SetAlpha(0)
        MinimapCluster.Tracking:SetScale(0.001)
    end

    local MinimapContainer = MinimapCluster.MinimapContainer
    if MinimapContainer then
        MinimapContainer:ClearAllPoints()
        MinimapContainer:SetAllPoints()
    end

    local margin = C.general.margin or 10

    local Minimap = MinimapContainer and MinimapContainer.Minimap or _G.Minimap
    Minimap:SetParent(E.PetHider)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPRIGHT", -margin, -margin)
    Minimap:SetMaskTexture(A.textures.blank)
    Minimap:CreateBackdrop()
    Minimap:SetMovable(false)
    Minimap:SetScript("OnMouseUp", self.OnMouseClick)

    if E.isClassic then
        Minimap:SetSize(180, 180)
    end
    
    local ZoomHitArea = Minimap.ZoomHitArea
    
    local ZoomIn = Minimap.ZoomIn
    if (ZoomIn) then
        Minimap.ZoomIn:Kill()
    end
    
    local ZoomOut = Minimap.ZoomOut
    if (ZoomOut) then
        Minimap.ZoomOut:Kill()
    end
            
    local MinimapBackdrop = _G.MinimapBackdrop
    MinimapBackdrop:Hide()

    local MinimapCompassTexture = _G.MinimapCompassTexture
    MinimapCompassTexture:Hide()

    local ExpansionLandingPageMinimapButton = _G.ExpansionLandingPageMinimapButton
    if ExpansionLandingPageMinimapButton then
        ExpansionLandingPageMinimapButton:SetAlpha(0)
    end

    -- calendar
    local GameTimeFrame = _G.GameTimeFrame
    GameTimeFrame:Kill()

    -- clock
    local TimeManagerClockButton = _G.TimeManagerClockButton
    TimeManagerClockButton:Kill()

    local ZoneTextButton = MinimapCluster.ZoneTextButton or _G.MinimapZoneTextButton
    if (ZoneTextButton) then
        ZoneTextButton:Hide()
    end

    if MinimapZoneText then
        MinimapZoneText:Hide()
    end

    local IndicatorFrame = MinimapCluster.IndicatorFrame
    if IndicatorFrame then
        IndicatorFrame:SetParent(Minimap)
        IndicatorFrame:ClearAllPoints()
        IndicatorFrame:SetPoint("TOPLEFT", 3, -3)
    end

    local InstanceDifficulty = MinimapCluster.InstanceDifficulty
    if InstanceDifficulty then
        InstanceDifficulty:SetParent(Minimap)
        InstanceDifficulty:ClearAllPoints()
        InstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -1, -1)
    end

    if (self.PostStyle) then
        self:PostStyle()
    end
end

function MODULE:CreateZoneButton()
    local Zone = CreateFrame("Button", "TukuiMinimapZone", Minimap)
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
        if not MouseIsOver(Zone) then
            Animation:Stop()
            if not Animation:IsPlaying() then
                Animation:Play(true)
            end
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
    self.TaxiRequestEarlyLandingButton = self:AddTaxiRequestEarlyLandingButton()

    if E.isClassic then
        Minimap_Update()
    end
end
