local _, ns = ...
local E, C = ns.E, ns.C
local CHAT = E:CreateModule("Chat")

-- Blizzard
local MAX_CHAT_WINDOWS = _G.Constants.ChatFrameConstants.MaxChatWindows
local CHAT_FRAME_TEXTURES = _G.CHAT_FRAME_TEXTURES
local CHAT_FRAMES = _G.CHAT_FRAMES
local GetChannelName = _G.GetChannelName
local ActivateChat = _G.ChatFrameUtil.ActivateChat
local DeactivateChat = _G.ChatFrameUtil.DeactivateChat

-- Mine
local RESET_ATTEMPTS = 10

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
	[3] = false, -- Voice window, left to Blizzard
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

function CHAT:SetupChatFrame(index, config, channels)
	local frame
	if config.default then
		frame = _G["ChatFrame" .. index]
		if config.name then
			FCF_SetWindowName(frame, config.name)
		end
	else
		frame = FCF_OpenNewWindow(config.name)
		if not frame then return end
	end

	FCF_SetChatWindowFontSize(nil, frame, 12)

	if config.position == "RIGHT" then
		FCF_UnDockFrame(frame)

		local tab = frame.Tab or _G[frame:GetName() .. "Tab"]
		tab:ClearAllPoints()

		FCF_RestorePositionAndDimensions(frame)
		FCF_SetTabPosition(frame, 0)
	else
		FCF_DockFrame(frame)
		FCF_SetLocked(frame, 1)
	end

	if config.channels then
		-- still joined after FCF_ResetChatWindows, only the windows lost them
		for _, channel in next, channels do
			frame:AddChannel(channel)
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
		frame:RemoveAllChannels()
	end

	if config.groups then
		frame:RemoveAllMessageGroups()

		for k, group in next, config.groups do
			frame:AddMessageGroup(group)
		end
	else
		-- remove channels like Trade, Looking For Group, etc.
		frame:RemoveAllMessageGroups()
	end
end

