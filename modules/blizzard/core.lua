local _, ns = ...
local E = ns.E

local BLIZZARD = E:CreateModule("Blizzard")

-- one failing tweak reports through the error handler; the rest still load
local function Load(tweak, method)
    if (tweak and tweak[method]) then E:Call(tweak[method], tweak) end
end

function BLIZZARD:Init()
    Load(self, "UpdateFramerateFrame")
    Load(self, "UpdateQueueStatusFrame")
    Load(self.Durability, "Init")
    Load(self.Ghost, "Init")
    Load(self.MirrorTimer, "Init")
    Load(self.TalkingHead, "Init")
    Load(self.UIWidgets, "Init")
    Load(self.RaidUtility, "Load")
    Load(self.ObjectiveTracker, "Load")
end
