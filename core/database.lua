local _, ns = ...
local E = ns.E

--------------------------------------------------
-- Database
--------------------------------------------------
local name, realm = E.name, E.realm

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

    if not TaintedChatHistory then
        TaintedChatHistory = {}
    end

    self.db = TaintedDatabase[realm][name]
end

function E:GetDatabase()
    return TaintedDatabase
end

function E:ResetDatabase()
    TaintedDatabase[realm][name] = {}
    TaintedChatHistory = {}
end

function E:IsInstalled()
	return TaintedDatabase[realm][name].installed
end

function E:MarkAsInstalled()
    TaintedDatabase[realm][name].installed = true
end

-- chat
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

-- experience bar
function E:GetExperienceBarIndex()
	return TaintedDatabase[realm][name].experience
end

function E:SetExperienceBarIndex(index)
	TaintedDatabase[realm][name].experience = index
end

-- Gold
function E:GetMoney()
    return TaintedDatabase[realm][name].money
end

function E:SetMoney(value)
    TaintedDatabase[realm][name].money = value
end
