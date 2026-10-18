local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Taint
--------------------------------------------------
-- prints blocked/forbidden actions (any addon) with the function involved; off with taintLog = 0
if C.general.taintLog == 0 then return end

local taint_proto = {}

-- the "Interface action failed because of an AddOn" message (UIParent), with what was blocked
function taint_proto:ADDON_ACTION_BLOCKED(...)
    E:print("ADDON_ACTION_BLOCKED", ...)
end

-- the "<addon> has been blocked from an action only available to the Blizzard UI" popup
function taint_proto:ADDON_ACTION_FORBIDDEN(...)
    E:print("ADDON_ACTION_FORBIDDEN", ...)
end

function taint_proto:MACRO_ACTION_BLOCKED(...)
    E:print("MACRO_ACTION_BLOCKED", ...)
end

function taint_proto:MACRO_ACTION_FORBIDDEN(...)
    E:print("MACRO_ACTION_FORBIDDEN", ...)
end

function taint_proto:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

local frame = Mixin(CreateFrame("Frame"), taint_proto)
frame:RegisterEvent("ADDON_ACTION_BLOCKED")
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:RegisterEvent("MACRO_ACTION_BLOCKED")
frame:RegisterEvent("MACRO_ACTION_FORBIDDEN")
frame:SetScript("OnEvent", frame.OnEvent)
