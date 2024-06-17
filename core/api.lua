local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Lua
local getmetatable = getmetatable

-- Blizzard
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
	self:SetParent(E.Hider)
	self:Hide()

	if (self.UnregisterAllEvents) then
        self:UnregisterAllEvents()
    end
end

E.API.StripTexts = function(self, Kill)
	for i = 1, self:GetNumRegions() do
		local Region = select(i, self:GetRegions())
		if (Region and Region:GetObjectType() == "FontString") then
			if (Kill and type(Kill) == "boolean") then
				Region:Kill()
			else
				Region:SetText("")
			end
		end
	end
end

E.API.StripTextures = function(self, Kill)
	for i = 1, self:GetNumRegions() do
		local Region = select(i, self:GetRegions())
		if (Region and Region:GetObjectType() == "Texture") then
			if (Kill and type(Kill) == "boolean") then
				Region:Kill()
			elseif (Region:GetDrawLayer() == Kill) then
				Region:SetTexture(nil)
			elseif (Kill and type(Kill) == "string" and Region:GetTexture() ~= Kill) then
				Region:SetTexture(nil)
			else
				Region:SetTexture(nil)
			end
		end
	end
end


E.API.StripTexts = function(self, Kill)
	for i = 1, self:GetNumRegions() do
		local Region = select(i, self:GetRegions())
		if (Region and Region:GetObjectType() == "FontString") then
			Region:SetText("")
		end
	end
end

-- Fading
E.API.SetFadeInTemplate = function(self, FadeTime, Alpha)
	securecall(UIFrameFadeIn, self, FadeTime, self:GetAlpha(), Alpha)
end

E.API.SetFadeOutTemplate = function(self, FadeTime, Alpha)
	securecall(UIFrameFadeOut, self, FadeTime, self:GetAlpha(), Alpha)
end

-- Resize
E.API.SetOutside = function(self, Anchor, OffsetX, OffsetY)
	OffsetX = OffsetX and E.Scale(OffsetX) or E.Scale(1)
	OffsetY = OffsetY and E.Scale(OffsetY) or E.Scale(1)

	Anchor = Anchor or self:GetParent()

	if self:GetPoint() then
		self:ClearAllPoints()
	end

	self:SetPoint("TOPLEFT", Anchor, "TOPLEFT", -OffsetX, OffsetY)
	self:SetPoint("BOTTOMRIGHT", Anchor, "BOTTOMRIGHT", OffsetX, -OffsetY)
end

E.API.SetInside = function(self, Anchor, OffsetX, OffsetY)
	OffsetX = OffsetX and E.Scale(OffsetX) or E.Scale(1)
	OffsetY = OffsetY and E.Scale(OffsetY) or E.Scale(1)

	Anchor = Anchor or self:GetParent()

	if self:GetPoint() then
		self:ClearAllPoints()
	end

	self:SetPoint("TOPLEFT", Anchor, "TOPLEFT", OffsetX, -OffsetY)
	self:SetPoint("BOTTOMRIGHT", Anchor, "BOTTOMRIGHT", -OffsetX, OffsetY)
end

-- Backdrop
E.API.CreateBackdrop = function(self, template)
	if not self.Backdrop then
		local backdropTexture = C.general.backdrop.texture or A.textures.blank
		local backdropColor = C.general.backdrop.color
		local backdropAlpha = (template == "transparent") and 0.70 or 1
		
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
		
		local level = self:GetFrameLevel() or 1

		self.Backdrop = CreateFrame("Frame", nil, self, "BackdropTemplate")
		self.Backdrop:SetPoint("TOPLEFT", -inset, inset)
		self.Backdrop:SetPoint("BOTTOMRIGHT", inset, -inset)
		self.Backdrop:SetFrameLevel(level - 1)
		self.Backdrop:SetBackdrop(backdrop)
		self.Backdrop:SetBackdropColor(backdropColor.r, backdropColor.g, backdropColor.b, backdropAlpha)
		self.Backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
	end
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
