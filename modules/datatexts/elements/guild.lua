local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local IsInGuild = _G.IsInGuild
local GetGuildInfo = _G.GetGuildInfo
local GetNumGuildMembers = _G.GetNumGuildMembers
local InCombatLockdown = _G.InCombatLockdown

-- Mine
local DATATEXT_STRING = "%s %s"

local GUILD = L.GUILD
local MEMBERS = L.MEMBERS
local NO_GUILD = L.NO_GUILD

local guild_proto = {}

function guild_proto:OnMouseDown(button)
    if button == "LeftButton" or button == "RightButton" then
        if InCombatLockdown() then
            E:error(ERR_NOT_IN_COMBAT)
        else
            ToggleGuildFrame()
        end
    end
end

function guild_proto:CreateTooltip(tooltip)
    local numTotalGuildMembers, numOnlineGuildMembers, numOnlineAndMobileMembers = GetNumGuildMembers()
    if IsInGuild() and numOnlineGuildMembers > 0 then
        local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(self.unit)

        tooltip:AddDoubleLine(guildName, guildRealm or "", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        -- tooltip:AddDoubleLine("Members", "|cff00ff00" .. FRIENDS_LIST_ONLINE .. "|r |cffffffff(" .. numOnlineGuildMembers .. ")|r", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        tooltip:AddDoubleLine(MEMBERS, ("%d / %d"):format(numOnlineGuildMembers, numTotalGuildMembers), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
	    tooltip:AddLine(" ")

        for index = 1, numOnlineGuildMembers do
            local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline,
            status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(index)
            if guid ~= self.guid then
				local classColor = E.colors.class[class]
				local difficultyColor = E.GetRelativeDifficultyColor(UnitLevel(self.unit), level)
				GameTooltip:AddDoubleLine(name, ("%s (%s)"):format(difficultyColor:WrapTextInColorCode(level), zone), classColor.r, classColor.g, classColor.b, 1.0, 1.0, 1.0)
            end
        end
    end
end

function guild_proto:OnEvent(event, ...)
    if IsInGuild() then
        local numTotalGuildMembers, numOnlineGuildMembers, numOnlineAndMobileMembers = GetNumGuildMembers()
        local value = self.color:WrapTextInColorCode(numOnlineGuildMembers or 0)
        self.Text:SetFormattedText(DATATEXT_STRING, GUILD, value)
    else
        self.Text:SetText(NO_GUILD)
    end
end

function guild_proto:Update()
    self:OnEvent("ForceUpdate")
end

function guild_proto:Enable()
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Update()
    self:Show()
end

function guild_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Guild", guild_proto)
