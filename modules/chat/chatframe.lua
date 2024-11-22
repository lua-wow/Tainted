local _, ns = ...
local E, C = ns.E, ns.C
local CHAT = E:CreateModule("Chat")

-- Blizzard
local NUM_CHAT_WINDOWS = _G.NUM_CHAT_WINDOWS
local CHAT_FRAME_TEXTURES = _G.CHAT_FRAME_TEXTURES
local GetChannelName = _G.GetChannelName
local ChatEdit_ChooseBoxForSend = _G.ChatEdit_ChooseBoxForSend
local FCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame

-- Mine
local TAB_TEXTURES = {
	"ChatFrame%sTabLeft",
	"ChatFrame%sTabMiddle",
	"ChatFrame%sTabRight",

	"ChatFrame%sTabSelectedLeft",
	"ChatFrame%sTabSelectedMiddle",
	"ChatFrame%sTabSelectedRight",

	"ChatFrame%sTabHighlightLeft",
	"ChatFrame%sTabHighlightMiddle",
	"ChatFrame%sTabHighlightRight",

	"ChatFrame%sTabSelectedLeft",
	"ChatFrame%sTabSelectedMiddle",
	"ChatFrame%sTabSelectedRight",

	"ChatFrame%sMinimizeButton",	-- Classic and Cata
	"ChatFrame%sButtonFrameMinimizeButton",
	"ChatFrame%sButtonFrame",

	"ChatFrame%sEditBoxLeft",
	"ChatFrame%sEditBoxMid",
	"ChatFrame%sEditBoxRight",
}

local EDIT_BOX_TEXTURES = {
	"ChatFrame%sEditBoxFocusLeft",
	"ChatFrame%sEditBoxFocusMid",
	"ChatFrame%sEditBoxFocusRight",
}

local CHAT_CONFIG = {
	[1] = {
		name = "G, S & W",
		default = true,
		groups = {
			"SAY",
			"EMOTE",
			"YELL",
			"GUILD",
			"OFFICER",
			"GUILD_ACHIEVEMENT",
			"ACHIEVEMENT",
			"WHISPER",
			"BN_WHISPER",
			"PARTY",
			"PARTY_LEADER",
			"RAID",
			"RAID_LEADER",
			"RAID_WARNING",
			"INSTANCE_CHAT",
			"INSTANCE_CHAT_LEADER",

			"BG_HORDE",
			"BG_ALLIANCE",
			"BG_NEUTRAL",

			"SYSTEM",

			-- "AFK",
			-- "DND",
			-- "BN_CONVERSATION"
		}
	},
	[2] = {
		name = _G.COMBAT_LOG or "Combat Log",
		default = true,
	},
	[3] = {
		default = true
	},
	[4] = {
		name = _G.OTHER or "Others",
		position = "RIGHT",
		groups = {
			-- Combat
			"COMBAT_XP_GAIN",		 -- Expirence
			"COMBAT_HONOR_GAIN",	 -- Honor
			"COMBAT_FACTION_CHANGE", -- Reputation
			"SKILL",				 -- Skill-ups
			"LOOT",					 -- Item Loot
			"CURRENCY",				 -- Currency
			"MONEY",				 -- Money Loot
			"TRADESKILLS",			 -- Tradeskills

			-- Other
			"SYSTEM",				 -- System
			"ERRORS",				 -- Errors
			"IGNORED",				 -- Ignored
		}
	},
	[5] = {
		name = _G.NPC_NAMES_DROPDOWN_ALL or "NPCs",
		groups = {
			-- Creature Messages
			"MONSTER_SAY",
			"MONSTER_EMOTE",
			"MONSTER_YELL",
			"MONSTER_WHISPER",
			"MONSTER_BOSS_EMOTE",
			"MONSTER_BOSS_WHISPER"
		}
	},
	[6] = {
		name = _G.COMMUNITIES_DEFAULT_CHANNEL_NAME or "General",
		channels = true
	}
}

