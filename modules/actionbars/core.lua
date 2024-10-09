local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:CreateModule("ActionBars")

-- Blizzard
local NUM_SPECIAL_BUTTONS = _G.NUM_SPECIAL_BUTTONS or 10
local NUM_PET_ACTION_SLOTS = _G.NUM_PET_ACTION_SLOTS or 10
local NUM_ACTIONBAR_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS or 12
local MAIN_MENU_BAR_NUM_BUTTONS  = _G.MAIN_MENU_BAR_NUM_BUTTONS or 12
local MULTI_BAR_BOTTOM_LEFT_NUM_BUTTONS   = _G.MULTI_BAR_BOTTOM_LEFT_NUM_BUTTONS or 12
local MULTI_BAR_BOTTOM_RIGHT_NUM_BUTTONS    = _G.MULTI_BAR_BOTTOM_RIGHT_NUM_BUTTONS  or 12

-- local ACTION_BARS = {
--     ["bar1"] = { visibility = "[petbattle] hide; show" },
--     ["bar2"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar3"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar4"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar5"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar6"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar7"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar8"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["pet"] = { visibility = "[pet,nopetbattle,nooverridebar,nopossessbar] show; hide" },
--     ["petbattle"] = { visibility = "[petbattle] show; hide" },
--     ["stance"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
-- }

local actionbar_proto = {
    _enabled = true,
    _num = NUM_ACTIONBAR_BUTTONS,
    _size = C.actionbars.size,
    _spacing = C.actionbars.spacing,
    _visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show",
    _horizontal = true
}

function actionbar_proto:Update()
    self:UpdateAnchor()
    self:CreateBackground(self._num, self._size, self._spacing, self._horizontal)
    self:UpdateVisibility()
    self:UpdateButtonsPosition()
end

function actionbar_proto:UpdateAnchor()
    self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function actionbar_proto:CreateBackground(num, size, spacing, isHorizontal)
    local rows = (not isHorizontal) and num or 1
    local cols = isHorizontal and num or 1
    self:SetWidth((cols * size) + ((cols + 1) * spacing))
    self:SetHeight((rows * size) + ((rows + 1) * spacing))
	self:CreateBackdrop("transparent")
end

function actionbar_proto:Enable()
	RegisterStateDriver(self, "visibility", self._visibility or "show")
    self:Show()
end

function actionbar_proto:Disable()
	UnregisterStateDriver(self, "visibility")
    self:Hide()
end

function actionbar_proto:UpdateVisibility()
    if self._enabled then
	    self:Enable()
    else
        self:Disable()
    end
end

function actionbar_proto:UpdateButtonsPosition()
    local element = self

    local size = element._size
    local spacing = element._spacing

    element:CreateBackground(element._num, size, spacing, element._horizontal)

    for i, button in next, element._buttons do
        button:SetParent(button._parent or element)
        button:ClearAllPoints()
        button:SetSize(size, size)

        if i == 1 then
            button:SetPoint("TOPLEFT", element, "TOPLEFT", spacing, -spacing)
        else
            local anchor = element._buttons[i - 1]
            if element._horizontal then
                button:SetPoint("LEFT", anchor, "RIGHT", spacing, 0)
            else
                button:SetPoint("TOP", anchor, "BOTTOM", 0, -spacing)
            end
        end
    end
end

local function Hook_UpdateHotkeys(button)
    local hotkey = button.HotKey
    local text = hotkey:GetText()
    if not text then return end
    if text ~= _G.RANGE_INDICATOR then
        text = text:gsub("(s%-)", "|cffff8000s|r")
        text = text:gsub("(a%-)", "|cffff8000a|r")
        text = text:gsub("(c%-)", "|cffff8000c|r")
        text = text:gsub(_G.KEY_BUTTON3, "m3")
        text = text:gsub(_G.KEY_BUTTON4, "m4")
        text = text:gsub(_G.KEY_BUTTON5, "m5")
        text = text:gsub(_G.KEY_MOUSEWHEELUP, "mU")
        text = text:gsub(_G.KEY_MOUSEWHEELDOWN, "mD")
        text = text:gsub(_G.KEY_NUMPAD0, "N0")
        text = text:gsub(_G.KEY_NUMPAD1, "N1")
        text = text:gsub(_G.KEY_NUMPAD2, "N2")
        text = text:gsub(_G.KEY_NUMPAD3, "N3")
        text = text:gsub(_G.KEY_NUMPAD4, "N4")
        text = text:gsub(_G.KEY_NUMPAD5, "N5")
        text = text:gsub(_G.KEY_NUMPAD6, "N6")
        text = text:gsub(_G.KEY_NUMPAD7, "N7")
        text = text:gsub(_G.KEY_NUMPAD8, "N8")
        text = text:gsub(_G.KEY_NUMPAD9, "N9")
        text = text:gsub(_G.KEY_NUMPADDECIMAL, "N.")
        text = text:gsub(_G.KEY_NUMPADDIVIDE, "N/")
        text = text:gsub(_G.KEY_NUMPADMINUS, "N-")
        text = text:gsub(_G.KEY_NUMPADMULTIPLY, "N*")
        text = text:gsub(_G.KEY_NUMPADPLUS, "N+")
        text = text:gsub(_G.KEY_PAGEUP, "PU")
        text = text:gsub(_G.KEY_PAGEDOWN, "PD")
        text = text:gsub(_G.KEY_SPACE, "SPB")
        text = text:gsub(_G.KEY_INSERT, "INS")
        text = text:gsub(_G.KEY_HOME, "HM")
        text = text:gsub(_G.KEY_DELETE, "DEL")
        text = text:gsub(_G.KEY_BACKSPACE, "BKS")
        text = text:gsub(_G.KEY_INSERT_MAC, "HLP") -- mac

        hotkey:SetText(text)
    end
end

function actionbar_proto:StyleActionButton(button)
    return MODULE:StyleActionButton(button)
end

function MODULE:UpdateFlyout(isButtonDownOverride)
    if (not self.FlyoutArrowContainer or not self.FlyoutBorderShadow) then return end

    if self.FlyoutBorder then self.FlyoutBorder:SetTexture(nil) end
    if self.FlyoutBorderShadow then self.FlyoutBorderShadow:SetTexture(nil) end

    local SpellFlyout = _G.SpellFlyout
    if SpellFlyout and SpellFlyout:IsShown() then
        SpellFlyout.Background:Hide()

        for i, button in next, SpellFlyout:GetLayoutChildren() do
            MODULE:StyleActionButton(button)
        end
    end
end

function MODULE:StyleActionButton(button)
    if not button then return end
    if button.__styled then return end

    button:CreateBackdrop()

    local fontObject = E.GetFont(C.actionbars.font)

    local icon = button.icon or button.Icon
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(button)
        icon:SetTexCoord(unpack(E.IconCoord))
    end

    local count = button.Count
    if count then
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", 0, 0)
        count:SetFontObject(fontObject)
    end

    local cooldown = button.cooldown or button.Cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetAllPoints(button)

        local font, _fontSize, fontFlags = fontObject:GetFont()
        local timer = cooldown:GetCooldownTimer()
        timer:SetFont(font, 16, fontFlags)
        cooldown.Timer = timer
    end

    local hotkey = button.HotKey
    if hotkey then
        hotkey:ClearAllPoints()
        hotkey:SetPoint("TOPRIGHT", 0, -3)
        hotkey:SetFontObject(fontObject)
        hotkey:SetVertexColor(1, 1, 1)
        hotkey:SetDrawLayer("OVERLAY")
        hotkey:SetJustifyH("RIGHT")

        if button.UpdateHotkeys then
            hooksecurefunc(button, "UpdateHotkeys", Hook_UpdateHotkeys)
        end

        Hook_UpdateHotkeys(button)
    end

    local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		normal:SetTexture(nil)
		normal:SetAlpha(0)
		normal:Hide()
        button:SetNormalTexture(0)
	end

    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    if pushed then
        pushed:ClearAllPoints()
        pushed:SetOutside(icon or button, 3, 3)
    end
    
    -- if button.SetPushedTexture then
    --     local pushed = button:CreateTexture(nil, "HIGHLIGHT")
    --     pushed:SetAllPoints()
    --     pushed:SetColorTexture(0.90, 0.00, 0.10, 0.30)

    --     button:SetPushedTexture(pushed)
    -- end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetOutside(icon or button, 3, 3)
    end

    -- if button.SetHighlightTexture then
    --     local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	-- 	highlight:SetAllPoints()
    --     highlight:SetColorTexture(1.00, 1.00, 1.00, 0.30)
        
    --     button:SetHighlightTexture(highlight)    
    -- end

    local checkedTexture = button.GetCheckedTexture and button:GetCheckedTexture()
    if checkedTexture then
        checkedTexture:ClearAllPoints()
        checkedTexture:SetOutside(icon or button, 3, 3)
    end

    -- if button.SetCheckedTexture then
    --     local checked = button:CreateTexture(nil, "HIGHLIGHT")
	-- 	checked:SetAllPoints()
    --     checked:SetColorTexture(0.00, 1.00, 0.00, 0.30)
    --     checked:HookScript("OnShow", function(self)
    --         if button.Backdrop then
    --             button.Backdrop:SetBackdropBorderColor(C.general.highlight.color:GetRGB())
    --         end
    --     end)
    --     checked:HookScript("OnHide", function(self)
    --         if button.Backdrop then
    --             button.Backdrop:SetBackdropBorderColor(C.general.border.color:GetRGB())
    --         end
    --     end)

    --     button:SetCheckedTexture(checked)
    -- end

    if button.Name then button.Name:Hide() end
    if button.Flash then button.Flash:SetTexture(nil) end
    if button.Border then button.Border:SetTexture(nil) end
    if button.RightDivider  then button.RightDivider:Hide() end
    if button.NewActionTexture then button.NewActionTexture:Hide() end
    if button.FlyoutBorderShadow then button.FlyoutBorderShadow:Hide() end
    if button.SpellHighlightTexture then button.SpellHighlightTexture:Hide() end
    if button.IconMask then button.IconMask:Hide() end
    if button.SlotArt then button.SlotArt:SetTexture(nil) end
    if button.SlotBackground then button.SlotBackground:SetTexture(nil) end

    -- pet action button
    if button.CooldownFlash then button.CooldownFlash:Hide() end
    if button.AutoCastOverlay then button.AutoCastOverlay:Hide() end
    if button.LevelLinkLock then button.LevelLinkLock:Hide() end
    
    -- button.SpellCastAnimFrame
    -- button.SpellHighlightAnim

    -- extra action button and zone ability button
    local style = button.style or button.Style
    if style then
        style:Hide()
        style:SetParent(E.Hider)
    end

    if button.UpdateFlyout then
        hooksecurefunc(button, "UpdateFlyout", MODULE.UpdateFlyout)
    end

    button.__styled = true

    return button
end

function MODULE:CreateActionBar(name, element_proto)
    local element = Mixin(CreateFrame("Frame", "Tainted" .. name, E.PetHider, "SecureHandlerStateTemplate"), actionbar_proto, element_proto or {})
    element:SetFrameLevel(5)
    element:SetSize(0, 0)
    element._buttons = {}

    self[name] = element

    return element
end

function MODULE:Hide(obj)
    if not obj then return end

    obj:Hide()

    if obj.EnableMouse then
		obj:EnableMouse(false)
	end

    if obj.UnregisterAllEvents then
        obj:UnregisterAllEvents()
		obj:SetAttribute("statehidden", true)
	end

    obj:SetParent(E.Hider)
end

function MODULE:ToggleBagsBar()
    local element = _G.BagsBar
    if element:IsShown() then
        element:Hide()
    else
        element:Show()
    end
    element:ClearAllPoints()
    element:SetPoint("BOTTOMRIGHT", UIParent, -10, 260)
end

function MODULE:ToggleMicroMenu()
    local element = _G.MicroMenu
    if element:IsShown() then
        element:Hide()
    else
        element:Show()
    end
    element:ClearAllPoints()
    element:SetPoint("BOTTOMRIGHT", UIParent, -10, 220)
end

function MODULE:Init()
    SetActionBarToggles(
        1,                              -- action bar 2
        1,                              -- action bar 3
        1,                              -- action bar 4
        1,                              -- action bar 5
        C.actionbars.bar6 and 1 or nil, -- action bar 6
        C.actionbars.bar7 and 1 or nil, -- action bar 7
        C.actionbars.bar8 and 1 or nil  -- action bar 8
    )

    -- temporary
    do
        MicroMenu:ClearAllPoints()
        MicroMenu:SetPoint("BOTTOMRIGHT", UIParent, -10, 220)
        MicroMenu:Hide()

        BagsBar:ClearAllPoints()
        BagsBar:SetPoint("BOTTOMRIGHT", UIParent, -10, 260)
        BagsBar:Hide()
    end

    self:Hide(_G.MainMenuBar)
    -- self:Hide(_G.OverrideActionBar)
    self:Hide(_G.StatusTrackingBarManager)
	self:Hide(_G.MainStatusTrackingBarContainer)
	self:Hide(_G.SecondaryStatusTrackingBarContainer)

    local frame = _G.MainMenuBar
    -- frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    self:CreateActionBar1()
    self:CreateActionBar2()
    self:CreateActionBar3()
    self:CreateActionBar4()
    self:CreateActionBar5()
    
    self:CreateActionBar6()
    self:CreateActionBar7()
    self:CreateActionBar8()

    self:CreatePetBar()
    self:CreateStanceBar()

    do
        local holder = CreateFrame("Frame", "TaintedExtraAbilityHolder", UIParent)
        holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50)
        holder:SetSize(256, 128)
        holder:SetClampedToScreen(true)

        self:CreateExtraActionButton(holder)
        self:CreateZoneAbilityButton(holder)
    end
end
