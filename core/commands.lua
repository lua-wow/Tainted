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
            print("|cffff0000" .. SLASH_TAINTED1 .. " " .. cmd .. "|r:", v.description)
        end
    end
end

E:AddCommand("help", help)

SLASH_RELOADUI1 = "/rl"
SlashCmdList["RELOADUI"] = ReloadUI
