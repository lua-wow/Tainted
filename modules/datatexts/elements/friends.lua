local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local IsInGuild = _G.BNGetNumFriends
local InCombatLockdown = _G.InCombatLockdown

-- Mine
local WORLD_OF_WARCRAFT_STRING = "Worlf of Warcraft"
local BATTLENET_STRING = "Battle.net"
local COUNT_STRING = "%d / %d"

local BATTLENET_COLOR = E:CreateColor(0.00, 0.80, 1.00)
local GAMES = {
	["WoW"] = "World of Warcraft",
	["S2"] = "StarCraft 2",
	["OSI"] = "Diablo II: Resurrected",
	["D3"] = "Diablo 3",
	["Fen"] = "Diablo 4",
	["WTCG"] = "Hearthstone",
	["App"] = nil, -- "Battle.net Desktop App",
	["BSAp"] = nil, --"Battle.net Mobile App",
	["Hero"] = "Heroes of the Storm",
	["Pro"] = "Overwatch",
	["CLNT"] = "Battle.net Desktop App",
	["S1"] = "StarCraft: Remastered",
	["DST2"] = "Destiny 2",
	["VIPR"] = "Call of Duty: Black Ops 4",
	["ODIN"] = "Call of Duty: Modern Warfare",
	["LAZR"] = "Call of Duty: Modern Warfare 2",
	["ZEUS"] = "Call of Duty: Black Ops Cold War",
	["W3"] = "Warcraft III: Reforged",
}
local GAMES_PRIORITY = {
    ["WoW"] = 10,
	["W3"] = 9,
	["S1"] = 8,
	["S2"] = 7,
	["OSI"] = 6,
	["D3"] = 5,
	["Fen"] = 4,
	["WTCG"] = 3,
	["Pro"] = 2,
	["Hero"] = 1,
    -- useless
	-- ["App"] = nil, -- "Battle.net Desktop App",
	-- ["BSAp"] = nil, --"Battle.net Mobile App",
	-- ["CLNT"] = "Battle.net Desktop App",
	-- ["DST2"] = "Destiny 2",
	-- ["VIPR"] = "Call of Duty: Black Ops 4",
	-- ["ODIN"] = "Call of Duty: Modern Warfare",
	-- ["LAZR"] = "Call of Duty: Modern Warfare 2",
	-- ["ZEUS"] = "Call of Duty: Black Ops Cold War",
}

local friends = {}
local tags = {}

local friends_proto = {}

function friends_proto:OnMouseDown(button)
    if button == "LeftButton" or button == "RightButton" then
        if InCombatLockdown() then
            E:error(ERR_NOT_IN_COMBAT)
        else
            ToggleFriendsFrame(1)
        end
    end
end

function friends_proto:GetClass(value)
    if not value then return end
	for i, j in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		if j == value then
			return i
		end
	end
    return value
end

function friends_proto:UpdateFriendsList(num)
    friends = table.wipe(friends or {})
    for index = 1, num do
        local info = C_FriendList.GetFriendInfoByIndex(index)
        if info then
            table.insert(friends, {
                index = index,
                online = info.connected,
                -- character
                guid = info.guid,
                name = info.name,
                class = self:GetClass(info.className),
                area = (info.area ~= "Unknown") and info.area or nil,
                level = (info.level ~= "Unknown") and info.level or nil,
                isDND = info.dnd,
                isAFK = info.afk,
                isMobile = info.mobile
            })
        end
    end
end

local SortBattleTags = function(a, b)
    if a.client ~= b.client then
        return a.clientPriority > b.clientPriority
    end
    return a.index < b.index
end

function friends_proto:UpdateBattleTagList(num)
    tags = table.wipe(tags or {})
    for index = 1, num do
        local info = C_BattleNet.GetFriendAccountInfo(index)
        if info then
            local gameInfo = info.gameAccountInfo

            local client = gameInfo and gameInfo.clientProgram or nil

            table.insert(tags, {
                index = index,
                accountName = info.accountName,
                battleTag = info.battleTag,
                online = (gameInfo and gameInfo.isOnline) or false, -- for some reason this value is true even when friend is using Battle.net App
                client = client,
                clientPriority = GAMES_PRIORITY[client or "none"] or 0,
                wowProjectID = gameInfo and gameInfo.wowProjectID or nil,
                -- character
                guid = gameInfo and gameInfo.playerGuid or nil,
                name = gameInfo and gameInfo.characterName or nil,
                realm = gameInfo and gameInfo.realmName or nil,
                realmID = gameInfo and gameInfo.realmID or nil,
                realmName = gameInfo and gameInfo.realmDisplayName or nil,
                faction = gameInfo and gameInfo.factionName or nil,
                race = gameInfo and gameInfo.raceName or nil,
                class = self:GetClass(gameInfo and gameInfo.className or nil),
                area = gameInfo and gameInfo.areaName or nil,
                level = gameInfo and gameInfo.characterLevel or nil,
                isDND = (gameInfo and gameInfo.isGameBusy) or info.isDND,
                isAFK = (gameInfo and gameInfo.isGameAFK) or info.isAFK,
                isMobile = gameInfo and gameInfo.isWowMobile
            })
        end
    end

    table.sort(tags, SortBattleTags)
