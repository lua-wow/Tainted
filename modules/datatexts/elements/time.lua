local _, ns = ...
local E, C, L = ns.E, ns.C, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local GetCVar = C_CVar and C_CVar.GetCVar or GetCVar
local SetCVar = C_CVar and C_CVar.SetCVar or SetCVar
local GetCVarBool = C_CVar and C_CVar.GetCVarBool or GetCVarBool
local GetGameTime = _G.GetGameTime
local GetNumSavedInstances = _G.GetNumSavedInstances
local GetNumSavedWorldBosses = _G.GetNumSavedWorldBosses
local GetSavedInstanceInfo = _G.GetSavedInstanceInfo
local GetSavedWorldBossInfo = _G.GetSavedWorldBossInfo
local InCombatLockdown = _G.InCombatLockdown

-- Mine
local UPDATE_INTERVAL = 10

local TIME = L.TIME or "Time"
local LOCAL_TIME = L.LOCAL_TIME or "Local"
local SERVER_TIME = L.SERVER_TIME or "Server"
local WORLD_BOSSES = L.WORLD_BOSSES or "World Bosses"
local INSTANCES = L.INSTANCES or "Saved Instances"
local SAVED_ENCOUNTERS = "%s - %s (%d/%d)" -- Nerub-ar Palace - Mythic (10/14)
local SAVED_INSTANCES = "%s - %s" -- Nerub-ar Palace - Mythic

local time_proto = {}

function time_proto:GetLocalTime(wantAMPM)
	local hour, minute = tonumber(date("%H")), tonumber(date("%M"))
	return GameTime_GetFormattedTime(hour, minute, wantAMPM)
end

function time_proto:GetServerTime(wantAMPM)
	local serverTime = C_DateAndTime.GetServerTimeLocal()
	local hour, minute = tonumber(date("%H", serverTime)), tonumber(date("%M", serverTime))
    return GameTime_GetFormattedTime(hour, minute, wantAMPM)
end

function time_proto:GetTime(wantAMPM)
	local isLocalTime = GetCVarBool("timeMgrUseLocalTime")
	if isLocalTime then
		return self:GetLocalTime(wantAMPM)
	end
	return self:GetServerTime(wantAMPM)
end

function time_proto:GetResetTime(value)
	local days, hours, minutes, seconds = ChatFrame_TimeBreakDown(math.floor(value))
	if (days and days > 0) then
		return ("%dd %dh %dm"):format(days, hours, minutes) -- 7d, 2h, 5m
	elseif (hours and hours > 0) then
		return ("%dh %dm"):format(hours, minutes) -- 12h, 32m
	end
    return ("%dm %ds"):format(minutes, seconds) -- 5m, 42s
end

function time_proto:CreateTooltip(tooltip)
	local numSavedInstances = GetNumSavedInstances() or 0
	local numSavedWorldBosses = GetNumSavedWorldBosses() or 0

	if (numSavedWorldBosses > 0) then
		tooltip:AddLine(WORLD_BOSSES)

		for i = 1, numSavedWorldBosses do
			local name, worldBossID, reset = GetSavedWorldBossInfo(i)
			if (name and reset) then
				local resetTime = self:GetResetTime(reset)
				tooltip:AddDoubleLine(name, resetTime, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
			end
		end
	end

	if (numSavedWorldBosses > 0) then
		tooltip:AddLine(" ")
	end

	if (numSavedInstances > 0) then
		tooltip:AddLine(INSTANCES)

		for i = 1, numSavedInstances do
			local name, lockoutID, reset, difficultyID, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID = GetSavedInstanceInfo(i)
			if (name and (locked or extended)) then
				local resetTime = self:GetResetTime(reset)
				if (numEncounters and numEncounters > 0) and (encounterProgress and encounterProgress > 0) then
					tooltip:AddDoubleLine(SAVED_ENCOUNTERS:format(name, difficultyName, encounterProgress, numEncounters), resetTime, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
				else
					tooltip:AddDoubleLine(SAVED_INSTANCES:format(name, difficultyName), resetTime, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
				end
			end
		end
	end

    if (numSavedWorldBosses > 0) or (numSavedInstances > 0) then
		tooltip:AddLine(" ")
	end
	
	do
    	local localTime = self:GetLocalTime(true)
		tooltip:AddDoubleLine(LOCAL_TIME, localTime, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1.0, 1.0, 1.0)

		local serverTime = self:GetServerTime(true)
		tooltip:AddDoubleLine(SERVER_TIME, serverTime, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1.0, 1.0, 1.0)
	end
end

function time_proto:OnMouseUp(click)
	if click == "RightButton" then
		TimeManager_Toggle()
	else
		if InCombatLockdown() then
			E:print(ERR_NOT_IN_COMBAT)
			return
		end

		if E.isRetail or E.isCata then
			GameTimeFrame_OnClick()
		else
			Stopwatch_Toggle()
		end
	end
end

function time_proto:OnUpdate(elapsed)
	self.updateInterval = self.updateInterval - (elapsed or 1)

	if (self.updateInterval <= 0) then
		local value = self:GetTime(C.datatexts.clock.format == "civilian")

        if self.Text then
            self.Text:SetText(value)
        end

		self.updateInterval = UPDATE_INTERVAL
	end
end

function time_proto:Update()
	self:OnUpdate()
end

function time_proto:Enable()
	self.updateInterval = 0

	-- setup clock format as 24-hour (military) or 12-hour (civilian)
	SetCVar("timeMgrUseMilitaryTime", C.datatexts.clock.format == "military" and 1 or 0)

    self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseUp", self.OnMouseUp)
    self:Update()
	self:Show()
end

function time_proto:Disable()
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)
	self:Hide()
end

MODULE:AddElement("Time", time_proto)
