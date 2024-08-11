local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _visibility = "show"
}

function bar_proto:UpdateAnchor()
    local margin = 10
    local spacing = self._spacing
    local stanceBarSize = C.actionbars.stance.size + (2 * spacing)
    local xOffset = margin + stanceBarSize + spacing
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOffset, -10)
end

function MODULE:CreateActionBar3()
    local element = self:CreateActionBar("ActionBar3", bar_proto)

    local frame = _G.MultiBarBottomRight
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBarBottomRightButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

    -- hide action bar when in combat
    -- show action bar when is out of combat
    element:RegisterEvent("PLAYER_REGEN_ENABLED")
    element:RegisterEvent("PLAYER_REGEN_DISABLED")
    element:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
        elseif event == "PLAYER_REGEN_DISABLED" then
            UIFrameFadeOut(self, 0.5, self:GetAlpha(), 0)
        end
    end)

	self.ActionBar3 = element
end
