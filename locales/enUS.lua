local _, ns = ...
local E, L = ns.E, ns.L

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
