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

function E:ResetDatabase()
    TaintedDatabase[realm][name] = {}
    TaintedChatHistory = {}
    self.db = TaintedDatabase[realm][name]
end

-- experience bar
function E:GetExperienceBarIndex()
	return self.db.experience
end

function E:SetExperienceBarIndex(index)
	self.db.experience = index
end

-- Gold
function E:GetMoney()
    return self.db.money
end

function E:SetMoney(value)
    self.db.money = value
end

-- KeyStone
function E:GetKeyStone()
    return self.db.keystone
end

function E:SetKeyStone(value)
    self.db.keystone = value
end

function E:GetVault()
    return self.db.vault
end

function E:SetVault(value)
    self.db.vault = value
end
