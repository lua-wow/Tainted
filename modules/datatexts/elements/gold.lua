local _, ns = ...
local E, C, L = ns.E, ns.C, ns.L
local MODULE = E:GetModule("DataTexts")
local ActionBars = E:GetModule("ActionBars")
local Containers = E:GetModule("Containers")

-- Blizzard
local IsLoggedIn = _G.IsLoggedIn
local GetMoney = _G.GetMoney

-- Mine
local GOLD = L.GOLD
local CHARACTER = L.CHARACTER or "Character"
local DEFICIT = L.DEFICIT or "Deficit"
local EARNED = L.EARNED or "Earned"
local PROFIT = L.PROFIT or "Profit"
local SERVER = L.SERVER or "Server"
local SESSION = L.SESSION or "Session"
local SPENT = L.SPENT or "Spent"
local TOGGLE_BAGS_BAR_TEXT = L.TOGGLE_BAGS_BAR_TEXT
local TOGGLE_BAGS_TEXT = L.TOGGLE_BAGS_TEXT
local TOTAL = L.TOTAL or "Total"
local WARBAND = L.WARBAND or "Warband"


local gold_proto = {
    threshold = 15
}

function gold_proto:FormatMoney(value)
    local gold = math.floor(value / 10000)
    local silver = math.floor(value / 100 % 100)
    local copper = value % 100
    return ("%02d%s %02d%s %02d%s"):format(gold, L.gold, silver, L.silver, copper, L.copper)
end

local SortByMoney = function(a, b)
    if not a or not b then
        return false
    end

    local realmA, realmB = a.realm or "", b.realm or ""

    if realmA ~= realmB then
        if realmA == E.realm then
            return true
        end
        if realmB == E.realm then
            return false
        end
        return realmA < realmB
    end

    if a.money ~= b.money then
        return a.money > b.money
    end

    return a.name < b.name
end

function gold_proto:UpdateCharacterList(tooltip)
    self.characters = table.wipe(self.characters or {})

    for realm, realmData in next, TaintedDatabase do
        for name, charData in next, realmData do
            local money = tonumber(charData.money or "")
            if money then
                table.insert(self.characters, { realm = realm, name = (name or ""), money = (money or 0) })
            end
        end
	end

    table.sort(self.characters, SortByMoney)
end

function gold_proto:CreateTooltip(tooltip)
    local isShiftKeyDown = IsShiftKeyDown()

	tooltip:AddLine(SESSION)
	tooltip:AddDoubleLine(EARNED, self:FormatMoney(self.earned), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
	tooltip:AddDoubleLine(SPENT, self:FormatMoney(self.spent), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

    local change = self.earned - self.spent
	if (change < 0) then
		tooltip:AddDoubleLine(DEFICIT, self:FormatMoney(change), 1.0, 0.0, 0.0, 1.0, 1.0, 1.0)
	elseif (change > 0) then
		tooltip:AddDoubleLine(PROFIT, self:FormatMoney(change), 0.0, 1.0, 0.0, 1.0, 1.0, 1.0)
	end

	tooltip:AddLine(" ")

    self:UpdateCharacterList()

    local total = 0
	tooltip:AddLine(CHARACTER)

    for index, row in next, self.characters do
        if isShiftKeyDown or index <= self.threshold then
            local color = (row.name == E.name and row.realm == E.realm) and E.colors.class[E.class] or E.colors.white
            local left = ("%s - %s"):format(row.name, row.realm)
            tooltip:AddDoubleLine(left, self:FormatMoney(row.money), color.r, color.g, color.b, 1.0, 1.0, 1.0)
            total = total + row.money
        end
	end

    local length = #self.characters
    if (length > 0) and (length > self.threshold) and (not isShiftKeyDown) then
        tooltip:AddLine(L.HOLD_SHIFT_TO_SHOW_ALL_CHARACTERS, 0.70, 0.70, 0.70)
    end

	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(TOTAL, self:FormatMoney(total), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

    if C_Bank and C_Bank.FetchDepositedMoney then
        local warband = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine("Warband", self:FormatMoney(warband), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end
    
    tooltip:AddLine(" ")
    tooltip:AddLine(TOGGLE_BAGS_TEXT)
    tooltip:AddLine(TOGGLE_BAGS_BAR_TEXT)
end

function gold_proto:OnMouseDown()
    if IsShiftKeyDown() then
        if Containers then
            Containers:Toggle()
        else
            ActionBars:ToggleBagsBar()
        end
    else
        ToggleAllBags()
    end
end

function gold_proto:OnEvent(event, ...)
    if not IsLoggedIn() then return end

    -- get player current money
    local money = GetMoney()

    -- load money from saved variables
    local savedMoney = E:GetMoney() or money

    local change = money - savedMoney
    if (change < 0) then
        self.spent = self.spent - change
    elseif (change > 0) then
        self.earned = self.earned + change
    end

    if self.Text then
        self.Text:SetText(self:FormatMoney(money))
    end

    -- update money in saved variables
    E:SetMoney(money)
end

function gold_proto:Update()
    self:OnEvent("ForceUpdate")
end

function gold_proto:Enable()
    self.spent = 0
    self.earned = 0
    
    if self.Text then
        local color = C.datatexts.colors.value
        self.Text:SetText(GOLD)
        self.Text:SetTextColor(color:GetRGB())
    end
    
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
    self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("SEND_MAIL_COD_CHANGED")
	self:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
	self:RegisterEvent("TRADE_MONEY_CHANGED")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
	self:Update()
    self:Show()
end

function gold_proto:Disable()
    if self.Text then
        self.Text:SetText("")
    end
    
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Gold", gold_proto)
