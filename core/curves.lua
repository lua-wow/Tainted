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

local curves = {
	auras = {
		duration = duration
	}
}

oUF.curves = curves
E.curves = curves
