local addon, ns = ...
local oUF = ns.oUF or _G.oUF
assert(oUF, "Unable to locate oUF install.")

local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:CreateModule("UnitFrames")

-- Blizzard
local NUM_BOSS_FRAMES = _G.NUM_BOSS_FRAMES or 8
local NUM_ARENA_FRAMES = _G.NUM_ARENA_FRAMES or 5

local CompactRaidFrameManager = _G.CompactRaidFrameManager
local CompactRaidFrameContainer = _G.CompactRaidFrameContainer
local GetSpecialization = _G.GetSpecialization
local GetSpecializationRole = _G.GetSpecializationRole

local units = {}

local auras = {
    ["player"] = true,
    ["target"] = true,
    ["targettarget"] = false,
    ["focus"] = true,
    ["focustarget"] = false,
    ["pet"] = true,
    ["raid"] = false,
    ["arena"] = true,
    ["boss"] = true,
    ["nameplate"] = false
}

do
    local element_proto = {
        unit = "player",
        numGroupMembers = 0,
        threshold = 20,
        spells = {
            [384255] = true,    -- Changing Talents
            [200749] = true     -- Activating Specialization
        }
    }

    function element_proto:SetDefaultPosition()
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 300)
    end

    function element_proto:SetHealerPosition()
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", parent, "BOTTOM", 0, 270)
    end

    -- TODO: Implement method for classic
    function element_proto:IsHealer()
        local spec = GetSpecialization()
        local specRole = GetSpecializationRole(spec)
        return (specRole == "HEALER")
    end

    function element_proto:UpdatePosition()
        if self:IsHealer() and (self.numGroupMembers <= self.threshold) then
            self:SetHealerPosition()
        else
            self:SetDefaultPosition()
        end
    end

    function element_proto:OnEvent(event, ...)
        self[event](self, ...)
    end

    function element_proto:PLAYER_ENTERING_WORLD()
        self.numGroupMembers = GetNumGroupMembers()
        self:UpdatePosition()
    end

    function element_proto:GROUP_ROSTER_UPDATE()
        self.numGroupMembers = GetNumGroupMembers()
        self:UpdatePosition()
    end

    function element_proto:UNIT_SPELLCAST_SUCCEEDED(unit, guid, spellID)
        if unit ~= self.unit then return end
        if not self.spells[spellID] then return end
        self:UpdatePosition()
    end

    function UnitFrames:CreateRaidHolder()
        local rows = 2
        local cols = C.unitframes.raid.unitsPerColumn
        local colsSpacing = C.unitframes.raid.columnSpacing
        local rowsSpacing = C.unitframes.raid.xOffset
        local width = C.unitframes.raid.width
        local height = C.unitframes.raid.height
    
        local element = Mixin(CreateFrame("Frame", addon .. "GroupHolder", E.PetHider), element_proto)
        -- element:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 300)
        element:SetWidth(cols * width + (cols - 1) * colsSpacing)
        element:SetHeight(rows * height + (rows - 1) * rowsSpacing)
        element:UpdatePosition()
        -- element:RegisterEvent("PLAYER_LOGIN")
        element:RegisterEvent("PLAYER_ENTERING_WORLD")
        element:RegisterEvent("GROUP_ROSTER_UPDATE")
        element:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        -- element:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")           -- Added in patch 5.0.4 (MoP) / Removed on patch 10.1.7 (Dragonflight)
        -- element:RegisterEvent("SPELLS_CHANGED")                          -- Removed in patch 4.0.1 (Cata)
        element:SetScript("OnEvent", element.OnEvent)
        return element
    end
end

function UnitFrames:DisableBlizzard()
	local PartyFrame = PartyFrame
	
	if C.unitframes.raid.enabled then
        if (PartyFrame) then
            PartyFrame:SetParent(E.Hider)
        end

		-- Disable Blizzard Raid Frames.
        if (CompactRaidFrameManager) then
            CompactRaidFrameManager:SetParent(E.Hider)
            CompactRaidFrameManager:UnregisterAllEvents()
            CompactRaidFrameManager:Hide()
        end

		if (CompactRaidFrameContainer) then
            CompactRaidFrameContainer:SetParent(E.Hider)
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:Hide()
        end
		
		if (E.isRetail) then
			UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
			CompactRaidFrameManager_SetSetting("IsShown", "0")
		end

		-- Hide Raid Interface Options.
		if not E.isRetail then
			InterfaceOptionsFrameCategoriesButton11:SetHeight(0.00001)
			InterfaceOptionsFrameCategoriesButton11:SetAlpha(0)
		end
	end
end

function UnitFrames:CreateUnitFrame(frame)
    frame:RegisterForClicks("AnyUp")
    frame:SetScript("OnEnter", UnitFrame_OnEnter)
    frame:SetScript("OnLeave", UnitFrame_OnLeave)

    frame.Health = self:CreateHealth(frame)
    frame.HealthPrediction = self:CreateHealthPrediction(frame)
    frame.Power = self:CreatePower(frame)
    frame.Name = self:CreateName(frame)
    frame.Portrait = self:CreatePortrait(frame)
    frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(frame)

    if (auras[frame.__unit]) then
        frame.Castbar = self:CreateCastbar(frame)
        frame.Buffs = self:CreateBuffs(frame)
        frame.Debuffs = self:CreateDebuffs(frame)
    end

    return frame
end

