local _, ns = ...
local oUF = ns.oUF or _G.oUF
assert(oUF, "JasjeUI was unable to locate oUF install.")

local E, L = ns.E, ns.L

-- Lua
local format = string.format

-- Blizzard
local TANK = _G.TANK or "Tank"
local HEALER = _G.HEALER or "Healer"
local DAMAGE = _G.DAMAGE or "Damage"
local DEAD = _G.DEAD or "Dead"
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK

local UnitReaction = _G.UnitReaction
local UnitIsPlayer = _G.UnitIsPlayer
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local GetQuestDifficultyColor = _G.GetQuestDifficultyColor
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsRaidOfficer = _G.UnitIsRaidOfficer
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsAFK = _G.UnitIsAFK
local UnitClassification = _G.UnitClassification
local UnitPowerType = _G.UnitPowerType

-- Constants
local GHOST = L.GHOST or "Ghost"

--------------------------------------------------
-- Tags
--------------------------------------------------
local events = {
    -- health
    ["curhp"]           = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["maxhp"]           = "UNIT_MAXHEALTH",
    -- power
    ["curpp"]           = "UNIT_POWER_UPDATE UNIT_POWER_FREQUENT UNIT_MAXPOWER",
    ["maxpp"]           = "UNIT_MAXPOWER",
    -- names
    ["name"]            = "UNIT_NAME_UPDATE",
    ["nameshort"]       = "UNIT_NAME_UPDATE PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE",
    ["namemedium"]      = "UNIT_NAME_UPDATE",
    ["namelarge"]      = "UNIT_NAME_UPDATE",
    -- colors
    ["healthcolor"]     = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["namecolor"]       = "UNIT_POWER_UPDATE",
    ["rolecolor"]       = "RAID_ROSTER_UPDATE GROUP_ROSTER_UPDATE",
    ["hostility"]       = "UNIT_POWER_UPDATE",
    ["difficulty"]      = "UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP",
    -- others
    ["classification"]  = "UNIT_CLASSIFICATION_CHANGED",
    ["dead"]            = "UNIT_HEALTH",
    ["offline"]         = "UNIT_HEALTH UNIT_CONNECTION",
    -- ["afk"]             = "PLAYER_FLAGS_CHANGED",
}

local tags = {
    -- health
    ["curhp"] = function(unit)
        local value = UnitHealth(unit)
        return E.ShortValue(value)
    end,
    ["maxhp"] = function(unit)
        local value = UnitHealthMax(unit)
        return E.ShortValue(value)
    end,
    -- power
    ["curpp"] = function(unit)
        local powerType, powerToken = UnitPowerType(unit)
        local color = oUF.colors.power[powerToken or "MANA"]
        if UnitIsDeadOrGhost(unit) then
            return ""
        end
        local value = UnitPower(unit, powerType)
        return E.ShortValue(value)
    end,
    ["maxpp"] = function(unit)
        local value = UnitPowerMax(unit)
        return E.ShortValue(value)
    end,
    -- names
    ["name"] = function(unit, r)
        local name = UnitName(unit or r) or "???"
        return name
    end,
    ["nameshort"] = function(unit)
        local name = UnitName(unit) or "???"
        local isLeader = UnitIsGroupLeader(unit)
        local isAssistant = UnitIsGroupAssistant(unit) or UnitIsRaidOfficer(unit)
        local assist = isAssistant and "[A] " or ""
        local lead = isLeader and "[L] " or ""
        return E.UTF8Sub(lead .. assist .. name, 10, false)
    end,
    ["namemedium"] = function(unit)
        local value = UnitName(unit) or "???"
        return E.UTF8Sub(value, 15, true)
    end,
    ["namelong"] = function(unit)
        local value = UnitName(unit) or "???"
        return E.UTF8Sub(value, 20, true)
    end,
    -- colors
    ["healthcolor"] = function(unit)
        local color = oUF.colors.health
        -- return "|c" .. color.hex
        return color:GenerateHexColorMarkup()
    end,
    ["namecolor"] = function(unit)
        local reaction = UnitReaction(unit, "player")
        if (UnitIsPlayer(unit)) then
            return _TAGS["raidcolor"](unit)
        elseif (reaction) then
            local color = oUF.colors.reaction[reaction]
            -- return "|c" .. color.hex
            return color:GenerateHexColorMarkup()
        else
            -- return "|c" .. E.colors.white.hex
            return E.colors.white:GenerateHexColorMarkup()
        end
    end,
    ["rolecolor"] = function(unit)
        local role = UnitGroupRolesAssigned(unit)
        local color = oUF.colors.roles[role or "NONE"]
		return color:GenerateHexColorMarkup()
    end,
    ["hostility"] = function(unit)
        local reaction = UnitReaction(unit, "player")
        local color = oUF.colors.reaction[reaction] or E.colors.white
        return color:GenerateHexColorMarkup()
    end,
    ["difficulty"] = function(unit)
        local level = UnitLevel(unit)
        local color = level and GetQuestDifficultyColor(level) or { r = 1, g = 1, b = 1 }
        return ("|cff%.2x%.2x%.2x"):format(color.r * 255, color.g * 255, color.b * 255)
    end,
    -- others
    ["classification"] = function(unit)
        local classification = UnitClassification(unit)
        return E.GetClassification(classification) or ""
    end,
    ["dead"] = function(unit)
        if UnitIsDead(unit) then
			return DEAD
		elseif UnitIsGhost(u) then
			return GHOST
		end
    end,
    -- ["afk"] = function(unit)
    --     if UnitIsAFK(unit) then
    --         return CHAT_FLAG_AFK
    --     end
    -- end
}

for tag, method in next, tags do
    oUF.Tags.Events[tag] = events[tag]
    oUF.Tags.Methods[tag] = method
end
