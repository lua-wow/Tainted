local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _enabled = C.actionbars.bar6,
    _horizontal = false
}

function bar_proto:UpdateAnchor()
    local anchor = UIParent
    if MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
        anchor = MODULE.ActionBar5
    elseif MODULE.ActionBar4 and MODULE.ActionBar4:IsShown() then
        anchor = MODULE.ActionBar4
    end

    if anchor ~= UIParent then
        self:SetPoint("RIGHT", anchor, "LEFT", -self._spacing, 0)
    else
        self:SetPoint("RIGHT", anchor, "RIGHT", -10, 10)
    end
end

function MODULE:CreateActionBar6()
    if not _G.MultiBar5 then return end

    local element = self:CreateActionBar("ActionBar6", bar_proto)

    local frame = _G.MultiBar5
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBar5Button" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

	self.ActionBar6 = element
end
