local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

-- Blizzard
local NUM_RAID_ICONS = _G.NUM_RAID_ICONS or 8
local NUM_WORLD_RAID_MARKERS = _G.NUM_WORLD_RAID_MARKERS or 8
local RAID_MARKER_RESET_ID = _G.RAID_MARKER_RESET_ID or -1

local ClearRaidMarker = _G.ClearRaidMarker
local SetRaidTarget = _G.SetRaidTarget
local IsRaidMarkerActive = _G.IsRaidMarkerActive
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local PlaceRaidMarker = _G.PlaceRaidMarker
local IsEveryoneAssistant = _G.IsEveryoneAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader

-- Mine
if not C.blizzard.raid_utility then return end

local SIZE = 24
local SPACING = 5

local RAID_MARKER_ATLAS = "GM-raidMarker%d"
local RAID_TARGET_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"

local RAID_TARGETS = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull"
}

local WORLD_MARKERS = {
    [1] = "Square",
    [2] = "Triangle",
    [3] = "Diamond",
    [4] = "Cross",
    [5] = "Star",
    [6] = "Circle",
    [7] = "Moon",
    [8] = "Skull",
}

local ATLAS = {
    ["Skull"] = "GM-raidMarker1",
    ["Cross"] = "GM-raidMarker2",
    ["Square"] = "GM-raidMarker3",
    ["Moon"] = "GM-raidMarker4",
    ["Triangle"] = "GM-raidMarker5",
    ["Diamond"] = "GM-raidMarker6",
    ["Circle"] = "GM-raidMarker7",
    ["Star"] = "GM-raidMarker8",
}

local WORLD_MARKERS_ORDER = _G.WORLD_RAID_MARKER_ORDER or { [1] = 8, [2] = 4, [3] = 1, [4] = 7, [5] = 2, [6] = 3, [7] = 6, [8] = 5 }



local button_proto = {}

do
    function button_proto:OnEnter()
        if self.__tooltip then
            local tooltip = GameTooltip
            tooltip:SetOwner(self, "ANCHOR_TOP")
            tooltip:AddLine(self.__tooltip or self:GetName())
            tooltip:Show()
        end
    end

    function button_proto:OnLeave()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end

    function button_proto:SetHighlight(state)
        local color = state and C.general.highlight.color or C.general.border.color
        self.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
    end
end

--------------------------------------------------
-- Assist
--------------------------------------------------

local assist_proto = {}

function assist_proto:Update()
    self.__checked = IsEveryoneAssistant()
    self:SetHighlight(self.__checked)

    local isGroupLeader = UnitIsGroupLeader("player")
    self:SetEnabled(isGroupLeader)
end

function assist_proto:OnClick(button, down)
    SetEveryoneIsAssistant(not self.__checked)
end

--------------------------------------------------
-- Ready Check
--------------------------------------------------
local readycheck_proto = {}

function readycheck_proto:OnClick(button, down)
    DoReadyCheck()
end

--------------------------------------------------
-- Role Poll
--------------------------------------------------
local rolepoll_proto = {}

function rolepoll_proto:OnClick(button, down)
    InitiateRolePoll()
end

--------------------------------------------------
-- Countdown
--------------------------------------------------
local countdown_proto = {}

function countdown_proto:OnClick(button, down)
    C_PartyInfo.DoCountdown(10)
end

--------------------------------------------------
-- Restrict Ping
--------------------------------------------------
local restrict_ping_proto = {}

do
    local RestrictPingTo = function(value)
        return function(self)
            C_PartyInfo.SetRestrictPings(value)
        end
    end

    local IsRestrictChecked = function(value)
        return function(self)
            local restrictedTo = C_PartyInfo.GetRestrictPings()
            return restrictedTo == value
        end
    end

    local menuFrame = CreateFrame("Frame", "TaintedRestrictPingMenu", UIParent, "UIDropDownMenuTemplate")
    
    local menuItems = {
        { text = "None", isNotRadio = true, func = RestrictPingTo(Enum.RestrictPingsTo.None), checked = IsRestrictChecked(Enum.RestrictPingsTo.None) },
        { text = "Lead", isNotRadio = true, func = RestrictPingTo(Enum.RestrictPingsTo.Lead), checked = IsRestrictChecked(Enum.RestrictPingsTo.Lead) },
        { text = "Assist", isNotRadio = true, func = RestrictPingTo(Enum.RestrictPingsTo.Assist), checked = IsRestrictChecked(Enum.RestrictPingsTo.Assist) },
        { text = "Tanks/Healers", isNotRadio = true, func = RestrictPingTo(Enum.RestrictPingsTo.TankHealer), checked = IsRestrictChecked(Enum.RestrictPingsTo.TankHealer) },
    }

    function restrict_ping_proto:OnClick(button, down)
        E:CreateDropDown(menuItems, menuFrame, "cursor", 0, 0, "Menu", 5)
    end
