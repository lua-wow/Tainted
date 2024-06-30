local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Maps")

function MODULE:Init()
    if not C.maps.enabled then return end
    if (self.WorldMap) then self.WorldMap:Init() end
    if (self.Minimap) then self.Minimap:Init() end
end
