local _, ns = ...
local E = ns.E

--------------------------------------------------
-- Database
--------------------------------------------------
local realm, name = E.Player.realm, E.Player.name

function E:InitDatabase()
    if not TaintedDatabase then
        TaintedDatabase = {}
    end

    if not TaintedDatabase[realm] then
        TaintedDatabase[realm] = {}
    end

    if not TaintedDatabase[realm][name] then
        TaintedDatabase[realm][name] = {}
    end

    -- chat hostory storage
    if not TaintedDatabase.ChatHistory then
        TaintedDatabase.ChatHistory = {}
    end

    return TaintedDatabase
end

function E:ResetDatabase()
    TaintedDatabase[realm][name] = {}
end

function E:IsInstalled()
	return TaintedDatabase[realm][name].installed
end

function E:MarkAsInstalled()
    TaintedDatabase[realm][name].installed = true
end

function E:MarkAsChatInstalled()
    TaintedDatabase[realm][name].chat = true
end

function E:MarkAsNotInstalled()
    TaintedDatabase[realm][name].installed = false
    TaintedDatabase[realm][name].chat = false
end

function E:IsChatInstalled()
	return TaintedDatabase[realm][name].chat
end
