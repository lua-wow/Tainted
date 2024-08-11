local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _horizontal = false
}

function bar_proto:UpdateAnchor()
    self:SetPoint("RIGHT", MODULE.ActionBar4, "LEFT", -self._spacing, 0)
end

function MODULE:CreateActionBar5()
    local element = self:CreateActionBar("ActionBar5", bar_proto)

    local frame = _G.MultiBarLeft
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBarLeftButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

	self.ActionBar5 = element
end
