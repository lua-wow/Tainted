local _, ns = ...
local E = ns.E

-- Blizzard
local ReloadUI = _G.ReloadUI

--------------------------------------------------
-- Slash Commands
--------------------------------------------------
local keys = {}
local commands = {}

SLASH_TAINTED1 = "/tainted"
SlashCmdList["TAINTED"] = function(cmd)
    local msg = cmd:gsub("^ +", "")
    local command, arg = string.split(" ", msg, 2)
    arg = arg and arg:match("^%s*(.-)%s*$")
    
    if commands[command] then
        commands[command].func(arg)
    elseif commands[""] then
        -- unknown subcommand: show help
        commands[""].func()
    end
end

function E:AddCommand(command, handler, description)
    if not commands[command] then
        table.insert(keys, command)
        table.sort(keys)
    end

    commands[command] = {
        func = handler,
        description = description
    }
end

local help = function()
    for _, cmd in next, keys do
        local row = commands[cmd]
        if (row and row.description) then
            print("|cffff8000/tainted " .. cmd .. "|r:", row.description)
        end
    end
end

local spell = function(value)
    if value then
        local data = C_Spell.GetSpellInfo(tonumber(value) or value)
        if data then
            local isKnown = C_SpellBook.IsSpellKnown(data.spellID)
            E:print("Spell " .. data.name .. " (" .. data.spellID .. ")", isKnown)
        else
            E:print("Spell " .. value .. " not found.")
        end
    else
        E:print("Please, provide a spellID or spellName.")
    end
end

local reset = function()
    E:ResetDatabase()
    ReloadUI()
end

E:AddCommand("", help)
E:AddCommand("reset", reset, "reset Tainted settings")
E:AddCommand("spell", spell, "Look for spell information based on spellID or name.")

SLASH_RELOADUI1 = "/rl"
SlashCmdList["RELOADUI"] = ReloadUI
