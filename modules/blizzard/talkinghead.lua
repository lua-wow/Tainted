local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Talking Head
--------------------------------------------------
if (not C.blizzard.talkinghead) then return end

local TalkingHeadFrame = _G.TalkingHeadFrame

local TalkingHead = {}

local function PlayCurrent(self)
    -- close annoying talking head
    self:CloseImmediately()
end

function TalkingHead:Init()
    -- hooksecurefunc(_G.TalkingHeadFrame, "PlayCurrent", PlayCurrent)
    _G.TalkingHeadFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
end

MODULE.TalkingHead = TalkingHead
