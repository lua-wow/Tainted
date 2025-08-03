local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Mine
local element_proto = {
    name = "MultiBarLeftButton",
	horizontal = false
}

do
    function element_proto:PostCreate()
        local element = self

        local frame = _G.MultiBarLeft
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

    function element_proto:UpdateAnchor()
        local element = self

        local margin = C.general.margin or 10
        local spacing = element.spacing or 5

        local anchor = UIParent
        if MODULE.ActionBar4 and  MODULE.ActionBar4:IsShown() then
            anchor = MODULE.ActionBar4
        end

        element:ClearAllPoints()
        if anchor == UIParent then
            element:SetPoint("RIGHT", UIParent, "RIGHT", -margin, -margin)
        elseif anchor then
            element:SetPoint("RIGHT", anchor, "LEFT", -spacing, 0)
        end
    end
end

function MODULE:CreateActionBar5()
	return self:CreateActionBar("ActionBar5", element_proto)
end