function CHAT:SetupChatFrame(frame, config)
	if not config then return end

	if not config.default then
		FCF_OpenNewWindow(config.name)
	else
		if config.name then
			FCF_SetWindowName(frame, config.name)
		end
	end

	FCF_SetChatWindowFontSize(nil, frame, 12)

	if config.position == "RIGHT" then
		FCF_UnDockFrame(frame)
	else
		FCF_DockFrame(frame)
		FCF_SetLocked(frame, 1)
	end

	if config.channels then
		if E.isRetail then
			local channels = { EnumerateServerChannels() }
			for k, channel in next, channels do
				-- dont know why, but this works
				C_Timer.After(1, function() ChatFrame_SetChannelEnabled(frame, channel, true) end)
			end
		end

		-- Adjust Chat Colors
		ChangeChatColor("CHANNEL1", 0.76, 0.90, 0.91)
		ChangeChatColor("CHANNEL2", 0.91, 0.62, 0.47)
		ChangeChatColor("CHANNEL3", 0.91, 0.89, 0.47)
		ChangeChatColor("CHANNEL4", 0.91, 0.89, 0.47)
		ChangeChatColor("CHANNEL5", 0.00, 0.89, 0.47)
		ChangeChatColor("CHANNEL6", 0.00, 0.89, 0.00)
	else
		-- remove channels like Trade, Looking For Group, etc.
		ChatFrame_RemoveAllChannels(frame)
	end

	if config.groups then
		ChatFrame_RemoveAllMessageGroups(frame)

		for k, group in next, config.groups do
			ChatFrame_AddMessageGroup(frame, group)
		end
	else
		-- remove channels like Trade, Looking For Group, etc.
		ChatFrame_RemoveAllMessageGroups(frame)
	end
end

function CHAT:Reset()
	local channels = { EnumerateServerChannels() }
	if channels and (#channels == 0) then
		-- restart this function until we are able to query public channels
		C_Timer.After(1, CHAT.Reset)
		return
	end

	-- reset chat frames
	FCF_ResetChatWindows()
	DEFAULT_CHAT_FRAME:SetUserPlaced(true)

	for index = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. index]
		local config = CHAT_CONFIG[index]
		CHAT:SetupChatFrame(frame, config)

		if (index == 4) then
			local tab = frame.Tab or _G[frame:GetName() .. "Tab"]
			tab:ClearAllPoints()

			FCF_RestorePositionAndDimensions(frame)
			FCF_SetTabPosition(frame, 0)
		end
	end

	local ChatFrame1 = _G["ChatFrame1"]
	local ChatFrame1EditBox = _G["ChatFrame1EditBox"]

	CHAT.SetChatFramePosition(ChatFrame1)

	FCF_SelectDockFrame(ChatFrame1)

	-- fix a editbox texture
	ChatEdit_ActivateChat(ChatFrame1EditBox)
	ChatEdit_DeactivateChat(ChatFrame1EditBox)
end

