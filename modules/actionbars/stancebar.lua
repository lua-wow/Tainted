local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local NUM_SPECIAL_BUTTONS  = _G.NUM_SPECIAL_BUTTONS  or 10

local InCombatLockdown = _G.InCombatLockdown
local GetNumShapeshiftForms = _G.GetNumShapeshiftForms

local element_proto = {
	name = "StanceButton",
	num = NUM_SPECIAL_BUTTONS,
	size = C.actionbars.stance.size,
    spacing = C.actionbars.stance.spacing,
    horizontal = C.actionbars.stance.horizontal,
	visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show",
}

do
	function element_proto:UpdateAnchor()
		local element = self
		element:ClearAllPoints()
		element:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
	end

	function element_proto:PostCreate()
		local element = self

		local frame = _G.StanceBar
		if frame then
			frame:StripTextures()
			frame:EnableMouse(false)

			-- Blizzard's Update runs on every form change and sets icon, cooldown and checked state
			hooksecurefunc(frame, "Update", function()
				element:Update()
			end)
		end
	end

	function element_proto:Update()
		local element = self

		local numForms = GetNumShapeshiftForms() or 0

		if not InCombatLockdown() then
			if numForms == 0 then
				element:SetAlpha(0)
				element:Hide()
			else
				element:SetAlpha(1)
				element:Show(true)

				-- resize backdrop
				element:CreateBackground(numForms)
			end
		end

		for index = 1, numForms do
			local button = _G[element.name .. index]
			if button and button.Backdrop then
				if button:GetChecked() then
					button.Backdrop:SetBackdropBorderColor(C.general.highlight.color:GetRGB())
				else
					button.Backdrop:SetBackdropBorderColor(C.general.border.color:GetRGB())
				end
			end
		end
	end
end

function MODULE:CreateStanceBar()
	local element = self:CreateActionBar("StanceBar", element_proto)
	
	element:Update()
	-- element:SkinStanceButtons()

	return element
end
