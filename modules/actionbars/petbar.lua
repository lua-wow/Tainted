local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local NUM_PET_ACTION_SLOTS = _G.NUM_PET_ACTION_SLOTS or 10

-- Mine
local StyleActionButton = MODULE.StyleActionButton

local element_proto = {
	name = "PetActionButton",
	num = NUM_PET_ACTION_SLOTS,
	size = C.actionbars.pet.size,
	spacing = C.actionbars.pet.spacing,
	horizontal = false,
	-- visibility = "[@pet,exists,nopossessbar] show; hide"
	visibility = "[@pet,exists,nopetbattle,nooverridebar,nopossessbar] show; hide"
}

do
	function element_proto:UpdateAnchor()
		local element = self

		local margin = 10
		local spacing = element.spacing or 5

		local anchor = UIParent
		if MODULE.ActionBar8 and MODULE.ActionBar8:IsShown() then
			anchor = MODULE.ActionBar8
		elseif MODULE.ActionBar7 and MODULE.ActionBar7:IsShown() then
			anchor = MODULE.ActionBar7
		elseif MODULE.ActionBar6 and MODULE.ActionBar6:IsShown() then
			anchor = MODULE.ActionBar6
		elseif MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
			anchor = MODULE.ActionBar5
		elseif MODULE.ActionBar4 and MODULE.ActionBar4:IsShown() then
			anchor = MODULE.ActionBar4
		end
	
		if anchor ~= UIParent then
			element:SetPoint("RIGHT", anchor, "LEFT", -spacing, 0)
		else
			element:SetPoint("RIGHT", UIParent, "RIGHT", margin, -margin)
		end
	end

	function element_proto:PostCreate()
        local element = self

        local frame = _G.PetActionBar or _G.PetActionBarFrame
        if frame then
			-- frame:SetShown(true)
			-- frame:EnableMouse(false)
			frame:SetParent(element)
			frame:ClearAllPoints()
			frame:SetAllPoints(E.Hider)
			frame.ignoreFramePositionManager = true
			frame.ignoreInLayout = true
        end
    end
end

function MODULE:CreatePetBar()
	return self:CreateActionBar("PetBar", element_proto)
end
