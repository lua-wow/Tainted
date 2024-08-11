local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local bar_proto = {
    _visibility = "show"
}

function bar_proto:Update()
    self:UpdateAnchor()
    self:CreateBackground(self._num, self._size, self._spacing, self._horizontal)
    self:UpdateVisibility()
    self:UpdateButtonsPosition()
end

function bar_proto:UpdateAnchor()
    -- self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 10)
end

function bar_proto:CreateBackground(num, size, spacing, isHorizontal)
    local rows = 1
    local cols = num / 2

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

function bar_proto:UpdateButtonsPosition()
    local element = self

    local isHorizontal = element._horizontal
    local size = element._size
    local spacing = element._spacing

    for i, button in next, element._buttons do
        button:SetParent(button._parent or element)
        button:ClearAllPoints()
        button:SetSize(size, size)

        if i == 1 then
            button:SetPoint("TOPLEFT", self.Left, "TOPLEFT", spacing, -spacing)
		elseif i == 7 then
            button:SetPoint("TOPLEFT", self.Right, "TOPLEFT", spacing, -spacing)
        else
            local anchor = element._buttons[i - 1]
            if element._horizontal then
                button:SetPoint("LEFT", anchor, "RIGHT", spacing, 0)
            else
                button:SetPoint("TOP", anchor, "BOTTOM", 0, -1 * spacing)
            end
        end
    end
end

function MODULE:CreateActionBar2()
    local element = self:CreateActionBar("ActionBar2", bar_proto)

    local frame = _G.MultiBarBottomLeft
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["MultiBarBottomLeftButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

	self.ActionBar2 = element
end
