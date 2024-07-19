local _, ns = ...
local E, C = ns.E, ns.C

-- Blizzard
local SetCVar = _G.SetCVar
local GetCVar = _G.GetCVar
local SetAutoDeclineGuildInvites = _G.SetAutoDeclineGuildInvites

--------------------------------------------------
-- CVars
--------------------------------------------------
local variables = {
	-- errors
	["scriptErrors"] = 1,
	["scriptWarnings"] = 1,
	["luaErrorExceptions"] = 1,

	-- system
	["screenshotQuality"] = 10,
	["showTutorials"] = 0,
	["violenceLevel"] = 5,

	-- camera
	["cameraSmoothStyle"] = 0,				-- default: 4
	
	-- sounds
	["Sound_EnableAllSound"] = 1,			-- enables all sounds
    ["Sound_MasterVolume"] = 0.15,			-- set master volume (0.0 to 1.0)
    ["Sound_EnableSFX"] = 1,				-- enables sound effects
    ["Sound_SFXVolume"] = 0.15,				-- sound effects volume (default = 1.0)
    ["Sound_EnableMusic"] = 1,				-- enables music sounds
    ["Sound_MusicVolume"] = 0.10,			-- set music volume (default = 0.4)
    ["Sound_EnableAmbience"] = 1,			-- enables ambience sounds
    ["Sound_AmbienceVolume"] = 0.20,		-- ambience volume (default = 0.6)
    ["Sound_EnableDialog"] = 1,				-- enables dialog volume
    ["Sound_DialogVolume"] = 0.20,			-- dialog volume (default 1.0)
	
	-- bags
	["combinedBags"] = 1,
	["expandBagBar"] = 1,
	
	-- chat
	["chatMouseScroll"] = 1,
	["chatStyle"] = "classic",				-- values: "classic" or "im"
	["whisperMode"] = "popout",				-- values: "popout", "inline", "popout_and_inline"
	["removeChatDelay"] = 1,
	["profanityFilter"] = 0,

	-- tooltips
	["UberTooltips"] = 1,
	["alwaysCompareItems"] = 0,

	-- loot
	["autoLootDefault"] = 1,
	["lootUnderMouse"] = 1,
	-- ["autoOpenLootHistory"] = 0,
	-- ["showLootSpam"] = 1,

	-- names
    ["UnitNameEnemyGuardianName"] = 1,		-- default = 1
    ["UnitNameEnemyMinionName"] = 1,		-- default = 1
    ["UnitNameEnemyPetName"] = 1,			-- default = 1
    ["UnitNameEnemyPlayerName"] = 1,		-- default = 1
    ["UnitNameEnemyTotemName"] = 1,			-- default = 1
    ["UnitNameForceHideMinus"] = 0,			-- default = 0
    ["UnitNameFriendlyGuardianName"] = 0,	-- default = 1
    ["UnitNameFriendlyMinionName"] = 0,		-- default = 1
    ["UnitNameFriendlyPetName"] = 0,		-- default = 1
    ["UnitNameFriendlyPlayerName"] = 0,		-- default = 1
    ["UnitNameFriendlySpecialNPCName"] = 0,	-- default = 1
    ["UnitNameFriendlyTotemName"] = 0,		-- default = 1
    ["UnitNameGuildTitle"] = 0,				-- default = 1
    ["UnitNameHostleNPC"] = 1,				-- default = 1
    ["UnitNameInteractiveNPC"] = 1,			-- default = 1
    ["UnitNameNonCombatCreatureName"] = 0,	-- default = 0
    ["UnitNameNPC"] = 0,					-- default = 0
    ["UnitNameOwn"] = 0,					-- default = 0
    ["UnitNamePlayerGuild"] = 0,			-- default = 1
    ["UnitNamePlayerPVPTitle"] = 0,			-- default = 1

	-- ["showVKeyCastbar"] = 1,				-- if the V key display is up for your current target, show the enemy cast bar with the target's health bar in the game field
	-- ["showVKeyCastbarOnlyOnTarget"] = 0,
	-- ["showVKeyCastbarSpellName"] = 1,

	-- action bars
	["alwaysShowActionBars"] = 1,
	["countdownForCooldowns"] = 1,

	-- auras
	["buffDurations"] = 1,

	-- quests
	["autoQuestWatch"] = 1,
	["autoQuestProgress"] = 1,
	-- ["instantQuestText"] = 1,

	-- loss of control
	["lossOfControl"] = 1,
	-- ["lossOfControlDisarm"] = 2,
	-- ["lossOfControlFull"] = 2,
	-- ["lossOfControlInterrupt"] = 2,
	-- ["lossOfControlRoot"] = 2,
	-- ["lossOfControlSilence"] = 2,

	-- arena
	["showArenaEnemyFrames"] = 0,
	["showArenaEnemyPets"] = 0,
}

function E:SetupDefaultsCVars()
	for name, value in next, variables do
		SetCVar(name, value)
	end

	if SetAutoDeclineGuildInvites then
		SetAutoDeclineGuildInvites(true)
	end
end
