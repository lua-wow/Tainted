local _, ns = ...
local oUF = ns.oUF or _G.oUF
assert(oUF, "Unable to locate oUF install.")

local E, C = ns.E, ns.C

--------------------------------------------------
-- Colors
-- https://warcraft.wiki.gg/wiki/ColorMixin
--------------------------------------------------
oUF.colors.black = oUF:CreateColor(0, 0, 0)
oUF.colors.white = oUF:CreateColor(1, 1, 1)
oUF.colors.gray = oUF:CreateColor(0.70, 0.70, 0.70)
oUF.colors.green = oUF:CreateColor(0.29, 0.67, 0.30)
oUF.colors.lawngreen = oUF:CreateColor(0.49, 0.99, 0.00)
oUF.colors.yellow = oUF:CreateColor(1.00, 0.82, 0.00)
oUF.colors.orange = oUF:CreateColor(1.00, 0.23, 0.00)
oUF.colors.red = oUF:CreateColor(0.78, 0.25, 0.25)
oUF.colors.aqua = oUF:CreateColor(0.00, 1.00, 1.00)
oUF.colors.fuchsia = oUF:CreateColor(1.00, 0.00, 1.00)

oUF.colors.health = oUF:CreateColor(0.29, 0.68, 0.30)

oUF.colors.disconnected = oUF:CreateColor(0.1, 0.1, 0.1)

oUF.colors.runes = {
	[1] = oUF:CreateColor(0.69, 0.31, 0.31),
	[2] = oUF:CreateColor(0.41, 0.80, 1.00),
	[3] = oUF:CreateColor(0.65, 0.63, 0.35),
	[4] = oUF:CreateColor(0.53, 0.53, 0.93),
	[5] = oUF:CreateColor(0.55, 0.57, 0.61), -- unspec, new char
}

oUF.colors.reaction = {
	[1] = oUF:CreateColor(0.78, 0.25, 0.25), -- Hated
	[2] = oUF:CreateColor(0.78, 0.25, 0.25), -- Hostile
	[3] = oUF:CreateColor(0.78, 0.25, 0.25), -- Unfriendly
	[4] = oUF:CreateColor(0.85, 0.77, 0.36), -- Neutral
	[5] = oUF:CreateColor(0.29, 0.68, 0.30), -- Friendly
	[6] = oUF:CreateColor(0.29, 0.68, 0.30), -- Honored
	[7] = oUF:CreateColor(0.29, 0.68, 0.30), -- Revered
	[8] = oUF:CreateColor(0.29, 0.68, 0.30), -- Exalted
}

