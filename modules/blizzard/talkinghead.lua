local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Talking Head
--------------------------------------------------
if (not C.blizzard.talkinghead) then return end

local TalkingHead = {}

local function PlayCurrent(self)
    -- close annoying talking head
    self:CloseImmediately()
end

function TalkingHead:Init()
    -- hooksecurefunc(_G.TalkingHeadFrame, "PlayCurrent", PlayCurrent)
    local TalkingHeadFrame = _G.TalkingHeadFrame
    if TalkingHeadFrame then
        _G.TalkingHeadFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
    end
end

MODULE.TalkingHead = TalkingHead