function CHAT:Reset(attempt)
	attempt = attempt or 1

	local channels = { EnumerateServerChannels() }
	if (#channels == 0) then
		-- public channels are not queryable right after login
		if (attempt < RESET_ATTEMPTS) then
			C_Timer.After(1, function() CHAT:Reset(attempt + 1) end)
		else
			E:print("Chat reset postponed: no public channels found.")
		end
		return
	end

	-- reset chat frames
	FCF_ResetChatWindows()
	DEFAULT_CHAT_FRAME:SetUserPlaced(true)

	-- in order: FCF_OpenNewWindow hands out the next free frame
	for index = 1, MAX_CHAT_WINDOWS do
		local config = CHAT_CONFIG[index]
		if config then
			CHAT:SetupChatFrame(index, config, channels)
		end
	end

	local ChatFrame1 = _G["ChatFrame1"]
	local ChatFrame1EditBox = _G["ChatFrame1EditBox"]

	CHAT.PositionChat(ChatFrame1)

	FCF_SelectDockFrame(ChatFrame1)

	-- fix a editbox texture
	ActivateChat(ChatFrame1EditBox)
	DeactivateChat(ChatFrame1EditBox)

	E.db.chat = true
end

-- A post-hook can't see FCF_OpenTemporaryWindow's return value, so style whatever is new.
-- Reused temporary frames are already styled.
function CHAT.StyleTemporaryChatFrames()
	for _, name in next, CHAT_FRAMES do
		local frame = _G[name]
		if frame and (not frame.__styled) then
			CHAT:Style(frame)
		end
	end
end

-- Keep tabs fully visible: Blizzard fades tabs towards these values.
function CHAT.UpdateTabAlpha(frame)
	local tab = _G[frame:GetName() .. "Tab"]
	tab.mouseOverAlpha = 1
	tab.noMouseAlpha = 1
	tab:SetAlpha(1)
end

-- Update editbox border color
function CHAT.UpdateEditBoxBorderColor(editBox)
	local chatType = editBox:GetAttribute("chatType")
	if (not chatType) or (not editBox.Backdrop) then return end

	local info
	if (chatType == "CHANNEL") then
		local id = GetChannelName(editBox:GetAttribute("channelTarget"))
		if (id ~= 0) then
			info = ChatTypeInfo[chatType .. id]
		end
	else
		info = ChatTypeInfo[chatType]
	end

	if info then
		editBox.Backdrop:SetBackdropBorderColor(info.r, info.g, info.b, 1)
	else
		local color = C.general.border.color
		editBox.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
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

-- Right chat: first undocked, shown window after ChatFrame1. Temporary windows have IDs above
-- MAX_CHAT_WINDOWS, so they are never picked.
local GetRightChatFrame = function()
	for i = 2, MAX_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if (not frame.isDocked) and _G["ChatFrame" .. i .. "Tab"]:IsShown() then
			return frame
		end
	end
end

-- ChatFrame1 is an Edit Mode system: its SetPoint/ClearAllPoints are overrides, the originals
-- are kept as *Base. Calling the originals skips Edit Mode snapping and our own SetPoint hook.
local SetPanelPoints = function(frame, anchor)
	local ClearAllPoints = frame.ClearAllPointsBase or frame.ClearAllPoints
	local SetPoint = frame.SetPointBase or frame.SetPoint
	ClearAllPoints(frame)
	SetPoint(frame, "TOP", anchor.Tab, "BOTTOM", 0, -5)
	SetPoint(frame, "LEFT", anchor, "LEFT", C.chat.margin, 0)
	SetPoint(frame, "RIGHT", anchor, "RIGHT", -16, 0)
	SetPoint(frame, "BOTTOM", anchor.DataText, "TOP", 0, 8)
end

-- Blizzard re-anchors ChatFrame1 through its SetPoint override: Edit Mode (ApplySystemAnchor)
-- and, on Classic, UIParentManageFramePositions while chat is in its default position.
function CHAT.OnChatFrame1SetPoint(frame)
	SetPanelPoints(frame, CHAT.Left)
end

function CHAT.PositionChat(frame)
	local anchor
	if (frame == _G.ChatFrame1) then
		anchor = CHAT.Left
	elseif (frame == GetRightChatFrame()) then
		anchor = CHAT.Right
	else
		return
	end

	frame:SetParent(anchor)
	SetPanelPoints(frame, anchor)
	frame:SetMovable(true) -- the frame needs to be movable to use 'SetUserPlaced'
	frame:SetUserPlaced(true)
	frame:SetMovable(false)

	FCF_SavePositionAndDimensions(frame)
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
	
	local name = frame:GetName()

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetFading(C.chat.text.fading.enabled)
	frame:SetTimeVisible(C.chat.text.fading.timer or 15)
	
	local Tab = _G[name .. "Tab"]
	if Tab then
		-- remove default tab textures
		Tab:StripTextures()
		self.UpdateTabAlpha(frame)

		local TabText = Tab.Text or _G[name .."TabText"]
		if TabText then
			TabText:SetFont(font, fontSize, fontFlag)
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
	hooksecurefunc(EditBox, "UpdateHeader", self.UpdateEditBoxBorderColor)

	-- hide editbox instead of fading
	EditBox:HookScript("OnEditFocusLost", function(self)
		self:Hide()
	end)

	self:HideTextures(frame)
	self.PositionChat(frame)

	-- Mouse Wheel
	frame:SetScript("OnMouseWheel", self.OnMouseWheel)

	frame.__styled = true
end

function CHAT:Setup()
	local frameLevel = self.Left.Tab:GetFrameLevel()

	for i = 1, MAX_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		local tab = _G["ChatFrame" .. i .. "Tab"]

		tab:SetFrameLevel(frameLevel + 1)

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

	hooksecurefunc("FCF_OpenTemporaryWindow", self.StyleTemporaryChatFrames)
	hooksecurefunc("FCF_RestorePositionAndDimensions", self.PositionChat)
	hooksecurefunc(_G.ChatFrame1, "SetPoint", self.OnChatFrame1SetPoint)
	hooksecurefunc("FCFTab_UpdateAlpha", self.UpdateTabAlpha)
	hooksecurefunc(BNToastFrame, "AddToast", self.AddToast)

	if not E.db.chat then
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:SetScript("OnEvent", function(f)
			f:UnregisterAllEvents()
			CHAT:Reset()
		end)
	end
end
