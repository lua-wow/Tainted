local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Mine
local element_proto = {
    name = "MultiBar7Button",
	horizontal = false
}

do
    function element_proto:UpdateAnchor()
        local element = self

        local margin = C.general.margin or 10
        local spacing = element.spacing or 5

        local anchor = UIParent
        if MODULE.ActionBar7 and MODULE.ActionBar7:IsShown() then
            anchor = MODULE.ActionBar7
        elseif MODULE.ActionBar6 and MODULE.ActionBar6:IsShown() then
            anchor = MODULE.ActionBar6
        elseif MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
            anchor = MODULE.ActionBar5
        elseif MODULE.ActionBar4 and MODULE.ActionBar4:IsShown() then
            anchor = MODULE.ActionBar4
        end

        element:ClearAllPoints()
        if anchor ~= UIParent then
            element:SetPoint("RIGHT", anchor, "LEFT", -spacing, 0)
        else
            element:SetPoint("RIGHT", anchor, "RIGHT", -margin, -margin)
        end
    end

    function element_proto:PostCreate()
        local element = self

        local frame = _G.MultiBar5
        if frame then
            frame:SetShown(true)
            frame:EnableMouse(false)
            frame:SetParent(element)
            frame.ignoreFramePositionManager = true
            frame.ignoreInLayout = true
        end
    end
end

function MODULE:CreateActionBar7()
	return self:CreateActionBar("ActionBar8", element_proto)
end