end

function friends_proto:CreateTooltip(tooltip)
    self.level = UnitLevel(self.unit)

    local numFriends = C_FriendList.GetNumFriends()
    local numOnlineFriends = C_FriendList.GetNumOnlineFriends()
    local numBNetTotal, numBNetOnline, numBNetFavorite, numBNetFavoriteOnline = BNGetNumFriends()

    local num = numOnlineFriends + numBNetOnline
    if num > 0 then
        self:UpdateFriendsList(numOnlineFriends)
        self:UpdateBattleTagList(numBNetOnline)

        if numBNetOnline > 0 then
            tooltip:AddDoubleLine(BATTLENET_STRING, COUNT_STRING:format(numBNetOnline, numBNetTotal))

            for _, tag in next, tags do
                if tag.online then
                    local game = GAMES[tag.client]
                    if game then
                        local left = BATTLENET_COLOR:WrapTextInColorCode(tag.accountName)
                        local right = game

                        if tag.wowProjectID then
                            local classColor = E.colors.class[tag.class]
                            left = left .. " (" .. classColor:WrapTextInColorCode(tag.name)

                            local difficultyColor = E.GetRelativeDifficultyColor(self.level, tag.level)
                            left = left .. " " .. difficultyColor:WrapTextInColorCode(tag.level) .. ")"

                            -- if (tag.wowProjectID == WOW_PROJECT_MAINLINE) then
                            if (tag.wowProjectID == WOW_PROJECT_CLASSIC) then
                                right = right .. " Classic"
                            elseif (tag.wowProjectID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
                                right = right .. " Classic (TBC)"
                            elseif (tag.wowProjectID == WOW_PROJECT_WRATH_CLASSIC) then
                                right = right .. " Classic (Wrath)"
                            elseif (tag.wowProjectID == WOW_PROJECT_CATACLYSM_CLASSIC) then
                                right = right .. " Classic (Cataclysm)"
                            end

                            if tag.area then
                                right = tag.area .. " - " .. right
                            end
                        end

                        tooltip:AddDoubleLine(left, right, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
                    end

                end
            end
        end
        
        if numOnlineFriends > 0 then
            if numBNetOnline > 0 then
                tooltip:AddLine(" ")
            end

            tooltip:AddDoubleLine(WORLD_OF_WARCRAFT_STRING, COUNT_STRING:format(numOnlineFriends, numFriends))

            for _, friend in next, friends do
                local classColor = E.colors.class[friend.class or "none"]
                local difficultyColor = E.GetRelativeDifficultyColor(self.level, friend.level)
                local left = classColor:WrapTextInColorCode(friend.name) .. " " .. difficultyColor:WrapTextInColorCode("(" .. friend.level .. ")")
                local right = friend.area or UNKNOWN
                tooltip:AddDoubleLine(left, right, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
            end
        end
    else
        return true
    end
end

function friends_proto:OnEvent(event, ...)
    local numFriends = C_FriendList.GetNumFriends() -- friends (no battle.net tag)
    local numOnlineFriends = C_FriendList.GetNumOnlineFriends() -- online friends (no battle.net tag)
    local numBNetTotal, numBNetOnline, numBNetFavorite, numBNetFavoriteOnline = BNGetNumFriends() -- battle.net tags

    local num = numOnlineFriends + numBNetOnline
    local value = self.color:WrapTextInColorCode(num)

    if self.Text then
        self.Text:SetFormattedText("%s %s", FRIENDS, value)
    end
end

function friends_proto:Update()
    self:OnEvent("ForceUpdate")
end

function friends_proto:Enable()
    self:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
	self:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
	self:RegisterEvent("BN_FRIEND_INFO_CHANGED")
	self:RegisterEvent("BN_CONNECTED")
	self:RegisterEvent("BN_DISCONNECTED")
	self:RegisterEvent("FRIENDLIST_UPDATE")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Update()
    self:Show()
end

function friends_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Friends", friends_proto)
