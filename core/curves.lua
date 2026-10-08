local _, ns = ...
local oUF = ns.oUF or _G.oUF
assert(oUF, "Unable to locate oUF install.")

local E, C = ns.E, ns.C

--------------------------------------------------
-- Curves
-- https://warcraft.wiki.gg/wiki/World_of_Warcraft_API#CurveUtil
-- https://warcraft.wiki.gg/wiki/ScriptObject_CurveObject
-- https://warcraft.wiki.gg/wiki/ScriptObject_ColorCurveObject
--------------------------------------------------
local duration = C_CurveUtil.CreateColorCurve()
duration:SetType(Enum.LuaCurveType.Step)
duration:AddPoint(0, oUF:CreateColor(0.99, 0.31, 0.31, 1))
duration:AddPoint(6, oUF:CreateColor(1.00, 1.00, 1.00, 1))

-- player aura timers: red < 5s, orange < 60s, white
local timer = C_CurveUtil.CreateColorCurve()
timer:SetType(Enum.LuaCurveType.Step)
timer:AddPoint(0, oUF:CreateColor(1.00, 0.08, 0.08, 1))
timer:AddPoint(5, oUF:CreateColor(1.00, 0.65, 0.00, 1))
timer:AddPoint(60, oUF:CreateColor(0.90, 0.90, 0.90, 1))

-- x = dispel type ID (SpellDispelType db2; unverified, taken from ElvUI); Retail oUF only
local dispel
if oUF.colors.dispel then
	dispel = C_CurveUtil.CreateColorCurve()
	dispel:SetType(Enum.LuaCurveType.Step)
	for name, id in next, { None = 0, Magic = 1, Curse = 2, Disease = 3, Poison = 4, Enrage = 9, Bleed = 11 } do
		local color = oUF.colors.dispel[name]
		if color then
			dispel:AddPoint(id, color)
		end
	end
end

local curves = {
	auras = {
		duration = duration,
		timer = timer,
		dispel = dispel
	}
}

oUF.curves = curves
E.curves = curves
