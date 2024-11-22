local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Mine
local element_proto = {
    name = "MultiBarRightButton",
    horizontal = false
}

do
    function element_proto:PostCreate()
        local element = self

        local frame = _G.MultiBarRight
        if frame then
            frame:SetShown(true)
            frame:EnableMouse(false)
            frame:SetParent(element)
            frame.ignoreFramePositionManager = true
            frame.ignoreInLayout = true
        end
    end

    function element_proto:UpdateAnchor()
        local element = self

        local margin = C.general.margin or 10

        element:ClearAllPoints()
        element:SetPoint("RIGHT", UIParent, "RIGHT", -margin, -margin)
    end
end

function MODULE:CreateActionBar4()
	return self:CreateActionBar("ActionBar4", element_proto)
end
