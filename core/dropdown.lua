local _, ns = ...
local E = ns.E
local MODULE = E:CreateModule("DropDown")

-- Blizzard
local UIDROPDOWNMENU_MAXLEVELS = _G.UIDROPDOWNMENU_MAXLEVELS or 3

-- Initialize the dropdown menu items
local function Initialize(frame, level, menuList)
	-- Iterate through the menu items
	for index, menuItem in ipairs(menuList) do
		-- Assign an index to the menu item
		menuItem.index = index

		-- Add the menu item to the dropdown
		UIDropDownMenu_AddButton(menuItem, level)
	end
end

-- Create a dropdown menu
function E:CreateDropDown(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
	-- Set default values for optional parameters
	displayMode = displayMode or "MENU"
	menuFrame = menuFrame or CreateFrame("Frame")

	-- Set the display mode of the menu frame
	menuFrame.displayMode = displayMode

	-- Initialize the dropdown menu
	UIDropDownMenu_Initialize(menuFrame, Initialize, displayMode, nil, menuList)

	-- Show the dropdown menu
	ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList, nil, autoHideDelay)
end

function MODULE:Skin(...)
    local manager = self
    local dropdown = self:GetOpenMenu()
    if dropdown and not dropdown.__skinned then
        dropdown:StripTextures()
        dropdown:CreateBackdrop(0.90)
        dropdown.__skinned = true
    end
end

function MODULE:SkinBackdrop(backdrop)
    if backdrop and not backdrop.__skinned then
        backdrop:StripTextures()
        backdrop:CreateBackdrop(0.80)
        if backdrop.NineSlice then
            backdrop.NineSlice:StripTextures()
        end
        backdrop.__skinned = true
    end
end

local UIDropDownMenu_CreateFrames = function(level, index)
    for index = 1, UIDROPDOWNMENU_MAXLEVELS do
        MODULE:SkinBackdrop(_G["DropDownList" .. index .. "Backdrop"])
        MODULE:SkinBackdrop(_G["DropDownList" .. index .. "MenuBackdrop"])
    end
end

function MODULE:Init()
    local menu = _G.Menu
    if menu then
        local manager = menu:GetManager()
        hooksecurefunc(manager, "OpenMenu", self.Skin)
		hooksecurefunc(manager, "OpenContextMenu", self.Skin)
    end

    hooksecurefunc("UIDropDownMenu_CreateFrames", UIDropDownMenu_CreateFrames)
end