end

--------------------------------------------------
-- Close
--------------------------------------------------
local close_proto = {}

do
    function close_proto:OnClick(button, down)
        local parent = self:GetParent()
        parent:Hide()
    end
end

--------------------------------------------------
-- Raid Target
--------------------------------------------------
local raid_target_proto = {}

do
    function raid_target_proto:OnClick(button, down)
        SetRaidTarget("target", self.__index)
    end

    function raid_target_proto:IsActive()
        local index = GetRaidTargetIndex("target")
        return self.__index == index
    end
end

--------------------------------------------------
-- World Marker
--------------------------------------------------
local world_marker_proto = {}

do
    -- these function are restricted to Blizzard UI
    -- function world_marker_proto:OnClick(button, down)
    --     ClearRaidMarker(self.__index)
    --     PlaceRaidMarker(self.__index)
    -- end

    function world_marker_proto:IsActive()
        return IsRaidMarkerActive(self.__index)
    end
end

local clear_proto = {}

do
    -- these function are restricted to Blizzard UI
    function clear_proto:OnClick(button, down)
        ClearRaidMarker()
    end
end

--------------------------------------------------
-- Raid Utility
--------------------------------------------------
local element_proto = {}

function element_proto:UpdateAnchor()
    local minimap = _G["TaintedMinimapDataText"] or _G["Minimap"]

    self:ClearAllPoints()
    if minimap then
        self:SetPoint("TOPRIGHT", minimap, "BOTTOMRIGHT", 0, -3)
    else
        self:SetPoint("CENTER", UIParent, -800, 0)
    end
end

function element_proto:CreateButton(name, atlas, proto, tooltip)
    local element = Mixin(CreateFrame("Button", "$parent" .. name, self, "SecureActionButtonTemplate"), button_proto, proto or {})
    element:SetSize(SIZE, SIZE)
    element:SetNormalAtlas(atlas)
    element:CreateBackdrop()
    if element.OnClick then element:SetScript("OnClick", element.OnClick) end
    if element.OnEnter then element:SetScript("OnEnter", element.OnEnter) end
    if element.OnLeave then element:SetScript("OnLeave", element.OnLeave) end
    element.__tooltip = tooltip
    return element
end

function element_proto:CreateRaid()
end

