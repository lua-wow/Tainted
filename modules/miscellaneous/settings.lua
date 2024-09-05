local _, ns = ...
local E, C = ns.E, ns.C

local screenshots = ns.ScreenShots
if screenshots then
    screenshots:Configure(C.miscellaneous.screenshots or {})
end
