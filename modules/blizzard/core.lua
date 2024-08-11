local _, ns = ...
local E = ns.E

local BLIZZARD = E:CreateModule("Blizzard")

function BLIZZARD:Init()
    self:UpdateFramerateFrame()
    self:UpdateQueueStatusFrame()
    if (self.Ghost) then self.Ghost:Init() end
    if (self.MirrorTimer) then self.MirrorTimer:Init() end
    if (self.TalkingHead) then self.TalkingHead:Init() end
    if (self.UIWidgets) then self.UIWidgets:Init() end
end
