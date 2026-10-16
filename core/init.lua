local addon, ns = ...

local frame = CreateFrame("Frame", nil, UIParent)

-- Global
_G[addon] = frame

-- Engine, Config, Assets, Locales, Private
local E, C, A, L, P = frame, {}, {}, {}, {}
ns.E, ns.C, ns.A, ns.L, ns.P = E, C, A, L, P
ns[1], ns[2], ns[3], ns[4], ns[5] = E, C, A, L, P

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

-- Addon
E.addon = addon --GetAddOnMetadata(addon, "Title")
E.version = GetAddOnMetadata(addon, "Version")

-- Player
E.name = UnitName("player")
E.class = select(2, UnitClass("player"))
E.realm = GetRealmName()
E.locale = GetLocale()

-- Game
local wowPatch, wowBuild, wowReleaseDate, tocVersion = GetBuildInfo()
E.patch = wowPatch
E.build = wowBuild
E.releaseDate = wowReleaseDate
E.tocVersion = tocVersion

-- reference: https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID
E.isStandard = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
E.isVanilla = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
E.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
E.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
E.isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
E.isMists = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
E.isPlunderstorm = (WOW_PROJECT_ID == WOW_PROJECT_WOWLABS)
E.isCamelot = (WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)

-- game type families, as in TOC [AllowLoadGameType mainline/classic]
E.isClassic = (E.isVanilla or E.isTBC or E.isWrath or E.isCata or E.isMists)
E.isMainline = not E.isClassic

-- Hider
E.Hider = CreateFrame("Frame", "TaintedHider", UIParent)
-- needs a rect, or frames anchored to hidden frames (e.g. Classic Era MicroMenuContainer) return nil from GetCenter()
E.Hider:SetAllPoints()
E.Hider:Hide()

-- PetHider
E.PetHider = CreateFrame("Frame", "TaintedPetHider", UIParent, "SecureHandlerStateTemplate")
E.PetHider:SetAllPoints()
E.PetHider:SetFrameStrata("LOW")
RegisterStateDriver(E.PetHider, "visibility", "[petbattle] hide; show")
