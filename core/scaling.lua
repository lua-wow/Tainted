local _, ns = ...
local E, C = ns.E, ns.C

-- Blizzard
local GetCVar = C_CVar and C_CVar.GetCVar or _G.GetCVar
local SetCVar = C_CVar and C_CVar.SetCVar or _G.SetCVar

--------------------------------------------------
-- Pixel Perfect
--------------------------------------------------
-- called again when the resolution or ui scale changes
function E:UpdatePixelScale()
	local physicalScreenWidth, physicalScreenHeight = GetPhysicalScreenSize()
	self.screenWidth = physicalScreenWidth
	self.screenHeight = physicalScreenHeight
	self.pixelPerfectScale = math.min(1, math.max(0.3, 768 / physicalScreenHeight))
end

-- scaling multiplier, cached because E.Scale runs for every border/inset
local mult = 1

function E:UpdateScale()
	-- Default to 1 if 'uiScale' is not a valid number
	local uiScale = tonumber(GetCVar("uiScale")) or 1

	-- ApplyUiScale may push UIParent below the CVar minimum (0.64)
	local parentScale = UIParent:GetScale()
	if (parentScale and parentScale < uiScale) then
		uiScale = parentScale
	end

	mult = self.pixelPerfectScale / uiScale
end

E.Scale = function(size)
	-- Ensure 'size' is a valid number, default to 1 if not
	size = tonumber(size) or 1

	-- Return the scaled size, rounded to the nearest integer
    return mult * math.floor(size / mult + 0.5)
end

E:UpdatePixelScale()
E:UpdateScale()

--------------------------------------------------
-- UIScaling
--------------------------------------------------
-- reference: https://wowpedia.fandom.com/wiki/UI_scaling
function E:SetupUiScale()
    local uiScale = C.general.uiScale
    local currentUIScale = math.floor((uiScale * 100) + 0.5)
    local savedUIScale = math.floor(((tonumber(GetCVar("uiScale")) or 0) * 100) + 0.5)

    -- enable ui scaling
    SetCVar("useUiScale", 1)

    -- change ui scale only if cvar was changed
    if (currentUIScale ~= savedUIScale) then
        SetCVar("uiScale", uiScale)
    end

    self:ApplyUiScale()
end

-- UIParent scale isn't saved by the client, so it is applied on every login
function E:ApplyUiScale()
    local uiScale = C.general.uiScale

    -- allow ui to be set under 0.64
    if (uiScale <= 0.64 and GetCVar("useUiScale") == "1") then
        UIParent:SetScale(uiScale)
    end

    self:UpdateScale()
end

--------------------------------------------------
-- Events
--------------------------------------------------
E:RegisterEvent("UI_SCALE_CHANGED")
E:RegisterEvent("DISPLAY_SIZE_CHANGED")

-- only affects frames sized after the change; existing ones update on /reload
function E:UI_SCALE_CHANGED()
	self:UpdatePixelScale()
	self:UpdateScale()
end

E.DISPLAY_SIZE_CHANGED = E.UI_SCALE_CHANGED
