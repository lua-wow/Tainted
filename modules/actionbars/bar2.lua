local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local MULTI_BAR_BOTTOM_LEFT_NUM_BUTTONS   = _G.MULTI_BAR_BOTTOM_LEFT_NUM_BUTTONS or 12

-- Mine
local element_proto = {
    name = "MultiBarBottomLeftButton",
    num = MULTI_BAR_BOTTOM_LEFT_NUM_BUTTONS
}

do
    function element_proto:UpdateAnchor()
        local element = self
        element:ClearAllPoints()
        element:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 62)
    end

    function element_proto:PostCreate()
        local element = self

        local frame = _G.MultiBarBottomLeft
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

    function element_proto:CreateBackground()
        local element = self

		local num = element.num
		local size = element.size
		local spacing = element.spacing
		local horizontal = element.horizontal

		local rows = 1
		local cols = (num / 2)

        local left = CreateFrame("Frame", self:GetName() .. "Left", self) --, "SecureHandlerStateTemplate")
        left:SetPoint("RIGHT", MODULE.ActionBar1, "LEFT", -spacing, 0)
        left:SetWidth((cols * size) + ((cols + 1) * spacing))
        left:SetHeight((rows * size) + ((rows + 1) * spacing))
        left:SetFrameStrata("LOW")
        left:SetFrameLevel(self:GetFrameLevel())
        left:CreateBackdrop("transparent")
        self.Left = left
        
        local right = CreateFrame("Frame", self:GetName() .. "Right", self) --, "SecureHandlerStateTemplate")
        right:SetPoint("LEFT", MODULE.ActionBar1, "RIGHT", spacing, 0)
        right:SetWidth((cols * size) + ((cols + 1) * spacing))
        right:SetHeight((rows * size) + ((rows + 1) * spacing))
        right:SetFrameStrata("LOW")
        right:SetFrameLevel(self:GetFrameLevel())
        right:CreateBackdrop("transparent")
        self.Right = right
    end

    function element_proto:UpdateButtonPosition(button, index)
        local element = self

		local spacing = element.spacing or 5
		local horizontal = element.horizontal or false

        element:ClearAllPoints()
		if index == 1 then
			button:SetPoint("TOPLEFT", element.Left, "TOPLEFT", spacing, -spacing)
        elseif index == 7 then
			button:SetPoint("TOPLEFT", element.Right, "TOPLEFT", spacing, -spacing)
		else
			local previous = _G[element.name .. (index - 1)]
			if element.horizontal then
				button:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
			else
				button:SetPoint("TOP", previous, "BOTTOM", 0, -spacing)
			end
		end
	end
end

function MODULE:CreateActionBar2()
	return self:CreateActionBar("ActionBar2", element_proto)
end
