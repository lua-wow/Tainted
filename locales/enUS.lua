local _, ns = ...
local E, L = ns.E, ns.L

-- Blizard
local INVSLOT_HEAD = _G.INVSLOT_HEAD or 1
local INVSLOT_NECK = _G.INVSLOT_NECK or 2
local INVSLOT_SHOULDER = _G.INVSLOT_SHOULDER or 3
local INVSLOT_BODY = _G.INVSLOT_BODY or 4
local INVSLOT_CHEST = _G.INVSLOT_CHEST or 5
local INVSLOT_WAIST = _G.INVSLOT_WAIST or 6
local INVSLOT_LEGS = _G.INVSLOT_LEGS or 7
local INVSLOT_FEET = _G.INVSLOT_FEET or 8
local INVSLOT_WRIST = _G.INVSLOT_WRIST or 9
local INVSLOT_HAND = _G.INVSLOT_HAND or 10
local INVSLOT_FINGER1 = _G.INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2 = _G.INVSLOT_FINGER2 or 12
local INVSLOT_TRINKET1 = _G.INVSLOT_TRINKET1 or 13
local INVSLOT_TRINKET2 = _G.INVSLOT_TRINKET2 or 14
local INVSLOT_BACK = _G.INVSLOT_BACK or 15
local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND = _G.INVSLOT_OFFHAND or 15
local INVSLOT_RANGED = _G.INVSLOT_RANGED or 18
local INVSLOT_TABARD = _G.INVSLOT_TABARD or 19

-- general
L.gold = "|cffffd700g|r"
L.silver = "|cffc7c7cfs|r"
L.copper = "|cffeda55fc|r"

L.OFFLINE = "Offline"
L.GHOST = "Ghost"

-- merchant
L.merchant = {
    ["notEnoughMoney"] = "You don't have enough money to repair.",
    ["repairCost"] = "Your gear has been repaired for %s.",
    ["junkSold"] = E.isRetail
        and "Your junk items have been sold."
        or "Your junk items have been sold for %s."
}

-- tooltips
L.PET_HAPINESS = "Pet is %s"
L.PET_DAMAGE = "Pet is doing %s damage"
L.PET_LOYALTY = "Pet is %s loyalty"

-- datatexts
L.BANK = _G.BANK or "Bank"
L.BAG = _G.BAGSLOT or "Bag"
L.BAG_SLOTS = {
    [0] = _G.BAG_NAME_BACKPACK or "Backpack",
    [1] = _G.BAG_NAME_BAG_1 or "Bag 1",
    [2] = _G.BAG_NAME_BAG_2 or "Bag 2",
    [3] = _G.BAG_NAME_BAG_3 or "Bag 3",
    [4] = _G.BAG_NAME_BAG_4 or "Bag 4",
    [5] = _G.BAG_NAME_BAG_4 or "Reagents",
}
L.BAGS = _G.HUD_EDIT_MODE_BAGS_LABEL or "Bags"

L.CHARACTER = _G.CHARACTER or "Character"
L.CURRENCY = _G.CURRENCY or "Currency"
L.DEFICIT = "Deficit"
L.EARNED = "Earned"
L.FREE = "Free"
L.GUILD = _G.GUILD or "Guild"
L.HOME = _G.HOME or "Home"
L.INSTANCE = _G.INSTANCE or "Instance"
L.INSTANCES = "Saved Instances"
L.KEY_STONES = "Key Stones"
L.LOCAL_TIME = "Local"                                                                                                                                                                                                                                                                                                                                                                                                                      
L.MAP = _G.WORLD_MAP or "Map"
L.MEMBERS = "Members"
L.NO_GUILD = "No Guild"
L.PRIMARY_STATS = "Primary Stats"
L.PROFIT = "Profit"
L.REAGENTS = "Reagents"
L.UNKNOWN = _G.UNKNOWN or "Unknown"
L.SECONDARY_STATS = "Secondary Stats"
L.SERVER = "Server"
L.SERVER_TIME = "Server"
L.SESSION = "Session"
L.SLOTS = {
    [INVSLOT_HEAD] = "Head",
    [INVSLOT_NECK] = "Neck",
    [INVSLOT_SHOULDER] = "Shoulder",
    [INVSLOT_BODY] = "Shirt",
    [INVSLOT_CHEST] = "Chest",
    [INVSLOT_WAIST] = "Waist",
    [INVSLOT_LEGS] = "Legs",
    [INVSLOT_FEET] = "Feet",
    [INVSLOT_WRIST] = "Wrist",
    [INVSLOT_HAND] = "Hands",
    [INVSLOT_FINGER1] = "Finger 1",
    [INVSLOT_FINGER2] = "Finger 2",
    [INVSLOT_TRINKET1] = "Trinket 1",
    [INVSLOT_TRINKET2] = "Trinket 2",
    [INVSLOT_BACK] = "Back",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND] = "Off Hand",
    [INVSLOT_RANGED] = "Ranged",
    [INVSLOT_TABARD] = "Tabard"
}
L.SPENT = "Spent"
L.TIME = "Time"
L.TOTAL_GOLD = "Total Gold"
L.TOTAL = _G.TOTAL or "Total"
L.USED = "Used"
L.WORLD = _G.WORLD or "World"
L.WORLD_BOSSES = "World Bosses"
L.WARBAND = "Warband"
L.ZONE = "Zone"
L.ZONE_MAP = _G.BATTLEFIELD_MINIMAP or "Zone Map"

L.TOGGLE_BAGS_TEXT = "Click to Toggle Bags"
L.TOGGLE_BAGS_BAR_TEXT = "Shift + Click to Toggle Bags Bar"
L.TOGGLE_CHARACTER_TEXT = "Click to Toggle Character Info"
L.TOGGLE_GUILD_TEXT = "Click to Toggle Guild"
L.HOLD_SHIFT_TO_SHOW_ALL_CHARACTERS = "Hold Shift to show all characters"
