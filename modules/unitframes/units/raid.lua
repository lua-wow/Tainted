local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Raid Debuffs
--------------------------------------------------
do
    local element_proto = {
		showOnlyDispelableDebuffs = false
    }

    function UnitFrames:CreateRaidDebuffs(frame)
        if (not C.unitframes.raid.debuffs) then return end

		local height = C.unitframes.raid.height
		local size = (height >= 32) and (height - 16) or height
        local font = A.fonts.normal
        
        local element = Mixin(CreateFrame("Frame", nil, frame.Health), element_proto)
		element:SetPoint("CENTER", 0, 0)
		element:SetSize(size, size)
		element:SetFrameLevel(frame.Health:GetFrameLevel() + 10)
		element:CreateBackdrop()

		local icon = element:CreateTexture(nil, "ARTWORK")
		icon:SetInside(element)
		icon:SetTexCoord(unpack(E.IconCoord))
        
		local cd = CreateFrame("Cooldown", nil, element, "CooldownFrameTemplate")
		cd:SetInside(element, 1, 0)
		cd:SetReverse(true)
		cd:SetHideCountdownNumbers(true)
		cd:SetAlpha(0.70)
        
		local time = element:CreateFontString(nil, "OVERLAY")
		time:SetPoint("CENTER", element, "CENTER", 0, 0)
		time:SetFont(font, 12, "OUTLINE")
        
		local count = element:CreateFontString(nil, "OVERLAY")
		count:SetPoint("BOTTOMRIGHT", element, "BOTTOMRIGHT", 2, 0)
		count:SetFont(font, 12, "OUTLINE")
		count:SetTextColor(1, .9, 0)
		
		element.Icon = icon
        element.Cooldown = cd
        element.Time = time
        element.Count = count

		return element
    end
end

--------------------------------------------------
-- Aura Track
--------------------------------------------------
do
    local element_proto = {
		icons = true
    }

    function UnitFrames:CreateAuraTrack(frame)
        local element = Mixin(CreateFrame("Frame", frame:GetName() .. "AuraTrack", frame.Health), element_proto)
		element:SetAllPoints()
		return element
    end
end

--------------------------------------------------
-- Raid
--------------------------------------------------
function UnitFrames:CreateRaidFrame(frame)
    self:CreateUnitFrame(frame)
    if (frame.__config.auratrack.enabled) then
        frame.AuraTrack = self:CreateAuraTrack(frame)
    else
        frame.Buffs = self:CreateBuffs(frame)
    end
    frame.RaidDebuffs = self:CreateRaidDebuffs(frame)
    frame.GroupRoleIndicator = self:CreateGroupRoleIndicator(frame)
    frame.ReadyCheckIndicator = self:CreateReadyCheckIndicator(frame)
    frame.ResurrectIndicator = self:CreateResurrectIndicator(frame)
    frame.TargetIndicator = self:CreateTargetIndicator(frame)
    frame.Range = self:CreateRange(frame)
end
