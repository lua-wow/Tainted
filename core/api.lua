local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Lua
local getmetatable = getmetatable

-- Blizzard
local GetCVar = C_CVar and C_CVar.GetCVar or _G.GetCVar
local BackdropTemplateMixin = _G.BackdropTemplateMixin

--------------------------------------------------
-- API
--------------------------------------------------
E.API = {}

E.Scale = function(size)
	-- Ensure 'size' is a valid number, default to 1 if not
	size = tonumber(size) or 1

	-- Retrieve the UI scale value and ensure it is valid
	-- Default to 1 if 'uiScale' is not a valid number
	local uiScale = tonumber(GetCVar("uiScale"))
	if not uiScale then
		uiScale = 1
	end

	-- Calculate the scaling multiplier
    local mult = E.pixelPerfectScale / uiScale

	-- Return the scaled size, rounded to the nearest integer
    return mult * math.floor(size / mult + 0.5)
end

E.API.Kill = function(self)
	if self.UnregisterAllEvents then
        self:UnregisterAllEvents()
		self:SetAttribute("statehidden", true)
    end
	self:SetParent(E.Hider)
	-- self:Hide()
end

E.API.StripTexts = function(self, kill)
	for _, region in next, { self:GetRegions() } do
		if (region:GetObjectType() == "FontString") then
			if (kill and type(kill) == "boolean") then
				region:Kill()
			else
				region:SetText("")
			end
		end
	end
end

E.API.StripTextures = function(self, kill)
	for _, region in next, { self:GetRegions() } do
		if (region:GetObjectType() == "Texture") then
			if (kill and type(kill) == "boolean") then
				region:Kill()
			elseif (region:GetDrawLayer() == kill) then
				region:SetTexture(nil)
			elseif (kill and type(kill) == "string" and region:GetTexture() ~= kill) then
				region:SetTexture(nil)
			else
				region:SetTexture(nil)
			end
		end
	end
end

-- Fading
E.API.SetFadeInTemplate = function(self, time, alpha)
	securecall(UIFrameFadeIn, self, time, self:GetAlpha(), alpha)
end

E.API.SetFadeOutTemplate = function(self, time, alpha)
	securecall(UIFrameFadeOut, self, time, self:GetAlpha(), alpha)
end

-- Resize
E.API.SetOutside = function(self, anchor, xOffset, yOffset)
	xOffset = xOffset and E.Scale(xOffset) or E.Scale(1)
	yOffset = yOffset and E.Scale(yOffset) or E.Scale(1)

	anchor = anchor or self:GetParent()

	if self:GetPoint() then
		self:ClearAllPoints()
	end

	self:SetPoint("TOPLEFT", anchor, "TOPLEFT", -xOffset, yOffset)
	self:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", xOffset, -yOffset)
end

E.API.SetInside = function(self, anchor, xOffset, yOffset)
	xOffset = xOffset and E.Scale(xOffset) or E.Scale(1)
	yOffset = yOffset and E.Scale(yOffset) or E.Scale(1)

	anchor = anchor or self:GetParent()

	if self:GetPoint() then
		self:ClearAllPoints()
	end

	self:SetPoint("TOPLEFT", anchor, "TOPLEFT", xOffset, -yOffset)
	self:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -xOffset, yOffset)
end

-- Backdrop
E.API.CreateBackdrop = function(self, template)
	if self.Backdrop then return end
	
	local backdropTexture = C.general.backdrop.texture or A.textures.blank
	local backdropColor = C.general.backdrop.color
	local backdropAlpha = 1
	
	if (template == "transparent") then
		backdropAlpha = 0.70
	elseif type(template) == "number" then
		backdropAlpha = template
	end
	
	local borderTexture = C.general.border.texture or A.textures.blank
	local borderColor = C.general.border.color

	local inset = E.Scale(C.general.border.size or 1)
	local backdrop = {
		bgFile = backdropTexture
	}

	if (template ~= "solid") then
		backdrop.edgeFile = borderTexture
		backdrop.edgeSize = inset
		backdrop.insets = { top = inset, left = inset, bottom = inset, right = inset }
	end
	
	self.Backdrop = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Backdrop:SetPoint("TOPLEFT", -inset, inset)
	self.Backdrop:SetPoint("BOTTOMRIGHT", inset, -inset)
	self.Backdrop:SetBackdrop(backdrop)
	self.Backdrop:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, backdropAlpha)
	self.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)

	-- draw it below the element
	local level = self:GetFrameLevel() or 1
	if (level > 0) then
		self.Backdrop:SetFrameLevel(level - 1)
	end
end

E.API.SkinButton = function(button)
	button:CreateBackdrop()
	button:HookScript("OnEnter", function (self)
		if (self.Backdrop) then
			local backdropColor = C.general.backdrop.color
			local highlightColor = C.general.highlight.color
			self.Backdrop:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, backdropColor.a or 1)
			self.Backdrop:SetBackdropBorderColor(highlightColor.r, highlightColor.g, highlightColor.b, highlightColor.a or 1)
		end
	end)
	button:HookScript("OnLeave", function (self)
		if (self.Backdrop) then
			local backdropColor = C.general.backdrop.color
			local borderColor = C.general.border.color
			self.Backdrop:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, backdropColor.a or 1)
			self.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
		end
	end)
end

E.API.GetCooldownTimer = function(self)
	if self:GetObjectType() == "Cooldown" then
		local regions = { self:GetRegions() }
		for k, v in next, regions do
			if v:GetObjectType() == "FontString" then
				return v
			end
		end
	end
end

E.API.SkinCloseButton = function(self, xOffset, yOffset, closeSize)
	if self.SetNormalTexture then self:SetNormalTexture(0) end
	if self.SetNormalTexture then self:SetPushedTexture(0) end
	if self.SetHighlightTexture then self:SetHighlightTexture(0) end
	if self.SetDisabledTexture then self:SetDisabledTexture(0) end

	self:StripTextures()

	self.Texture = self:CreateTexture(nil, "OVERLAY")
	self.Texture:SetPoint("CENTER", xOffset or 0, yOffset or 0)
	self.Texture:SetSize(size or 12, size or 12)
	self.Texture:SetTexture(A.textures.close)

	self:SetScript("OnEnter", function(self) self.Texture:SetVertexColor(1, 0, 0) end)
	self:SetScript("OnLeave", function(self) self.Texture:SetVertexColor(1, 1, 1) end)
end

--------------------------------------------------
-- Merge Tainted API with WoW API
--------------------------------------------------
local AddAPI = function(object)
	local mt = getmetatable(object).__index
	for name, callback in pairs(E.API) do
		if not object[name] then mt[name] = callback end
	end
end

local Handled = { ["Frame"] = true }

local Object = CreateFrame("Frame")
AddAPI(Object)
AddAPI(Object:CreateTexture())
AddAPI(Object:CreateFontString())

Object = EnumerateFrames()

while (Object) do
    local t = Object:GetObjectType()
    if (not Object:IsForbidden() and not Handled[Object:GetObjectType()]) then
        AddAPI(Object)
        Handled[Object:GetObjectType()] = true
    end
    Object = EnumerateFrames(Object)
end
