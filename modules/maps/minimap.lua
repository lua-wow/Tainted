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

        local button = Mixin(CreateFrame("Button", addon .. "TaxiRequestEarlyLandingButton", Minimap), button_proto)
        button:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -3)
        button:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -3)
        button:SetHeight(20)
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

function MODULE:OnMouseClick(button)
	if (button == "RightButton") then
        local button = _G.MinimapCluster.Tracking.Button
        if button then
            button:OpenMenu()
            if button.menu then
                button.menu:ClearAllPoints()
                button.menu:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -5, 0);
            end
        else
            ToggleDropDownMenu(1, nil, MinimapCluster.TrackingFrame.DropDown, MinimapCluster.TrackingFrame, 8, 5);
        end
	elseif (button == "MiddleButton") then
		local ExpansionLandingPageMinimapButton = _G.ExpansionLandingPageMinimapButton
		ExpansionLandingPageMinimapButton:ToggleLandingPage()
	else
        local Minimap = _G.Minimap
        Minimap:OnClick()
	end
end

function MODULE:Style()
    local MinimapCluster = _G.MinimapCluster
    
    local BorderTop = MinimapCluster.BorderTop
    BorderTop:Hide()

    local Tracking = MinimapCluster.Tracking
    if Tracking then
        MinimapCluster.Tracking:SetAlpha(0)
        MinimapCluster.Tracking:SetScale(0.001)
    end

    local MinimapContainer = MinimapCluster.MinimapContainer
    MinimapContainer:ClearAllPoints()
    MinimapContainer:SetAllPoints()

    local Minimap = MinimapContainer.Minimap
    Minimap:SetParent(E.PetHider)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPRIGHT", -10, -10)
    Minimap:SetMaskTexture(A.textures.blank)
    Minimap:CreateBackdrop()
    Minimap:SetMovable(false)
    Minimap:SetScript("OnMouseUp", self.OnMouseClick)
    
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
    ExpansionLandingPageMinimapButton:SetAlpha(0)

    -- calendar
    local GameTimeFrame = _G.GameTimeFrame
    GameTimeFrame:Kill()

    -- clock
    local TimeManagerClockButton = _G.TimeManagerClockButton
    TimeManagerClockButton:Kill()

    local ZoneTextButton = MinimapCluster.ZoneTextButton
    if (ZoneTextButton) then
        ZoneTextButton:SetParent(Minimap)
        ZoneTextButton:ClearAllPoints()
        ZoneTextButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 3, -3)
        ZoneTextButton:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -3, -3)
        ZoneTextButton:SetHeight(20)
        ZoneTextButton:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        ZoneTextButton:CreateBackdrop()
        ZoneTextButton:SetAlpha(0)

        local MinimapZoneText = ZoneTextButton.MinimapZoneText
        if MinimapZoneText then
            MinimapZoneText:ClearAllPoints()
            MinimapZoneText:SetPoint("CENTER", ZoneTextButton, "CENTER", 0, 0)
        end
    end

    local IndicatorFrame = MinimapCluster.IndicatorFrame
    if IndicatorFrame then
        IndicatorFrame:SetParent(Minimap)
        IndicatorFrame:ClearAllPoints()
        IndicatorFrame:SetPoint("TOPLEFT", 3, -3)
    end

    local InstanceDifficulty = MinimapCluster.InstanceDifficulty
    InstanceDifficulty:SetParent(Minimap)
    InstanceDifficulty:ClearAllPoints()
    InstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -1, -1)
    -- InstanceDifficulty:SetPoint("TOPRIGHT", ZoneTextButton, "BOTTOMRIGHT", 0, -1)

    if (self.PostStyle) then
        self:PostStyle()
    end
end

function MODULE:AddZoneTextAnimation()
    local MinimapCluster = _G.MinimapCluster
    local ZoneTextButton = MinimapCluster.ZoneTextButton
    if (ZoneTextButton) then
        local MinimapZoneText = ZoneTextButton.MinimapZoneText
        local InstanceDifficulty = MinimapCluster.InstanceDifficulty

        local Animation = ZoneTextButton:CreateAnimationGroup()
        Animation:SetLooping("NONE")
        Animation:SetToFinalAlpha(true)

        local FadeIn = Animation:CreateAnimation("Alpha")
        FadeIn:SetFromAlpha(0)
        FadeIn:SetToAlpha(1)
        FadeIn:SetDuration(0.50)
        FadeIn:SetSmoothing("IN")

        ZoneTextButton.Animation = Animation

        Minimap:HookScript("OnEnter", function(self)
            Animation:Stop()
            if not Animation:IsPlaying() then
                Animation:Play()
            end
        end)

        Minimap:HookScript("OnLeave", function(self)
            if not MouseIsOver(ZoneTextButton) then
                Animation:Stop()
                if not Animation:IsPlaying() then
                    Animation:Play(true)
                end
            end
        end)
    end
end

function MODULE:Init()
    self:Style()
    self:AddZoneTextAnimation()
    self.TaxiRequestEarlyLandingButton = self:AddTaxiRequestEarlyLandingButton()
end
