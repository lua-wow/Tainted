local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Chat History
--------------------------------------------------
if not C.chat.history.enabled then return end

-- Blizzard
local hasanysecretvalues = _G.hasanysecretvalues
local GetPlayerLink = _G.GetPlayerLink
local Ambiguate = _G.Ambiguate

local database = TaintedChatHistory

local frame_proto = {
    threshold = C.chat.history.threshold or 0,
    events = {
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_GUILD",
        -- "CHAT_MSG_GUILD_ACHIEVEMENT",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_SAY",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_YELL",
        
        -- Not sure if I should add this one, it's pretty much always just spam
        -- "CHAT_MSG_CHANNEL",
    }
}

-- Replays as plain lines: running Blizzard's MessageEventHandler from here taints its chat
-- state (HistoryKeeper access IDs), which later breaks live messages with secret senders.
function frame_proto:Print()
    local chatFrame = _G.ChatFrame1

    for index = #database, 1, -1 do
        local tmp = database[index]
        local chatType = tmp.event:sub(10)
        local info = ChatTypeInfo[chatType]
        local fmt = _G["CHAT_" .. chatType .. "_GET"]
        local text, name = tmp.args[1], tmp.args[2]
        if info and fmt and name then
            local sender = GetPlayerLink(name, "[" .. Ambiguate(name, "none") .. "]")
            chatFrame:AddMessage(fmt:format(sender) .. text, info.r, info.g, info.b)
        end
    end
end

function frame_proto:Save(event, ...)
    -- secret payloads (chat lockdown) can't be stored or replayed
    if hasanysecretvalues(...) then return end

    local text = select(1, ...)
    if not text then return end

    local tmp = {
        event = event,
        timestamp = time(),
        args = { ... }
    }
    
    -- store message in the first position of the list
    table.insert(database, 1, tmp)

    -- remove old entries, keeping only a limited number of entries
    while #database > self.threshold do
        table.remove(database)
    end
end

function frame_proto:Init()
    self:UnregisterEvent("PLAYER_LOGIN")

    if not TaintedChatHistory then
        TaintedChatHistory = {}
    end

    database = TaintedChatHistory

    if self.threshold <= 0 then return end

    for _, event in ipairs(self.events) do
        self:RegisterEvent(event)
    end

    self:Print()
end

function frame_proto:OnEvent(event, ...)
    if (event == "PLAYER_LOGIN") then
        self:Init()
    else
        self:Save(event, ...)
    end
end

local history = Mixin(CreateFrame("Frame", "TaintedChatHistoryFrame"), frame_proto)
history:RegisterEvent("PLAYER_LOGIN")
history:SetScript("OnEvent", history.OnEvent)
