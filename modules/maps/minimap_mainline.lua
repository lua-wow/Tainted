local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

--------------------------------------------------
-- Minimap (Retail and Classic Forever)
--------------------------------------------------
-- both clients run Blizzard's mainline minimap code
if not C.maps.enabled then return end
if not (E.isRetail or E.isForever) then return end

local MODULE = E:GetModule("Minimap")

function MODULE:OnMouseClick(button)
    local Minimap = _G.Minimap
    local MinimapCluster = _G.MinimapCluster
    local ExpansionLandingPageMinimapButton = _G.ExpansionLandingPageMinimapButton
    if (button == "RightButton") then
        local TrackingButton = MinimapCluster.Tracking and MinimapCluster.Tracking.Button
        if TrackingButton then
            TrackingButton:OpenMenu()
            if TrackingButton.menu then
                TrackingButton.menu:ClearAllPoints()
                TrackingButton.menu:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -5, 0)
            end
        end
    elseif (button == "MiddleButton" and ExpansionLandingPageMinimapButton and ExpansionLandingPageMinimapButton:IsShown()) then
        ExpansionLandingPageMinimapButton:ToggleLandingPage()
    else
        Minimap:OnClick()
    end
end

-- Blizzard re-anchors these to the cluster header on layout changes
function MODULE:UpdateIndicatorsPosition()
    local Minimap = _G.Minimap
    local MinimapCluster = _G.MinimapCluster

    local IndicatorFrame = MinimapCluster.IndicatorFrame
    if IndicatorFrame then
        IndicatorFrame:ClearAllPoints()
        IndicatorFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 3, -3)
    end

    local InstanceDifficulty = MinimapCluster.InstanceDifficulty
    if InstanceDifficulty then
        InstanceDifficulty:ClearAllPoints()
        InstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -1, -1)
    end
end

function MODULE:StyleHybridMinimap()
    local HybridMinimap = _G.HybridMinimap
    if HybridMinimap and HybridMinimap.CircleMask then
        HybridMinimap.CircleMask:SetTexture(A.textures.blank)
    end
end

function MODULE:StyleBlizzard()
    local Minimap = _G.Minimap
    local MinimapCluster = _G.MinimapCluster

    local ZoomIn = Minimap.ZoomIn
    if (ZoomIn) then
        ZoomIn:Kill()
    end

    local ZoomOut = Minimap.ZoomOut
    if (ZoomOut) then
        ZoomOut:Kill()
    end

    -- the tracking menu is anchored to its button, so keep it shown but invisible
    local Tracking = MinimapCluster.Tracking
    if Tracking then
        Tracking:SetAlpha(0)
        if Tracking.Button then
            Tracking.Button:EnableMouse(false)
        end
    end

    -- was anchored to the killed 'GameTimeFrame'
    local AddonCompartmentFrame = _G.AddonCompartmentFrame
    if AddonCompartmentFrame then
        AddonCompartmentFrame:SetParent(E.Hider)
    end

    local ExpansionLandingPageMinimapButton = _G.ExpansionLandingPageMinimapButton
    if ExpansionLandingPageMinimapButton then
        ExpansionLandingPageMinimapButton:SetAlpha(0)
    end

    local IndicatorFrame = MinimapCluster.IndicatorFrame
    if IndicatorFrame then
        IndicatorFrame:SetParent(Minimap)
    end

    local InstanceDifficulty = MinimapCluster.InstanceDifficulty
    if InstanceDifficulty then
        InstanceDifficulty:SetParent(Minimap)
    end

    self:UpdateIndicatorsPosition()

    local function UpdateIndicatorsPosition()
        self:UpdateIndicatorsPosition()
    end

    hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", UpdateIndicatorsPosition)
    hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", UpdateIndicatorsPosition)

    -- hybrid minimap is load-on-demand and has its own round mask
    if C_AddOns.IsAddOnLoaded("Blizzard_HybridMinimap") then
        self:StyleHybridMinimap()
    else
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", function(f, event, name)
            if (name == "Blizzard_HybridMinimap") then
                self:StyleHybridMinimap()
                f:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end
