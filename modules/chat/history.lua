local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Chat History
--------------------------------------------------
if not C.chat.history.enabled then return end

local database = TaintedChatHistory

local frame_proto = {
    threshold = C.chat.history.threshold or 0,
    isPrinting = false,
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

function frame_proto:Print()
    self.isPrinting = true

    for index = #TaintedChatHistory, 1, -1 do
        local tmp = TaintedChatHistory[index]
        local result = pcall(_G.ChatFrame_MessageEventHandler, _G["ChatFrame1"], tmp.event, unpack(tmp.args))
    end

    self.isPrinting = false
end

function frame_proto:Save(event, ...)
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
    for index = self.threshold, #database do
        table.remove(database, self.threshold)
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
    elseif not self.isPrinting then
        self:Save(event, ...)
    end
end

local history = Mixin(CreateFrame("Frame", "TaintedChatHistory"), frame_proto)
history:RegisterEvent("PLAYER_LOGIN")
history:SetScript("OnEvent", history.OnEvent)
