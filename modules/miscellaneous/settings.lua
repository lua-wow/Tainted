local _, ns = ...
local E, C = ns.E, ns.C

local screenshots = ns.ScreenShots and ns.ScreenShots.Frame
if screenshots then
    screenshots:SetOptions(C.miscellaneous.screenshots or {})
end