do
	local MANA = oUF:CreateColor(0.31, 0.45, 0.63)
	oUF.colors.power[Enum.PowerType.Mana or 0] = MANA
	oUF.colors.power.MANA = MANA
	
	local RAGE = oUF:CreateColor(0.69, 0.31, 0.31)
	oUF.colors.power[Enum.PowerType.Rage or 1] = RAGE
	oUF.colors.power.RAGE = RAGE
	
	local FOCUS = oUF:CreateColor(0.71, 0.43, 0.27)
	oUF.colors.power[Enum.PowerType.Focus or 2] = FOCUS
	oUF.colors.power.FOCUS = FOCUS
	
	local ENERGY = oUF:CreateColor(0.65, 0.63, 0.35)
	oUF.colors.power[Enum.PowerType.Energy or 3] = ENERGY
	oUF.colors.power.ENERGY = ENERGY
	
	local COMBO_POINTS = oUF:CreateColor(0.78, 0.25, 0.25)
	oUF.colors.power[Enum.PowerType.ComboPoints or 4] = COMBO_POINTS
	oUF.colors.power.COMBO_POINTS = COMBO_POINTS
	
	local RUNES = oUF:CreateColor(0.55, 0.57, 0.61)
	oUF.colors.power[Enum.PowerType.Runes or 5] = RUNES
	oUF.colors.power.RUNES = RUNES
	
	local RUNIC_POWER = oUF:CreateColor(0.00, 0.82, 1.00)
	oUF.colors.power[Enum.PowerType.RunicPower or 6] = RUNIC_POWER
	oUF.colors.power.RUNIC_POWER = RUNIC_POWER
	
	local SOUL_SHARDS = oUF:CreateColor(0.50, 0.32, 0.55)
	oUF.colors.power[Enum.PowerType.SoulShards or 7] = SOUL_SHARDS
	oUF.colors.power.SOUL_SHARDS = SOUL_SHARDS
	
	local LUNAR_POWER = oUF:CreateColor(0.93, 0.51, 0.93)
	oUF.colors.power[Enum.PowerType.LunarPower or 8] = LUNAR_POWER
	oUF.colors.power.LUNAR_POWER = LUNAR_POWER
	
	local HOLY_POWER = oUF:CreateColor(0.95, 0.90, 0.60)
	oUF.colors.power[Enum.PowerType.HolyPower or 9] = HOLY_POWER
	oUF.colors.power.HOLY_POWER = HOLY_POWER
	
	local ALTERNATE = oUF:CreateColor(0.00, 1.00, 1.00)
	oUF.colors.power[Enum.PowerType.Alternate or 10] = ALTERNATE
	oUF.colors.power.ALTERNATE = ALTERNATE
	
	local MAELSTROM = oUF:CreateColor(0.00, 0.50, 1.00)
	oUF.colors.power[Enum.PowerType.Maelstrom or 11] = MAELSTROM
	oUF.colors.power.MAELSTROM = MAELSTROM
	
	local CHI = oUF:CreateColor(0.71, 1.00, 0.92)
	oUF.colors.power[Enum.PowerType.Chi or 12] = CHI
	oUF.colors.power.CHI = CHI
	
	local INSANITY = oUF:CreateColor(0.40, 0.00, 0.80)
	oUF.colors.power[Enum.PowerType.Insanity or 13] = INSANITY
	oUF.colors.power.INSANITY = INSANITY
	
	-- local ARCANE_CHARGES = nil
	-- oUF.colors.power[Enum.PowerType.ArcaneCharges or 16] = ARCANE_CHARGES
	-- oUF.colors.power.ARCANE_CHARGES = ARCANE_CHARGES
	
	local FURY = oUF:CreateColor(0.78, 0.26, 0.99)
	oUF.colors.power[Enum.PowerType.Fury or 17] = FURY
	oUF.colors.power.FURY = FURY
	
	local PAIN = oUF:CreateColor(1.00, 0.61, 0.00)
	oUF.colors.power[Enum.PowerType.Pain or 18] = PAIN
	oUF.colors.power.PAIN = PAIN
	
	-- local ESSENCE = oUF:CreateColor(0.00, 0.82, 1.00)
	-- oUF.colors.power[Enum.PowerType.Essence or 19] = ESSENCE
	-- oUF.colors.power.ESSENCE = ESSENCE

	oUF.colors.power.STAGGER = {
		[1] = oUF:CreateColor(0.33, 0.69, 0.33),  -- green
		[2] = oUF:CreateColor(0.85, 0.77, 0.36),  -- yellow
		[3] = oUF:CreateColor(0.69, 0.31, 0.31)   -- red
	}

	oUF.colors.power.FUEL = oUF:CreateColor(0.00, 0.55, 0.50)
	oUF.colors.power.AMMOSLOT = oUF:CreateColor(0.80, 0.60, 0.00)
	-- oUF.colors.power.EBON_MIGHT = nil
	-- oUF.colors.POWER_TYPE_STEAM = oUF:CreateColor(0.55, 0.57, 0.61),
	-- oUF.colors.POWER_TYPE_PYRITE = oUF:CreateColor(0.60, 0.09, 0.17),
	-- oUF.colors.ALTPOWER = oUF:CreateColor(0.00, 1.00, 1.00),
	-- oUF.colors.ANIMA = oUF:CreateColor(0.83, 0.83, 0.83),
end

-- oUF.colors.class = {
-- 	["DRUID"]       = oUF:CreateColor(1.00, 0.49, 0.04),
-- 	["HUNTER"]      = oUF:CreateColor(0.67, 0.83, 0.45),
-- 	["MAGE"]        = oUF:CreateColor(0.25, 0.78, 0.92),
-- 	["PALADIN"]     = oUF:CreateColor(0.96, 0.55, 0.73),
-- 	["PRIEST"]      = oUF:CreateColor(0.99, 0.99, 0.99),
-- 	["ROGUE"]       = oUF:CreateColor(1.00, 0.96, 0.41),
-- 	["SHAMAN"]      = oUF:CreateColor(0.00, 0.44, 0.87),
-- 	["WARLOCK"]     = oUF:CreateColor(0.53, 0.53, 0.93),
-- 	["WARRIOR"]     = oUF:CreateColor(0.78, 0.61, 0.43),
-- 	["DEATHKNIGHT"] = oUF:CreateColor(0.77, 0.12, 0.24),
-- 	["MONK"]        = oUF:CreateColor(0.00, 1.00, 0.59),
-- 	["DEMONHUNTER"] = oUF:CreateColor(0.64, 0.19, 0.79),
-- 	["EVOKER"]      = oUF:CreateColor(0.20, 0.58, 0.50),
-- }

