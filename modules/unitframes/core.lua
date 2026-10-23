local addon, ns = ...
local oUF = ns.oUF or _G.oUF
assert(oUF, "Unable to locate oUF install.")

local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:CreateModule("UnitFrames")
local Talents = E:GetModule("Talents")

-- Blizzard
local NUM_BOSS_FRAMES = _G.NUM_BOSS_FRAMES or 8
local NUM_ARENA_FRAMES = _G.NUM_ARENA_FRAMES or 5

local CompactRaidFrameManager = _G.CompactRaidFrameManager
local CompactRaidFrameContainer = _G.CompactRaidFrameContainer
local GetNumGroupMembers = _G.GetNumGroupMembers
local InCombatLockdown =_G.InCombatLockdown

--------------------------------------------------
-- Unitframes
--------------------------------------------------
local units = {} -- store all spawn units

do
    local HEALER = "HEALER"
    local DEFAULT = "DEFAULT"

    local element_proto = {
        position = DEFAULT,
        positions = {
            [HEALER] = { "BOTTOM", UIParent, "BOTTOM", 0, 225 },
            [DEFAULT] = { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 300 }
        }
    }

    function element_proto:GetPosition()
        if Talents:IsHealer() and GetNumGroupMembers() <= C.unitframes.raid.healer.threshold then
            return HEALER
        end
        return DEFAULT
    end

    function element_proto:UpdatePosition()
        -- the holder parents the secure raid headers: move it after combat
        if InCombatLockdown() then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end

        local position = self:GetPosition()
        if position ~= self.position then
            self:ClearAllPoints()
            self:SetPoint(unpack(self.positions[position]))
            self.position = position
        end
    end

    function element_proto:OnEvent(event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:UnregisterEvent(event)
        end
        self:UpdatePosition()
    end

    function UnitFrames:CreateRaidHolder()
        local rows = 2
        local cols = C.unitframes.raid.unitsPerColumn
        -- point "LEFT": xOffset spaces units within a row, columnSpacing stacks the rows
        local colsSpacing = C.unitframes.raid.xOffset
        local rowsSpacing = C.unitframes.raid.columnSpacing
        local width = C.unitframes.raid.width
        local height = C.unitframes.raid.height
    
        local element = Mixin(CreateFrame("Frame", addon .. "GroupHolder", E.PetHider), element_proto)
        element:SetWidth(cols * width + (cols - 1) * colsSpacing)
        element:SetHeight(rows * height + (rows - 1) * rowsSpacing)
        element:SetPoint(unpack(element.positions[DEFAULT]))

        if C.unitframes.raid.healer.position then
            element:RegisterEvent("GROUP_ROSTER_UPDATE")
            element:SetScript("OnEvent", element.OnEvent)
            -- the first role (at PLAYER_ENTERING_WORLD) also sets the initial position
            Talents.OnRoleChanged = function() element:UpdatePosition() end
        end
        return element
    end
end

function UnitFrames:DisableBlizzard()
	local PartyFrame = PartyFrame

	if (PartyFrame and (C.unitframes.raid.enabled or C.unitframes.party.enabled)) then
        PartyFrame:SetParent(E.Hider)
    end

	if C.unitframes.raid.enabled then
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
		
		if (E.isMainline) then
			UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
			CompactRaidFrameManager_SetSetting("IsShown", "0")
		end

		-- Hide Raid Interface Options.
		-- if not E.isStandard then
		-- 	InterfaceOptionsFrameCategoriesButton11:SetHeight(0.00001)
		-- 	InterfaceOptionsFrameCategoriesButton11:SetAlpha(0)
		-- end
	end
end

-- Blizzard's UnitFrame_OnEnter reads frame.unit, which oUF no longer sets,
-- so read the secure unit attribute instead (works with every oUF version).
local function UnitFrame_UpdateTooltip(self)
    local unit = SecureButton_GetModifiedUnit(self)
    if (not unit or GameTooltip:IsForbidden()) then
        self.UpdateTooltip = nil
        return
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetUnit(unit)
    GameTooltip:Show()

    self.UpdateTooltip = UnitFrame_UpdateTooltip
end

local function UnitFrame_OnEnter(self)
    UnitFrame_UpdateTooltip(self)
end

function UnitFrames:CreateUnitFrame(frame)
    frame:RegisterForClicks("AnyUp")
    frame:SetScript("OnEnter", UnitFrame_OnEnter)
    frame:SetScript("OnLeave", UnitFrame_OnLeave)

    local textParent = CreateFrame("Frame", nil, frame)
    textParent:SetAllPoints(frame)
    textParent:SetFrameLevel(frame:GetFrameLevel() + 8)
    frame.TextParent = textParent

    frame.Health = self:CreateHealth(frame, frame.TextParent)
    frame.Power = self:CreatePower(frame, frame.TextParent)
    frame.Name = self:CreateName(frame, frame.TextParent)
    
    if frame.__config.castbar then
        frame.Castbar = self:CreateCastbar(frame, frame.Power)
    end
    
    if frame.__config.auras then
        frame.Buffs = self:CreateBuffs(frame)
        frame.Debuffs = self:CreateDebuffs(frame)
    end

    if frame.__key == "player" or frame.__key == "target" then
        frame.Portrait = self:CreatePortrait(frame)
    end
    
    frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(frame)

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

function UnitFrames:GetPartyAttributes()
    return addon .. "Party",
        nil,
        "showParty", true,
        "showPlayer", true,
        "point", "TOP",
        "yOffset", -C.unitframes.party.yOffset,
        "initial-width", C.unitframes.party.width,
        "initial-height", C.unitframes.party.height,
        "oUF-initialConfigFunction", [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
end

function UnitFrames:GetRaidVisibility()
    local visibility = "custom [group:raid, @raid21, noexists] show; "
    if not C.unitframes.party.enabled then
        visibility = visibility .. "[group:party, nogroup:raid] show; "
    end
    if C.unitframes.raid.solo then
        visibility = visibility .. "[@player, exists, nogroup:party] show; "
    end
    return visibility ..  "hide"
end

function UnitFrames:GetRaidAttributes()
    local name = addon .. "Raid"
    local showSolo = C.unitframes.raid.solo or nil

    -- local visibility = "custom [group:raid, @raid21, noexists] show; [group:party, nogroup:raid] show; "
    -- if C.unitframes.raid.solo then
    --     visibility = visibility .. "[@player, exists, nogroup:party] show; "
    -- end
    -- visibility = visibility ..  "hide"

    return name,
        nil,
        -- visibility,
        -- http://wowprogramming.com/docs/secure_template/Group_Headers
        -- Set header attributes
        "showParty", true,
        "showRaid", true,
        "showPlayer", true,
        "showSolo", showSolo,
        "showPet", E.isVanilla,
        "xOffset", C.unitframes.raid.xOffset or 5,
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
end

function UnitFrames:GetRaid40Visibilty()
    return "custom [@raid21, exists] show; hide"
end

function UnitFrames:GetRaid40Attributes()
    local name = addon .. "Raid40"
    -- local visibility = "custom [@raid21, exists] show; hide"
    return name,
        nil,
        -- visibility,
        -- http://wowprogramming.com/docs/secure_template/Group_Headers
        -- Set header attributes
        "showParty", true,
        "showRaid", true,
        "showPlayer", true,
        "showPet", false,
        "xOffset", C.unitframes.raid.xOffset or 5,
        "point", "LEFT",
        "groupFilter", "1,2,3,4,5,6,7,8",
        "groupingOrder", "1,2,3,4,5,6,7,8",
        "groupBy", "GROUP",
        "maxColumns", math.ceil(40 / 5),
        "unitsPerColumn", C.unitframes.raid.unitsPerColumn or 5,
        "columnSpacing", C.unitframes.raid.columnSpacing or 5,
        "columnAnchorPoint", "BOTTOM",
        "initial-width", C.unitframes.raid.width or 70,
        "initial-height", math.ceil(0.80 * C.unitframes.raid.height or 30),
        "oUF-initialConfigFunction", [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
end

function UnitFrames:Init()
    if (not C.unitframes.enabled) then return end

    self:DisableBlizzard()

    local holder = E.PetHider

    local RaidHolder = self:CreateRaidHolder(holder)
    self.RaidHolder = RaidHolder

    oUF:RegisterStyle(addon, function(frame, unit)
        -- Retail oUF owns frame.__unit, so the style key needs its own field.
        frame.__key = unit:gsub("%d+", "")
        frame.__config = C.unitframes[frame.__key]

        -- header children are sized by oUF-initialConfigFunction
        if frame.__key ~= "raid" and frame.__key ~= "party" then
            local width = frame.__config.width or 200
            local height = frame.__config.height or 32
            frame:SetSize(width, height)
        end
        
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
        elseif (unit == "party") then
            UnitFrames:CreatePartyFrame(frame)
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
            -- targettarget:SetPoint("BOTTOM", holder, "BOTTOM", 0, 235)
            targettarget:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -40)
        end

        local pet = CreateUnit("pet", holder)
        if (pet) then
            pet:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", 0, 80)
        end

        local focus = CreateUnit("focus", holder)
        if (focus) then
            focus:SetPoint("BOTTOMLEFT", target, "BOTTOMRIGHT", 100, -17)

            local focustarget = CreateUnit("focustarget", holder)
            if (focustarget) then
                -- focustarget:SetPoint("TOP", focus, "BOTTOM", 0, -40)
                focustarget:SetPoint("BOTTOM", focus, "TOP", 0, 40)
            end
        end

        CreateUnit("boss", holder, NUM_BOSS_FRAMES)
        
        CreateUnit("arena", holder, NUM_ARENA_FRAMES)

        if (C.unitframes.party.enabled) then
            local party = self:SpawnHeader(UnitFrames:GetPartyAttributes())
            party:SetVisibility("custom [group:party, nogroup:raid] show; hide")
            party:SetParent(holder)
            party:SetPoint("LEFT", holder, "LEFT", 28, 0)
        end

        if (C.unitframes.raid.enabled) then
            local raid = self:SpawnHeader(UnitFrames:GetRaidAttributes())
            raid:SetVisibility(UnitFrames:GetRaidVisibility())
            raid:SetParent(RaidHolder)
            raid:SetPoint("BOTTOMLEFT", 0, 0)

            local raid40 = self:SpawnHeader(UnitFrames:GetRaid40Attributes())
            raid40:SetVisibility(UnitFrames:GetRaid40Visibilty())
            raid40:SetParent(RaidHolder)
            raid40:SetPoint("BOTTOMLEFT", 0, 0)
        end

        if (C.unitframes.nameplate.enabled) then
            for k, v in next, UnitFrames.Nameplates.cvars do
                local value, _, _, _, _, isSecure, isReadOnly = C_CVar.GetCVarInfo(k)
                if (not value) then
                    E:error("CVar " .. k .. " is not accessible.")
                    UnitFrames.Nameplates.cvars[k] = nil
                end
            end

            local nameplates = self:SpawnNamePlates(addon)
            nameplates:SetSize(200, 20)

            nameplates:SetCVars(UnitFrames.Nameplates.cvars or {})

            if UnitFrames.Nameplates.SetAddedCallback then
                nameplates:SetAddedCallback(UnitFrames.Nameplates.SetAddedCallback)
            end

            if UnitFrames.Nameplates.SetRemovedCallback then
                nameplates:SetRemovedCallback(UnitFrames.Nameplates.SetRemovedCallback)
            end

            if UnitFrames.Nameplates.SetTargetCallback then
                nameplates:SetTargetCallback(UnitFrames.Nameplates.SetTargetCallback)
            end

            -- nameplates:SetEnemyInteractible(state)
            -- nameplates:SetFriendlyInteractible(state)
        end
    end)
end

local function SetTest(frame, enabled)
    if (enabled) then
        frame.__unit = "player"
        frame.Hide = function() end
        frame:Show()
    elseif (rawget(frame, "Hide")) then
        -- only frames shown by a previous test: restore the real Hide
        frame.Hide = nil
        frame:Hide()
    end
end

function UnitFrames.RunTest(group)
    -- boss and arena frames share the same position, show only one of them
    local skip = (group == "arena") and "boss" or "arena"
    for unit, frame in next, units do
        local enabled = (unit ~= skip)
        local length = #frame
        if (length > 0) then
            for i = 1, length do
                SetTest(frame[i], enabled)
            end
        else
            SetTest(frame, enabled)
        end
    end
end

E:AddCommand("test", UnitFrames.RunTest, "Spawn test unit frames; [boss|arena], default boss.")
