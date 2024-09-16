local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local InCombatLockdown = _G.InCombatLockdown
local CreateKeyChordStringFromTable = _G.CreateKeyChordStringFromTable
local GetBindingText = _G.GetBindingText
local GetBindingKeyForAction = _G.GetBindingKeyForAction

-- Mine
local DATATEXT_STRING = "%s"
local VOICE = _G.BINDING_HEADER_VOICE_CHAT or "Voice"
local PUSH_TO_TALK = _G.PUSH_TO_TALK or "Push to Talk"
local VOICE_CHAT_MODE = _G.VOICE_CHAT_MODE or "Voice Chat Mode"
local VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT = _G.VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT or "Push %s to talk"
local VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT_UNBOUND = _G.VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT_UNBOUND or "Push to Talk key not bound."
local VOICE_CHAT_NOTIFICATION_COMMS_MODE_VOICE_ACTIVATED = _G.VOICE_CHAT_NOTIFICATION_COMMS_MODE_VOICE_ACTIVATED or "Open Mic."

local voice_proto = {}

function voice_proto:OnMouseDown(button)
    if InCombatLockdown() then
        E:error(ERR_NOT_IN_COMBAT)
        return
    end

    ToggleChannelFrame()
end

function voice_proto:CreateTooltip(tooltip)
    local mode = C_VoiceChat.GetCommunicationMode()
    if mode == Enum.CommunicationMode.PushToTalk then
        local pushKey = C_VoiceChat.GetPushToTalkBinding()

        tooltip:AddDoubleLine(VOICE_CHAT_MODE, "|cffff0000[" .. PUSH_TO_TALK .. "]|r", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        tooltip:AddLine(" ")

        if pushKey then
            local s = CreateKeyChordStringFromTable(pushKey)
            local t = GetBindingText(s)
            tooltip:AddLine(VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT:format(t), 1.0, 1.0, 1.0)
        else
            tooltip:AddLine(VOICE_CHAT_NOTIFICATION_COMMS_MODE_PTT_UNBOUND, 1.0, 1.0, 1.0)
        end
    elseif mode == Enum.CommunicationMode.OpenMic then
        tooltip:AddDoubleLine(VOICE_CHAT_MODE, "|cffff0000[" .. VOICE_CHAT_NOTIFICATION_COMMS_MODE_VOICE_ACTIVATED .. "]|r", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    local useNotBound = true
    local useParentheses = true
    local bindingText = GetBindingKeyForAction("TOGGLECHATTAB", useNotBound, useParentheses)
    local tip = string.sub(_G.VOICE_CHAT_CHANNEL_MANAGEMENT_TIP, 6)
    if bindingText and bindingText ~= "" then
        tooltip:AddLine(" ")
        tooltip:AddLine(tip:format("", bindingText), 1.0, 1.0, 1.0)
    end
end

function voice_proto:Update()
end

function voice_proto:Enable()
    if self.Text then
        self.Text:SetFormattedText(DATATEXT_STRING, VOICE)
    end

	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Show()
end

function voice_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
    self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Voice Chat", voice_proto)