oUF.colors.totems = {
	[1] = oUF:CreateColor(0.78, 0.25, 0.25),
	[2] = oUF:CreateColor(0.78, 0.61, 0.43),
	[3] = oUF:CreateColor(0.25, 0.78, 0.92),
	[4] = oUF:CreateColor(0.99, 0.99, 0.99)
}

oUF.colors.happiness = {
	[1] = oUF:CreateColor(0.69, 0.31, 0.31),
	[2] = oUF:CreateColor(0.65, 0.63, 0.35),
	[3] = oUF:CreateColor(0.33, 0.59, 0.33)
}

oUF.colors.mirror = {
    DEATH		= oUF:CreateColor(1.0, 0.70, 0.0),
	BREATH		= oUF:CreateColor(0.0, 0.50, 1.0),
	EXHAUSTION	= oUF:CreateColor(1.0, 0.90, 0.0),
	FEIGNDEATH	= oUF:CreateColor(1.0, 0.70, 0.0)
}

oUF.colors.stagger = oUF.colors.power.STAGGER

oUF.colors.combopoints = {
	[1] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 1
	[2] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 2
	[3] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 3
	[4] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 4
	[5] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 5
	[6] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 6
	[7] = oUF:CreateColor(0.29, 0.68, 0.30),	-- Combo 7
	[8] = oUF:CreateColor(0.33, 0.73, 1.00)		-- Echoing Reprimand Highlight
}

oUF.colors.roles = {
	["TANK"] = oUF:CreateColor(0.4, 0.7, 1.0),		-- Blue for tanks
	["HEALER"] = oUF:CreateColor(0.0, 1.0, 0.0),	-- Green for healers
	["DAMAGER"] = oUF:CreateColor(1.0, 0.0, 0.0),	-- Red for DPS
	["NONE"] = oUF:CreateColor(1.0, 1.0, 1.0)		-- unknown role
}

-- local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(self.unit)
oUF.colors.difficulty = {
	[0] = oUF:CreateColor(0.70, 0.70, 0.70), -- Trivial
	-- [0] = oUF:CreateColor(0.50, 0.50, 0.50),
	[1] = oUF:CreateColor(0.25, 0.75, 0.25), -- Easy
	[2] = oUF:CreateColor(1.00, 0.82, 0.00), -- Fair
	[3] = oUF:CreateColor(1.00, 0.27, 0.00), -- Difficult
	-- [3] = oUF:CreateColor(1.00, 0.50, 0.25), -- Difficult
	[4] = oUF:CreateColor(1.00, 0.10, 0.10)	-- Impossible
}

oUF.colors.difficulty.impossible = oUF.colors.difficulty[4]
oUF.colors.difficulty.very_difficult = oUF.colors.difficulty[3]
oUF.colors.difficulty.difficult = oUF.colors.difficulty[2]
oUF.colors.difficulty.standard = oUF.colors.difficulty[1]
oUF.colors.difficulty.trivial = oUF.colors.difficulty[0]

-- local classification = UnitClassification(unit)
oUF.colors.classification = {
	-- ["unknown"] = oUF:CreateColor(175, 80, 80),	-- #AF5050
	["worldboss"] = oUF:CreateColor(1.00, 0.10, 0.10),
	["rareelite"] = oUF:CreateColor(1.00, 0.27, 0.00),
	["elite"] = oUF:CreateColor(1.00, 0.65, 0.00),
	["rare"] = oUF:CreateColor(1.00, 0.82, 0.00),
	["normal"] = oUF:CreateColor(1.00, 1.00, 1.00),
	["trivial"] = oUF:CreateColor(0.70, 0.70, 0.70),
	["minus"] = oUF:CreateColor(0.70, 0.70, 0.70)
}

oUF.colors.quality = {}

for k, v in next, Enum.ItemQuality do
	oUF.colors.quality[k] = color
	oUF.colors.quality[v] = color
end

E.colors = oUF.colors
E.CreateColor = oUF.CreateColor

