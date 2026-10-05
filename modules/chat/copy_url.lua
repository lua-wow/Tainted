
local _, ns = ...
local E, C = ns.E, ns.C
local CHAT = E:GetModule("Chat")

-- Blizzard
local SetHyperlink = ItemRefTooltip.SetHyperlink
local ChooseBoxForSend = _G.ChatFrameUtil.ChooseBoxForSend
local ActivateChat = _G.ChatFrameUtil.ActivateChat
local AddMessageEventFilter = _G.ChatFrameUtil.AddMessageEventFilter

-- Lua
local gsub = string.gsub
local sub = string.sub

local CreatePattner = function(url)
	local color = C.chat.link.color
	if C.chat.link.brackets then
		return color:WrapTextInColorCode("|Hurl:" .. url .. "|h[" .. url .. "]|h") .. " "
	end
	return color:WrapTextInColorCode("|Hurl:" .. url .. "|h" .. url .. "|h") .. " "
end

function CHAT:HyperlinkFilter(event, msg, ...)
	local text, replacements 
	
	text, replacements = gsub(msg, "(%a+)://(%S+)%s?", CreatePattner("%1://%2"))
	if (replacements > 0) then
		return false, text, ...
	end

	text, replacements = gsub(msg, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", CreatePattner("www.%1.%2"))
	if (replacements > 0) then
		return false, text, ...
	end

	text, replacements = gsub(msg, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", CreatePattner("%1@%2%3%4"))
	if (replacements > 0) then
		return false, text, ...
	end
end

function CHAT:SetHyperlink(data, ...)
	if (data and sub(data, 1, 3) == "url") then
		local ChatFrameEditBox = ChooseBoxForSend()

		local link = data:sub(5)

		if (not ChatFrameEditBox:IsShown()) then
			ActivateChat(ChatFrameEditBox)
		end

		ChatFrameEditBox:Insert(link)
		ChatFrameEditBox:HighlightText()
		link = nil
	else
		SetHyperlink(self, data, ...)
	end
end

function CHAT:EnableHiperlinkFilter()
	AddMessageEventFilter("CHAT_MSG_CHANNEL", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_YELL", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_GUILD", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_OFFICER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_PARTY", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_RAID", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_RAID_LEADER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_SAY", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_WHISPER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_BN_WHISPER", self.HyperlinkFilter)
	AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", self.HyperlinkFilter)

	ItemRefTooltip.SetHyperlink = self.SetHyperlink
end