function element_proto:Load()
    self.buttons = table.wipe(self.buttons or {})
    self.markers = table.wipe(self.markers or {})

    local size, spacing = 24, 5
    local xOffset, yOffset = spacing, spacing
    local cols = (NUM_RAID_ICONS + 1)
    local width = (cols * size) + ((cols + 1) * spacing)

    -- Everyone Is Assist
    self.EveryoneIsAssist = self:CreateButton("EveryoneIsAssist", "GM-icon-assist", assist_proto, "Everyone Is Assist")
    self.EveryoneIsAssist:SetPoint("TOPLEFT", self, "TOPLEFT", spacing, -yOffset)

    -- Ready Check
    self.ReadyCheck = self:CreateButton("ReadyCheck", "GM-icon-readyCheck", readycheck_proto, "Ready Check")
    self.ReadyCheck:SetPoint("TOPLEFT", self.EveryoneIsAssist or self, "TOPRIGHT", spacing, 0)

    -- Role Poll
    self.RolePoll = self:CreateButton("RolePoll", "GM-icon-roles", rolepoll_proto, "Role Poll")
    self.RolePoll:SetPoint("TOPLEFT", self.ReadyCheck or self, "TOPRIGHT", spacing, 0)

    -- Countdown
    self.Countdown = self:CreateButton("Countdown", "GM-icon-countdown", countdown_proto, "Countdown")
    self.Countdown:SetPoint("TOPLEFT", self.RolePoll or self, "TOPRIGHT", spacing, 0)
    
    -- Restrict Ping
    self.RestrictPing = self:CreateButton("RestrictPing", "Ping_Wheel_Icon_OnMyWay", restrict_ping_proto, _G.RAID_MANAGER_RESTRICT_PINGS_TO)
    self.RestrictPing:SetPoint("TOPLEFT", self.Countdown or self, "TOPRIGHT", spacing, 0)

    -- Close
    self.Close = self:CreateButton("Close", "UI-LFG-DeclineMark", close_proto, "Close")
    self.Close:SetPoint("TOPLEFT", self.RestrictPing or self, "TOPRIGHT", (3 * SIZE) + (4 * spacing), 0)
    
    yOffset = yOffset + size + spacing

    -- Raid Targets
    do
        for pos = 1, NUM_RAID_ICONS do
            local index = NUM_RAID_ICONS - pos + 1
            local symbol = RAID_TARGETS[index]
            local atlas = ATLAS[symbol]

            local button = self:CreateButton("RaidTargetButton" .. index, atlas, raid_target_proto, "Mark current target as " .. symbol)
            button.__index = index

            if pos == 1 then
                button:SetPoint("TOPLEFT", self, "TOPLEFT", spacing, -yOffset)
            else
                button:SetPoint("LEFT", self.buttons[pos - 1], "RIGHT", 5, 0)
            end

            table.insert(self.buttons, button)
        end

        yOffset = yOffset + size + spacing
    end

    -- World Markers
    do
        for pos, index in next, WORLD_MARKERS_ORDER do
            local symbol = WORLD_MARKERS[index]
            local atlas = ATLAS[symbol]

            local button = self:CreateButton("WorldMarkerButton" .. index, atlas, world_marker_proto, "Place a " .. symbol .. " mark on the ground")
            button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
            button:SetAttribute("type1", "macro")
            button:SetAttribute("macrotext1", "/wm " .. index)
            button:SetAttribute("type2", "macro")
            button:SetAttribute("macrotext2", "/cwm " .. index)
            button.__index = index

            if pos == 1 then
                button:SetPoint("TOPLEFT", self, "TOPLEFT", spacing, -yOffset)
            else
                button:SetPoint("LEFT", self.markers[pos - 1], "RIGHT", spacing, 0)
            end

            table.insert(self.markers, button)
        end

        yOffset = yOffset + size + spacing

        -- Clear World Markers
        self.ClearWorldMarkers = self:CreateButton("ClearWorldMarkers", "GM-raidMarker-reset", clear_proto, "Clear Markers")
        self.ClearWorldMarkers:SetPoint("TOPLEFT", self.markers[#WORLD_RAID_MARKER_ORDER], "TOPRIGHT", spacing, 0)
    end

    self:SetWidth(width)
    self:SetHeight(yOffset)
    self:UpdateAnchor()
end

function element_proto:UpdateRaidTarget()
    local index = GetRaidTargetIndex("target")
    for _, button in next, self.buttons do
        button:SetHighlight(button.__index == index)
    end
end

function element_proto:UpdateWorldMarkers()
    for _, button in next, self.markers do
        button:SetHighlight(button:IsActive())
    end
end

function element_proto:UpdateVisibility()
    if self:IsShown() then
        self:Hide()
    else
        self:Show()
    end
    -- if IsInGroup() and UnitIsGroupLeader("player") then
    --     self:Show()
    -- else
    --     self:Hide()
    -- end
end

function element_proto:OnEvent(event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        -- self:UpdateVisibility()
        if self.EveryoneIsAssist then self.EveryoneIsAssist:Update() end
    elseif event == "RAID_TARGET_UPDATE" then
        self:UpdateRaidTarget()
        self:UpdateWorldMarkers()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:UpdateRaidTarget()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- self:UpdateVisibility()
        self:UpdateWorldMarkers()
        if self.EveryoneIsAssist then self.EveryoneIsAssist:Update() end
    end
end

local frame = Mixin(CreateFrame("Frame", "TaintedRaidUtility", UIParent), element_proto)
frame:SetPoint("CENTER", UIParent, -800, 0)
frame:CreateBackdrop("transparent")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PARTY_LEADER_CHANGED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("RAID_TARGET_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", frame.OnEvent)
frame:Hide()

MODULE.RaidUtility = frame

E:AddCommand("raid", function() frame:UpdateVisibility() end, "Show/Hide raid utility")