--------------------------------------------------
-- Functions
--------------------------------------------------
-- https://wowpedia.fandom.com/wiki/ColorGradient
local function ColorGradient(perc, ...)
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return E:CreateColor(r, g, b)
	elseif perc <= 0 then
		local r, g, b = ...
		return E:CreateColor(r, g, b)
	end

	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	local r = r1 + (r2 - r1) * relperc
	local g = g1 + (g2 - g1) * relperc
	local b = b1 + (b2 - b1) * relperc
	return E:CreateColor(r, g, b)
end

local function ColorGradient_9(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then
		return E:CreateColor(r3, g3, b3)
	elseif perc <= 0 then
		return E:CreateColor(r1, g1, b1)
	end

	local segment, relperc = math.modf(perc * 2)
	local rr1, rg1, rb1, rr2, rg2, rb2 = select((segment * 3) + 1, r1, g1, b1, r2, g2, b2, r3, g3, b3)

	local r = rr1 + (rr2 - rr1) * relperc
	local g = rg1 + (rg2 - rg1) * relperc
	local b = rb1 + (rb2 - rb1) * relperc
	return E:CreateColor(r, g, b)
end

local function ColorGradient_3(perc, c1, c2, c3)
	if perc >= 1 then
		return c3
	elseif perc <= 0 then
		return c1
	end

	local segment, relperc = math.modf(perc * 2)
	local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, c1.r, c1.g, c1.b, c2.r, c2.g, c2.b, c3.r, c3.g, c3.b)

	local r = r1 + (r2 - r1) * relperc
	local g = g1 + (g2 - g1) * relperc
	local b = b1 + (b2 - b1) * relperc
	return E:CreateColor(r, g, b)
end

function E.ColorGradient(perc, ...)
	local args = select("#", ...)
	if (args == 3) then
		return ColorGradient_3(perc, ...)
	elseif (args == 9) then
		return ColorGradient_9(perc, ...)
	end
	return ColorGradient(perc, ...)
end

-- https://wowpedia.fandom.com/wiki/RGBToHex
function E.RGBToHex(r, g, b)
	r = (r <= 255 and r >= 0) and r or 0
	g = (g <= 255 and g >= 0) and g or 0
	b = (b <= 255 and b >= 0) and b or 0
	return string.format("%02x%02x%02x", r, g, b)
end

-- https://wowpedia.fandom.com/wiki/HexToRGB
function E.HexToRGB(hex)
    if type(hex) == "string" then
         local m = #hex == 3 and 17 or (#hex == 6 and 1 or 0)
         local rhex, ghex, bhex = hex:match('^(%x%x?)(%x%x?)(%x%x?)$')
         if rhex and m > 0 then
              return tonumber(rhex, 16) * m, tonumber(ghex, 16) * m, tonumber(bhex, 16) * m
         end
    end
    return 0, 0, 0
end

local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitCanAttack = _G.UnitCanAttack
local UnitIsPVP = _G.UnitIsPVP
local UnitClass = _G.UnitClass
local UnitReaction = _G.UnitReaction

function E.GetUnitColor(unit)
	-- local color = E:CreateColor(1, 1, 1)

	if UnitPlayerControlled(unit) then
		if UnitCanAttack(unit, "player") then
			-- hostile players are red
			if UnitCanAttack("player", unit) then
				return E.colors.reaction[2]
			end
		elseif UnitCanAttack("player", unit) then
			-- players we can attack but which are not hostile are yellow
			return E.colors.reaction[4]
		elseif UnitIsPVP(unit) then
			-- players we can assist but are PvP flagged are green
			return E.colors.reaction[6]
		else
			local class = select(2, UnitClass(unit))
			return E.colors.class[class]
		end
	else
		local reaction = UnitReaction(unit, "player");
		if reaction then
			return E.colors.reaction[reaction]
		else
			return C.general.border.color
		end
	end
end

function E.GetRelativeDifficultyColor(unitLevel, challengeLevel)
    local diff = challengeLevel - unitLevel
    if diff >= 5 then
        return E.colors.difficulty["impossible"]
    elseif diff >= 3 then
        return E.colors.difficulty["very_difficult"]
    elseif diff >= -4 then
        return E.colors.difficulty["difficult"]
    elseif -diff <= UnitQuestTrivialLevelRange("player") then
        return E.colors.difficulty["standard"]
    else
        return E.colors.difficulty["trivial"]
    end
end
