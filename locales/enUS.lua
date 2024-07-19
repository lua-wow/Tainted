local _, ns = ...
local E, L = ns.E, ns.L

L.gold = "|cffffd700g|r"
L.silver = "|cffc7c7cfs|r"
L.copper = "|cffeda55fc|r"

L.offline = "Offline"
L.ghost = "Ghost"

L.merchant = {
    ["notEnoughMoney"] = "You don't have enough money to repair.",
    ["repairCost"] = "Your gear has been repaired for %s.",
    ["junkSold"] = E.isRetail
        and "Your junk items have been sold."
        or "Your junk items have been sold for %s."
}
