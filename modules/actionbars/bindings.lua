local _, ns = ...
local E = ns.E

-- Blizzard
local DEFAULT_BINDINGS  = _G.DEFAULT_BINDINGS or 0
local ACCOUNT_BINDINGS  = _G.ACCOUNT_BINDINGS or 1
local CHARACTER_BINDINGS = _G.CHARACTER_BINDINGS or 2

local SetBinding = _G.SetBinding
local GetBinding = _G.GetBinding
local GetNumBindings = _G.GetNumBindings
local SaveBindings = _G.SaveBindings
local GetCurrentBindingSet = _G.GetCurrentBindingSet

local SetupKeyBindings = function()
    -- returns if either account or character-specific bindings are active.
    local set = GetCurrentBindingSet()
    if (set == DEFAULT_BINDINGS) then
        E:print("You are using the default key bind configuration")
    elseif (set == ACCOUNT_BINDINGS) then
        E:print("You are using the account key bind configuration")
    elseif (set == CHARACTER_BINDINGS) then
        E:print("You are using the character-specific key bind configuration")
    end

    SetBinding("NUMPAD4", "ACTIONBUTTON8", 2)
    SetBinding("NUMPAD5", "ACTIONBUTTON9", 2)
    SetBinding("NUMPAD6", "ACTIONBUTTON10", 2)
    SetBinding("NUMPAD7", "ACTIONBUTTON11", 2)
    SetBinding("NUMPAD8", "ACTIONBUTTON12", 2)
    
    SetBinding("NUMPAD1", "MULTIACTIONBAR1BUTTON1", 1)
    SetBinding("NUMPAD2", "MULTIACTIONBAR1BUTTON2", 1)
    SetBinding("NUMPAD3", "MULTIACTIONBAR1BUTTON3", 1)
    SetBinding("T", "MULTIACTIONBAR1BUTTON4", 1)
    SetBinding("R", "MULTIACTIONBAR1BUTTON5", 1)
    SetBinding("F", "MULTIACTIONBAR1BUTTON6", 1)
    SetBinding("G", "MULTIACTIONBAR1BUTTON7", 1)
    SetBinding("Y", "MULTIACTIONBAR1BUTTON8", 1)
    SetBinding("NUMPAD9", "MULTIACTIONBAR1BUTTON9", 1)
    SetBinding("F3", "MULTIACTIONBAR1BUTTON10", 1)
    SetBinding("F2", "MULTIACTIONBAR1BUTTON11", 1)
    SetBinding("F1", "MULTIACTIONBAR1BUTTON12", 1)
    
    SetBinding("ALT-NUMPADPLUS", "MULTIACTIONBAR3BUTTON5", 2)
    SetBinding("SHIFT-NUMPADPLUS", "MULTIACTIONBAR3BUTTON6", 2)
    SetBinding("CTRL-NUMPADPLUS", "MULTIACTIONBAR3BUTTON7", 2)
    SetBinding("NUMPADMINUS", "MULTIACTIONBAR3BUTTON8", 2)
    SetBinding("NUMPAD0", "MULTIACTIONBAR3BUTTON9", 2)
    SetBinding("F6", "MULTIACTIONBAR3BUTTON10", 2)
    SetBinding("F5", "MULTIACTIONBAR3BUTTON11", 2)
    SetBinding("F4", "MULTIACTIONBAR3BUTTON12", 2)
    
    SetBinding("CTRL-Z", "MULTIACTIONBAR4BUTTON12", 1)

    SetBinding("NUMPADPLUS", "EXTRAACTIONBUTTON1", 1)
    
    SetBinding("BUTTON3", "PINGONMYWAY", 1)
    SetBinding("CTRL-BUTTON3", "PINGWARNING", 1)
    SetBinding("SHIFT-BUTTON3", "PINGASSIST", 1)
    SetBinding("ALT-BUTTON3", "TOGGLEPINGLISTENER", 1)
    SetBinding("CTRL-SHIFT-BUTTON3", "PINGATTACK", 1)
    
    SetBinding("SHIFT-Y", "TOGGLEACHIEVEMENT", 1) -- default: Y

    SaveBindings(ACCOUNT_BINDINGS)
end

E:AddCommand("keybindings", SetupKeyBindings, "Reconfigure keybindings.")