local function CreateUnit(unit, parent, num)
    if (units[unit] or not C.unitframes[unit].enabled) then return end

    local name = unit:gsub("^%l", string.upper):gsub("t(arget)", "T%1")

    if (unit == "boss" or unit == "arena") then
        units[unit] = {}

        for i = 1, num do
            local element = oUF:Spawn(unit .. i, addon .. name .. i)
            element:SetParent(parent)
            
            if (i == 1) then
                element:SetPoint("LEFT", parent, "CENTER", 350, 300)
            else
                local prev = units[unit][i - 1]
                element:SetPoint("TOP", prev, "BOTTOM", 0, -40)
            end

            units[unit][i] = element
        end
    else
        local element = oUF:Spawn(unit, addon .. name)
        element:SetParent(parent)
        
        units[unit] = element
    end

    return units[unit]
end

function UnitFrames:Init()
    if (not C.unitframes.enabled) then return end

    self:DisableBlizzard()

    local holder = E.PetHider

    local RaidHolder = self:CreateRaidHolder(holder)
    self.RaidHolder = RaidHolder

    oUF:RegisterStyle(addon, function(frame, unit)
        frame.__unit = unit:gsub("%d+", "")
        frame.__config = C.unitframes[frame.__unit]

        local width = frame.__config.width or 200
        local height = frame.__config.height or 32
        frame:SetSize(width, height)
        frame:CreateBackdrop()
        frame.Backdrop:SetBackdropColor(0, 0, 0)
        frame.Backdrop:SetBackdropBorderColor(0, 0, 0)

        if (unit == "player") then
            UnitFrames:CreatePlayerFrame(frame)
        elseif (unit == "target") then
            UnitFrames:CreateTargetFrame(frame)
        elseif (unit == "targettarget") then
            UnitFrames:CreateTargetTargetFrame(frame)
        elseif (unit == "focus") then
            UnitFrames:CreateFocusFrame(frame)
        elseif (unit == "focustarget") then
            UnitFrames:CreateFocusTargetFrame(frame)
        elseif (unit == "pet") then
            UnitFrames:CreatePetFrame(frame)
        elseif (unit == "raid") then
            UnitFrames:CreateRaidFrame(frame)
        elseif (unit:match("^arena%d")) then
            UnitFrames:CreateArenaFrame(frame)
        elseif (unit:match("^boss%d")) then
            UnitFrames:CreateBossFrame(frame)
        elseif (unit:match("^nameplate%d")) then
            UnitFrames:CreateNameplateFrame(frame)
        end
    end)

    oUF:Factory(function(self)
        self:SetActiveStyle(addon)

        local player = CreateUnit("player", holder)
        if (player) then
            player:SetPoint("BOTTOMRIGHT", holder, "BOTTOM", -239, 235)
        end

        local target = CreateUnit("target", holder)
        if (target) then
            target:SetPoint("BOTTOMLEFT", holder, "BOTTOM", 239, 235)
        end

        local targettarget = CreateUnit("targettarget", holder)
        if (targettarget) then
            targettarget:SetPoint("BOTTOM", holder, "BOTTOM", 0, 235)
        end

        local pet = CreateUnit("pet", holder)
        if (pet) then
            pet:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", 0, 80)
        end

        local focus = CreateUnit("focus", holder)
        if (focus) then
            focus:SetPoint("BOTTOMLEFT", target, "BOTTOMRIGHT", 30, 0)

            local focustarget = CreateUnit("focustarget", holder)
            if (focustarget) then
                focustarget:SetPoint("TOP", focus, "BOTTOM", 0, -40)
            end
        end

        local boss = CreateUnit("boss", holder, NUM_BOSS_FRAMES)
        
        local arena = CreateUnit("arena", holder, NUM_ARENA_FRAMES)

        if (C.unitframes.raid.enabled) then
            local group = self:SpawnHeader(addon .. "Group", nil, "raid,party,solo",
                -- http://wowprogramming.com/docs/secure_template/Group_Headers
                -- Set header attributes
                "showParty", true,
                "showRaid", true,
                "showPlayer", true,
                "showPet", false,
                "xOffset", C.unitframes.raid.xOffset or 5,
                "yOffset", C.unitframes.raid.yOffset or 5,
                "point", "LEFT",
                "groupFilter", "1,2,3,4,5,6,7,8",
		        "groupingOrder", "1,2,3,4,5,6,7,8",
                "groupBy", "GROUP",
                "maxColumns", math.ceil(40 / 5),
                "unitsPerColumn", C.unitframes.raid.unitsPerColumn or 5,
                "columnSpacing", C.unitframes.raid.columnSpacing or 5,
                "columnAnchorPoint", "BOTTOM",
                "initial-width", C.unitframes.raid.width or 70,
                "initial-height", C.unitframes.raid.height or 30,
                "oUF-initialConfigFunction", [[
                    local header = self:GetParent()
                    self:SetWidth(header:GetAttribute("initial-width"))
                    self:SetHeight(header:GetAttribute("initial-height"))
                ]]
            )
            group:SetParent(RaidHolder)
            group:SetPoint("BOTTOMLEFT", 0, 0)
        end

        if (C.unitframes.nameplate.enabled) then
            self:SpawnNamePlates(addon, UnitFrames.NameplateCallback, UnitFrames.NameplateCVars)
        end
    end)
end

function UnitFrames:RunTest()
    for _, frame in next, units do
        local length = #frame
        if (length > 0) then
            for i = 1, length do
                frame[i].unit = "player"
                frame[i].Hide = function() end
                frame[i]:Show()
            end
        else
            frame.unit = "player"
            frame.Hide = function() end
            frame:Show()
        end
    end
end

E:AddCommand("test", UnitFrames.RunTest, "spawn frames")