local Dock = function(frame)
	FCF_DockFrame(frame, #FCFDock_GetChatFrames(GENERAL_CHAT_DOCK) + 1, true)
end

local Undock = function(frame)
	FCF_UnDockFrame(frame)
	FCF_SetTabPosition(frame, 0)
end

function CHAT:StyleTemporaryChatFrame()
	local frame = FCF_GetCurrentChatFrame()
	CHAT:Style(frame)
end

-- Update editbox border color
function CHAT:UpdateEditBoxBorderColor()
	local editBox = ChatEdit_ChooseBoxForSend()
	local chatType = editBox:GetAttribute("chatType")
	local channel = editBox:GetAttribute("channelTarget")

	if editBox.Backdrop then
		if (chatType == "CHANNEL") then
			local id = GetChannelName(channel)
			if (id == 0) then
				local color = unpack(C.general.border.color)
				editBox.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
			else
				local info = ChatTypeInfo[chatType .. id]
				editBox.Backdrop:SetBackdropBorderColor(info.r, info.g, info.b, 1)
			end
		else
			local info = ChatTypeInfo[chatType]
			editBox.Backdrop:SetBackdropBorderColor(info.r, info.g, info.b, 1)
		end
	end
end

function CHAT:OnMouseWheel(delta)
	if (delta < 0) then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		else
			for i = 1, (C.chat.ScrollByX or 3) do
				self:ScrollDown()
			end
		end
	elseif (delta > 0) then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		else
			for i = 1, (C.chat.ScrollByX or 3) do
				self:ScrollUp()
			end
		end
	end
end

function CHAT:SetChatFramePosition()
	local frame = self
	local id = frame:GetID()
	local name = frame:GetName()
	
	local Tab = frame.Tab or _G[name .. "Tab"]
	local IsMovable = frame:IsMovable()

	if Tab:IsShown() then
		if IsRightChatFound and not frame.isDocked then
			Dock(frame)
		end

		if id == 1 then
			local anchor = _G["TaintedChatLeft"]
			frame:SetParent(anchor)
			frame:SetMovable(false)
			frame:SetUserPlaced(true)
			frame:ClearAllPoints()
			frame:SetPoint("TOP", anchor.Tab, "BOTTOM", 0, -5)
			frame:SetPoint("LEFT", anchor, "LEFT", C.chat.margin, 0)
			frame:SetPoint("RIGHT", anchor, "RIGHT", -16, 0)
			frame:SetPoint("BOTTOM", anchor.DataText, "TOP", 0, 8)

			if E.isRetail then
				hooksecurefunc(frame, "SetPoint", function(f)
					frame:SetPointBase("TOP", anchor.Tab, "BOTTOM", 0, -5)
					frame:SetPointBase("LEFT", anchor, "LEFT", C.chat.margin, 0)
					frame:SetPointBase("RIGHT", anchor, "RIGHT", -16, 0)
					frame:SetPointBase("BOTTOM", anchor.DataText, "TOP", 0, 8)
				end)
			end
		elseif (id == 4) then
			local anchor = _G["TaintedChatRight"]
			frame:SetParent(anchor)
			frame:ClearAllPoints()
			frame:SetPoint("TOP", anchor.Tab, "BOTTOM", 0, -5)
			frame:SetPoint("LEFT", anchor, "LEFT", C.chat.margin, 0)
			frame:SetPoint("RIGHT", anchor, "RIGHT", -16, 0)
			frame:SetPoint("BOTTOM", anchor.DataText, "TOP", 0, 8)
			frame:SetMovable(true) -- the frame needs to be movable to use 'SetUserPlaced'
			frame:SetUserPlaced(true)
			frame:SetMovable(false)

			-- if E.isRetail then
			-- 	hooksecurefunc(frame, "SetPoint", function(f)
			-- 		frame:SetPointBase("TOP", anchor.Tab, "BOTTOM", 0, -5)
			-- 		frame:SetPointBase("LEFT", anchor, "LEFT", C.chat.margin, 0)
			-- 		frame:SetPointBase("RIGHT", anchor, "RIGHT", -16, 0)
			-- 		frame:SetPointBase("BOTTOM", anchor.DataText, "TOP", 0, 8)
			-- 	end)
			-- end
		end

		FCF_SavePositionAndDimensions(frame)
	end
end

-- TESTING CMD : /run BNToastFrame:AddToast(BN_TOAST_TYPE_ONLINE, 1)
function CHAT:AddToast()
	if not self.__skinned then
		
		self:ClearBackdrop()
		self:CreateBackdrop()

		if self.CloseButton then
			self.CloseButton:SkinCloseButton()
		end
		
		local glowFrame = _G.BNToastFrameGlowFrame
		if glowFrame then
			glowFrame:Hide()
		end

		self.__skinned = true
	end

	local owner = _G["TaintedExperienceBar"] or _G["TaintedChatLeft"]
	if owner then
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", 0, 5)
	end
end

function CHAT:HideTextures(frame)
	local id = frame:GetID()
	local name = frame:GetName()

	-- hide textures
	for _, texture in next, CHAT_FRAME_TEXTURES do
		local obj = _G[name .. texture]
		if obj and obj:GetObjectType() == "Texture" then
			obj:SetTexture(nil)
			obj:Hide()
		else
			E.error(name .. "." .. texture .. "  is not a texture.")
		end
	end

	-- remove default texture from tab
	for _, s in next, TAB_TEXTURES do
		local t = _G[s:format(id)]
		if t then
			t:Kill()
		end
	end

	-- remove default texture from edit box
	for _, s in next, EDIT_BOX_TEXTURES do
		local t = _G[s:format(id)]
		if t then
			t:Kill()
		end
	end
end

function CHAT:Style(frame)
	if frame.__styled then return end
	
	local fontObject = E.GetFont(C.chat.font)
	local font, fontSize, fontFlag = fontObject:GetFont()
	
	local id = frame:GetID()
	local name = frame:GetName()

	-- local Tab = _G[name .. "Tab"]
	-- local Scroll = frame.ScrollBar
	-- local ScrollBottom = frame.ScrollToBottomButton
	-- local ScrollTex = _G[name .."ThumbTexture"]
	-- local TabFont, TabFontSize, TabFontFlags = GetTabFont:GetFont()
	
	local anchor = self.Left

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetFading(C.chat.text.fading.enabled)
	frame:SetTimeVisible(C.chat.text.fading.timer or 15)
	
	local Tab = _G[name .. "Tab"]
	if Tab then
		-- remove default tab textures
		Tab:StripTextures()
		Tab:SetAlpha(1)
		Tab.SetAlpha = UIFrameFadeRemoveFrame
		
		local TabText = Tab.Text or _G[name .."TabText"]
		if TabText then
			TabText:SetFont(font, fontSize, fontFlag)
			TabText.SetFont = function() end
			TabText.SetFontObject = function() end
		end
		
		local ConversationIcon = Tab.conversationIcon or _G[name .. "TabConversationIcon"]
		if ConversationIcon then
			ConversationIcon:Kill()
		end
	end
	
	local ScrollBar = frame.ScrollBar
	if ScrollBar then
		ScrollBar:Kill()
	end
		
	local ScrollToBottomButton = frame.ScrollToBottomButton
	if ScrollToBottomButton then
		ScrollToBottomButton:Kill()
	end
	
	-- move the edit box
	local EditBox = frame.editBox or _G[name .."EditBox"]
	EditBox:ClearAllPoints()
	EditBox:SetAllPoints(self.Left.DataText)
	EditBox:SetAltArrowKeyMode(false) -- disable alt key usage
	EditBox:Hide() -- hide editbox on login
	EditBox:StripTextures()
	EditBox:CreateBackdrop()

	-- hide editbox instead of fading
	EditBox:HookScript("OnEditFocusLost", function(self)
		self:Hide()
	end)

	self:HideTextures(frame)
	self.SetChatFramePosition(frame)

	-- Mouse Wheel
	frame:SetScript("OnMouseWheel", self.OnMouseWheel)

	frame.__styled = true
end

function CHAT:Setup()
	local frameLevel = self.Left.Tab:GetFrameLevel()

	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		local tab = _G["ChatFrame" .. i .. "Tab"]

		tab:SetAlpha(0)
		tab:SetFrameLevel(frameLevel + 1)
		tab.noMouseAlpha = 0

		-- frame.BaseAddMessage = frame.AddMessage;
		-- frame.AddMessage = ChatFrame_AddMessage;

		self:Style(frame)

		if (i == 2) then
			if _G.CombatLogQuickButtonFrame_Custom then
				_G.CombatLogQuickButtonFrame_Custom:StripTextures()
			end
		end

		frame:SetScript("OnEnter", function(x)
			self.CopyButton:SetAlpha(1)
		end)
	
		frame:SetScript("OnLeave", function(x)
			self.CopyButton:SetAlpha(0)
		end)
	end

	-- local ChatConfigFrameDefaultButton = _G.ChatConfigFrameDefaultButton
	-- if ChatConfigFrameDefaultButton then
	-- 	ChatConfigFrameDefaultButton:Kill()
	-- end

	local QuickJoinToastButton = _G.QuickJoinToastButton
    if QuickJoinToastButton then
		QuickJoinToastButton:Kill()
		-- QuickJoinToastButton:ClearAllPoints()
		-- QuickJoinToastButton:SetPoint("BOTTOMLEFT", self.Left, "TOPLEFT", 0, 5)
	end
	
	do
		local button = _G.ChatFrameChannelButton
		button:Kill()
		-- if button then
		-- 	button:SetParent(self.Left)
		-- 	button:ClearAllPoints()
		-- 	button:SetPoint("TOPLEFT", self.Left, "TOPRIGHT", 5, 0)
		-- 	button:SetSize(20, 20)
		-- 	button:StripTextures()
		-- 	button:CreateBackdrop()

		-- 	local texture = button:CreateTexture(nil, "ARTWORK")
		-- 	texture:SetPoint("CENTER", button, 1, 1)  -- Make the texture fill the button
		-- 	texture:SetSize(20, 20)
		-- 	texture:SetAtlas("chatframe-button-icon-voicechat", false)
		-- end
    end
	
	do
		local button = _G.ChatFrameMenuButton
		button:Kill()
		-- if button then
		-- 	button:SetParent(self.Left)
		-- 	button:ClearAllPoints()
		-- 	button:SetPoint("TOP", _G.ChatFrameChannelButton, "BOTTOM", 0, -5)
		-- 	button:SetSize(20, 20)
		-- 	button:StripTextures()
		-- 	button:CreateBackdrop()

		-- 	local texture = button:CreateTexture(nil, "ARTWORK")
		-- 	texture:SetPoint("CENTER", button)  -- Make the texture fill the button
		-- 	texture:SetSize(20, 20)
		-- 	texture:SetAtlas("voicechat-icon-textchat-silenced", false)
		-- 	texture:SetDesaturation(0.90)
		-- 	texture:SetVertexColor(1, 1, 1)
		-- end
    end

	local VoiceChatPromptActivateChannel = _G.VoiceChatPromptActivateChannel
	if VoiceChatPromptActivateChannel then
		-- VoiceChatPromptActivateChannel:ClearAllPoints()
		-- VoiceChatPromptActivateChannel:SetPoint(unpack(Chat.VoiceAlertPosition))
		-- VoiceChatPromptActivateChannel:CreateBackdrop()
		-- VoiceChatPromptActivateChannel.AcceptButton:SkinButton()
		-- VoiceChatPromptActivateChannel.CloseButton:SkinCloseButton()
		-- VoiceChatPromptActivateChannel.ClearAllPoints = function() end
		-- VoiceChatPromptActivateChannel.SetPoint = function() end
	end
end

function CHAT:CreateBackground(side)
	local margin = C.chat.margin or 5

	local element = CreateFrame("Frame", "TaintedChat" .. side, UIParent)
	element:SetWidth(C.chat.width or 450)
	element:SetHeight(C.chat.height or 205)
	element:SetFrameLevel(1)
	element:SetFrameStrata("BACKGROUND")
	element:CreateBackdrop("transparent")

	local tab = CreateFrame("Frame", "$parentTab", element)
	tab:SetPoint("TOP", element, "TOP", 0, -margin)
	tab:SetPoint("LEFT", element, "LEFT", margin, 0)
	tab:SetPoint("RIGHT", element, "RIGHT", -margin, 0)
	tab:SetHeight(21)
	tab:SetFrameLevel(5)
	tab:CreateBackdrop()

	local datatext = CreateFrame("Frame", "$parentDataText", element)
	datatext:SetPoint("BOTTOM", element, "BOTTOM", 0, margin)
	datatext:SetPoint("LEFT", element, "LEFT", margin, 0)
	datatext:SetPoint("RIGHT", element, "RIGHT", -margin, 0)
	datatext:SetHeight(21)
	datatext:SetFrameLevel(5)
	datatext:CreateBackdrop()

	element.Tab = tab
	element.DataText = datatext
	return element
end

function CHAT:CreateChatFrame()
	local margin = C.general.margin or 10

	self.Left = self:CreateBackground("Left")
	self.Left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", margin, margin)

	self.Right = self:CreateBackground("Right")
	self.Right:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -margin, margin)
end

function CHAT:Init()
    self:CreateChatFrame()
	self:CreateCopyButton()
	self:Setup()
	self:EnableHiperlinkFilter()

	-- Set default position for Voice Activation Alert
	self.VoiceAlertPosition = { "BOTTOMLEFT", self.Left, "TOPLEFT", 0, 12 }

	hooksecurefunc("ChatEdit_UpdateHeader", self.UpdateEditBoxBorderColor)
	hooksecurefunc("FCF_OpenTemporaryWindow", self.StyleTemporaryChatFrame)
	hooksecurefunc("FCF_RestorePositionAndDimensions", self.SetChatFramePosition)
	-- hooksecurefunc("FCF_SavePositionAndDimensions", Chat.SaveChatFramePositionAndDimensions)
	-- hooksecurefunc("FCFTab_UpdateAlpha", Chat.NoMouseAlpha)
	hooksecurefunc(BNToastFrame, "AddToast", self.AddToast)
end
