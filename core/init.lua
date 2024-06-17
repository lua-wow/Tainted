local addon, ns = ...

local frame = CreateFrame("Frame", nil, UIParent)

-- Global
_G[addon] = frame

-- Engine, Config, Assets, Locales, Private
local E, C, A, L, P = frame, {}, {}, {}, {}
ns.E, ns.C, ns.A, ns.L, ns.P = E, C, A, L, P
ns[1], ns[2], ns[2], ns[3], ns[4] = E, C, A, L, P

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
local physicalScreenWidth, physicalScreenHeight = GetPhysicalScreenSize()
local windowed = Display_DisplayModeDropDown and Display_DisplayModeDropDown:windowedmode() or false
local fullscreen = Display_DisplayModeDropDown and Display_DisplayModeDropDown:fullscreenmode() or false

-- Addon
E.name = addon --GetAddOnMetadata(addon, "Title")
E.version = GetAddOnMetadata(addon, "Version")

-- System
E.windowed = windowed
E.fullscreen = fullscreen
E.screenWidth = physicalScreenWidth
E.screenHeight = physicalScreenHeight
E.pixelPerfectScale = math.min(1, math.max(0.3, 768 / physicalScreenHeight))

-- Player
E.Player = {}
E.Player.name = UnitName("player")
E.Player.class = select(2, UnitClass("player"))
E.Player.race = UnitRace("player")
E.Player.realm = GetRealmName()
E.Player.locale = GetLocale()
E.Player.level = UnitLevel("player")
E.Player.faction = select(2, UnitFactionGroup("player"))

-- Game
local wowPatch, wowBuild, wowReleaseDate, tocVersion = GetBuildInfo()
E.WoW = {}
E.WoW.patch = wowPatch
E.WoW.build = wowBuild
E.WoW.releaseDate = wowReleaseDate
E.WoW.tocVersion = tocVersion

-- reference: https://wowpedia.fandom.com/wiki/WOW_PROJECT_ID
E.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
E.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
E.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
E.isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
E.isCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

-- Hider
E.Hider = CreateFrame("Frame", "TaintedHider", UIParent)
E.Hider:Hide()

-- PetHider
E.PetHider = CreateFrame("Frame", "TaintedPetHider", UIParent, "SecureHandlerStateTemplate")
E.PetHider:SetAllPoints()
E.PetHider:SetFrameStrata("LOW")
RegisterStateDriver(E.PetHider, "visibility", "[petbattle] hide; show")
