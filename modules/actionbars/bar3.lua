local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local MULTI_BAR_BOTTOM_RIGHT_NUM_BUTTONS    = _G.MULTI_BAR_BOTTOM_RIGHT_NUM_BUTTONS  or 12

-- Mine
local element_proto = {
    name = "MultiBarBottomRightButton",
    num = MULTI_BAR_BOTTOM_RIGHT_NUM_BUTTONS
}

do
    function element_proto:UpdateAnchor()
        local element = self
        
        local margin = C.general.margin or 10
        local spacing = element.spacing or 5

        local stanceBarSize = C.actionbars.stance.size + (2 * spacing)
        local xOffset = margin + stanceBarSize + spacing

        element:ClearAllPoints()
        element:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOffset, -margin)
    end

    function element_proto:PostCreate()
        local element = self

        -- hide action bar when in combat
        -- show action bar when is out of combat
        element:RegisterEvent("PLAYER_REGEN_ENABLED")
        element:RegisterEvent("PLAYER_REGEN_DISABLED")
        element:SetScript("OnEvent", element.OnEvent)

        local frame = _G.MultiBarBottomRight
        if frame then
            if not E.isRetail then
                frame:SetShown(true)
                frame:EnableMouse(false)
            end
            frame:SetParent(element)
            frame.ignoreFramePositionManager = true
            frame.ignoreInLayout = true
        end
    end

    function element_proto:OnEvent(event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
        elseif event == "PLAYER_REGEN_DISABLED" then
            UIFrameFadeOut(self, 0.5, self:GetAlpha(), 0)
        end
    end
end

function MODULE:CreateActionBar3()
	return self:CreateActionBar("ActionBar3", element_proto)
end
