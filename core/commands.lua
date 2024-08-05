local _, ns = ...
local E = ns.E

-- Blizzard
local ReloadUI = _G.ReloadUI

--------------------------------------------------
-- Slash Commands
--------------------------------------------------
local commands = {
    ["reset"] = {
        description = "reset Tainted settings",
        func = function()
            E:ResetDatabase()
            ReloadUI()
        end
    }
}

SLASH_TAINTED1 = "/tainted"
SlashCmdList["TAINTED"] = function(cmd)
    local msg = cmd:gsub("^ +", "")
    local command, arg = string.split(" ", msg, 2)
    arg = arg and arg:gsub(" ", "")
    
    if commands[command] then
        commands[command].func(arg)
    end
end

function E:AddCommand(command, handler, description)
    commands[command] = {
        func = handler,
        description = description
    }
end

local help = function()
    for cmd, v in next, commands do
        if (v.description) then
            print("|cffff8000Tainted " .. cmd .. "|r:", v.description)
        end
    end
end

local spell = function(value)
    if value then
        local data = C_Spell.GetSpellInfo(value)
        if data then
            Tainted.print("Spell " .. data.name .. " (" .. data.spellID .. ")", IsPlayerSpell(data.spellID))
        else
            Tainted.print("Spell " .. value .. " not found.")
        end
    else
        Tainted.print("Please, provide a spellID or spellName.")
    end
end

E:AddCommand("help", help)
E:AddCommand("spell", spell, "Look for spell information based on spellID or name.")

SLASH_RELOADUI1 = "/rl"
SlashCmdList["RELOADUI"] = ReloadUI
