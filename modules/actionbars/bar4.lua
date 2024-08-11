local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _horizontal = false
}

function bar_proto:UpdateAnchor()
    self:SetPoint("RIGHT", UIParent, "RIGHT", -10, -10)
end

function MODULE:CreateActionBar4()
    local element = self:CreateActionBar("ActionBar4", bar_proto)

    local frame = _G.MultiBarRight
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBarRightButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

	self.ActionBar4 = element
end
