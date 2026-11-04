local _, ns = ...
local E = ns.E

-- Blizzard
local InCombatLockdown = _G.InCombatLockdown

--------------------------------------------------
-- Taxi
--------------------------------------------------
-- Taking a flight while shapeshifted fails and closes the map, and CancelShapeshiftForm is
-- secure-only. Cover each taxi button with a secure button that cancels the form first and
-- then clicks the original one.
if E.class ~= "DRUID" then return end

local TaxiFrame = _G.TaxiFrame

local function OnEnter(self)
    self.button:LockHighlight()
    _G.TaxiNodeOnButtonEnter(self.button)
end

local function OnLeave(self)
    self.button:UnlockHighlight()
    _G.TaxiNodeOnButtonLeave(self.button)
end

local overlays = {}

-- Blizzard shows/hides taxi buttons (distant nodes on hover), so mirror it on the overlays
local function UpdateVisibility()
    if InCombatLockdown() then return end
    for _, overlay in ipairs(overlays) do
        overlay:SetShown(overlay.button:IsShown())
    end
end

-- Blizzard creates and positions TaxiButton<N> in TaxiFrame_OnShow, which runs before this hook
TaxiFrame:HookScript("OnShow", function()
    if InCombatLockdown() then return end
    while _G["TaxiButton" .. (#overlays + 1)] do
        local name = "TaxiButton" .. (#overlays + 1)
        -- a protected child would make the taxi button protected, and Blizzard anchors it to a
        -- texture (InsetBg), which protected frames can't do, so parent to TaxiFrame instead
        local overlay = CreateFrame("Button", nil, TaxiFrame, "SecureActionButtonTemplate")
        overlay.button = _G[name]
        overlay:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
        overlay:SetAttribute("type", "macro")
        overlay:SetAttribute("macrotext", "/cancelform [form]\n/click " .. name)
        overlay:SetScript("OnEnter", OnEnter)
        overlay:SetScript("OnLeave", OnLeave)
        overlays[#overlays + 1] = overlay
    end

    -- for the same reason, copy each button's position relative to TaxiFrame
    local left, bottom = TaxiFrame:GetLeft(), TaxiFrame:GetBottom()
    for _, overlay in ipairs(overlays) do
        local button = overlay.button
        local x, y = button:GetCenter()
        overlay:ClearAllPoints()
        overlay:SetSize(button:GetSize())
        overlay:SetFrameLevel(button:GetFrameLevel() + 1)
        if x and left then
            overlay:SetPoint("CENTER", TaxiFrame, "BOTTOMLEFT", x - left, y - bottom)
        end
    end
    UpdateVisibility()
end)

hooksecurefunc("TaxiNodeOnButtonEnter", UpdateVisibility)
hooksecurefunc("DrawOneHopLines", UpdateVisibility)
