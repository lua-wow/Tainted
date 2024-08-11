local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _enabled = C.actionbars.bar7,
    _horizontal = false
}

function bar_proto:UpdateAnchor()
    local anchor = UIParent
    if MODULE.ActionBar6 and MODULE.ActionBar6:IsShown() then
        anchor = MODULE.ActionBar6
    elseif MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
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

function MODULE:CreateActionBar7()
    if not _G.MultiBar6 then return end

    local element = self:CreateActionBar("ActionBar7", bar_proto)

    local frame = _G.MultiBar6
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBar6Button" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

	self.ActionBar7 = element
end
