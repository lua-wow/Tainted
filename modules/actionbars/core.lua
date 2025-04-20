local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:CreateModule("ActionBars")

local function Hook_UpdateHotkeys(button)
    local hotkey = button.HotKey
    if not hotkey then return end

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

MODULE.StyleActionButton = function(button)
    if not button then return end
    if button.__styled then return end

    if button.CreateBackdrop then
        button:CreateBackdrop()
    end

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

    local buttonName = button.GetName and button:GetName() or nil

    local normal = button.GetNormalTexture and button:GetNormalTexture() or (buttonName and _G[buttonName .. "NormalTexture"])
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
    
    local FloatingBG = buttonName and _G[buttonName .. "FloatingBG"] or nil
    if FloatingBG then FloatingBG:Hide() end
    
    -- button.SpellCastAnimFrame
    -- button.SpellHighlightAnim

    -- extra action button and zone ability button
    local style = button.style or button.Style
    if style then
        style:Hide()
        style:SetParent(E.Hider)
    end

    -- if button.UpdateFlyout then
    --     hooksecurefunc(button, "UpdateFlyout", MODULE.UpdateFlyout)
    -- end

    button.__styled = true

    return button
end

function MODULE:Hide(obj, events)
    if not obj then return end

    obj:Hide()
    obj:SetParent(E.Hider)
    obj.ignoreFramePositionManager = true
    obj.ignoreInLayout = true

    -- with 8.2, there's more restrictions on frame anchoring if something
    -- happens to be attached to a restricted frame. This causes issues with
    -- moving the action bars around, so we perform a clear all points to avoid
    -- some frame dependency issues
    -- we then follow it up with a SetPoint to handle the cases of bits of the
    -- UI code assuming that this element has a position
    obj:ClearAllPoints()
    obj:SetPoint("CENTER")

    if obj.EnableMouse then
		obj:EnableMouse(false)
	end

    if events and obj.UnregisterAllEvents then
        obj:UnregisterAllEvents()
		-- obj:SetAttribute("statehidden", true)
	end
end

function MODULE:ToggleBagsBar()
    local element = _G.BagsBar
    if not element then return end

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
    if not element then return end
    
    if element:IsShown() then
        element:Hide()
    else
        element:Show()
    end
    element:ClearAllPoints()
    element:SetPoint("BOTTOMRIGHT", UIParent, -10, 220)
end

function MODULE:DisableBlizzard()
    self:Hide(_G.MainMenuBar, true)
    self:Hide(_G.MainMenuBarArtFrame, true)
    -- self:Hide(_G.OverrideActionBar, true)
    self:Hide(_G.PossessBarFrame, true)
    self:Hide(_G.ShapeshiftBarLeft, true)
    self:Hide(_G.ShapeshiftBarMiddle, true)
    self:Hide(_G.ShapeshiftBarRight, true)

    -- -- retail
    self:Hide(_G.StatusTrackingBarManager, true)
    self:Hide(_G.MainStatusTrackingBarContainer, true)
    self:Hide(_G.SecondaryStatusTrackingBarContainer, true)

    if E.isClassic then
        MultiActionBar_Update = function() end
        BeginActionBarTransition = function() end
    end

    -- temporary
    local MicroMenu = _G.MicroMenu
    if MicroMenu then
        MicroMenu:ClearAllPoints()
        MicroMenu:SetPoint("BOTTOMRIGHT", UIParent, -10, 220)
        MicroMenu:Hide()
    end

    local BagsBar = _G.BagsBar
    if BagsBar then
        BagsBar:ClearAllPoints()
        BagsBar:SetPoint("BOTTOMRIGHT", UIParent, -10, 260)
        BagsBar:Hide()
    end
end

function MODULE:Init()
    if not C.actionbars.enabled then return end

    -- diplay action bar grid
    if not E.isRetail then
        SetCVar("alwaysShowActionBars", 1)
    end

    local actionbars = {
        true, -- bar 2
        true, -- bar 3
        true, -- bar 4
        true, -- bar 5
        (not E.isClassic and C.actionbars.bar6) and true or false, -- bar 6
        (not E.isClassic and C.actionbars.bar7) and true or false, -- bar 7
        (not E.isClassic and C.actionbars.bar8) and true or false, -- bar 8
        true -- always show action bars
    }

    -- sets the visible state for each action bar
    SetActionBarToggles(unpack(actionbars))

    -- hide blizzard frames
    self:DisableBlizzard()

    -- costumize action bars
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

    if E.isRetail then
        do
            local holder = CreateFrame("Frame", "TaintedExtraAbilityHolder", UIParent)
            holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 80)
            holder:SetSize(256, 128)
            holder:SetClampedToScreen(true)

            self:CreateExtraActionButton(holder)
        end

        do
            local holder = CreateFrame("Frame", "TaintedZoneAbilityHolder", UIParent)
            holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 70)
            holder:SetSize(256, 128)
            holder:SetClampedToScreen(true)

            self:CreateZoneAbilityButton(holder)
        end
    end
end
