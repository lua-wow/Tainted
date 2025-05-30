local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard

-- Mine
local element_proto = {
    enabled = C.actionbars.bar6,
    name = "MultiBar5Button",
	horizontal = false
}

do
    function element_proto:UpdateAnchor()
        local element = self

        local margin = C.general.margin or 10
        local spacing = element.spacing or 5

        local anchor = UIParent
        if MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
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
            -- frame:SetShown(true)
            -- frame:EnableMouse(false)
            frame:SetParent(element)
            frame.ignoreFramePositionManager = true
            frame.ignoreInLayout = true
        end
    end
end

function MODULE:CreateActionBar6()
	return self:CreateActionBar("ActionBar6", element_proto)
end
