local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local PERFORMANCEBAR_UPDATE_INTERVAL = _G.PERFORMANCEBAR_UPDATE_INTERVAL or 1

local GetAddOnCPUUsage = _G.GetAddOnCPUUsage
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or _G.GetAddOnInfo
local GetAddOnMemoryUsage = _G.GetAddOnMemoryUsage
local GetAvailableBandwidth = _G.GetAvailableBandwidth
local GetCVarBool = C_CVar and C_CVar.GetCVarBool or _G.GetCVarBool
local GetDownloadedPercentage = _G.GetDownloadedPercentage
local GetFramerate = _G.GetFramerate
local GetNetIpTypes = _G.GetNetIpTypes
local GetNetStats = _G.GetNetStats
local GetNumAddOns = C_AddOns and C_AddOns.GetNumAddOns or _G.GetNumAddOns
local GetTotalCpuUsage = _G.GetTotalCpuUsage
local GetTotalMemory = _G.GetTotalMemory
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded
local ResetCPUUsage = _G.ResetCPUUsage
local UpdateAddOnCPUUsage = _G.UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage

-- Mine
local ADDON_CPU = L.ADDON_CPU or "AddOn CPU"
local ADDON_MEMORY = L.ADDON_MEMORY or "AddOn Memory"
local BANDWIDTH = L.BANDWIDTH or "Bandwidth"
local COLLECT_GARBAGE = L.COLLECT_GARBAGE or "(Ctrl or Alt Click) Collect Garbage"
local DOWNLOAD = L.DOWNLOAD or "Download"
local FRAMERATE = L.FRAMERATE or "Framerate"
local HOME = L.HOME or "Home"
local LATENCY = L.LATENCY or "Latency"
local PROTOCOL = L.PROTOCOL or "Protocol"
local UNKNOWN = L.UNKNOWN or "Unknown"
local WORLD = L.WORLD or "World"

local DATATEXT_STRING = "FPS %s MS %s"
local FRAMERATE_VALUE = "%.0f"
local FRAMERATE_STRING = "%s fps"
local LATENCY_STRING = "%s ms"
local BANDWIDTH_VALUE = "%d Mbps"
local DOWNLOAD_VALUE = "%.2f%%"

local STATUS_COLOR = {
    [1] = E:CreateColor(12, 216, 9), -- green
    [2] = E:CreateColor(232, 218, 15), -- yellow
    [3] = E:CreateColor(255, 144, 0), -- orange
    [4] = E:CreateColor(216, 9, 9), -- red
}

local addons = {}

local system_proto = {}

local FormatMemory = function(value)
    if (value > 1000) then
        return ("%.2f mb"):format(value / 1000)
    end
    return ("%.2f kb"):format(value)
end

local GetTotalMemory = function()
    local value = 0
    for index, row in next, addons do
        value = value + row.memory
    end
    return value
end

local GetTotalCpuUsage = function()
    local value = 0
    for index, row in next, addons do
        value = value + row.cpu
    end
    return value
end

local SortAddOns = function(a, b)
    if (a.memory ~= b.memory) then
        return a.memory > b.memory
    elseif (a.cpu ~= b.cpu) then
        return a.cpu > b.cpu
    end
    return a.name < b.name
end

local UpdateAddonList = function()
    addons = table.wipe(addons or {})

    -- update the memory usages of the addons
    UpdateAddOnMemoryUsage()
    
    local isCpuProfiling = GetCVarBool("scriptProfile")
    if isCpuProfiling then
        -- update the cpu profiling data of the addons
        UpdateAddOnCPUUsage()
    end

    for index = 1, GetNumAddOns(), 1 do
        local name = GetAddOnInfo(index)
        local loadedOrLoading, loaded = IsAddOnLoaded(name)
        if loadedOrLoading then
            local memory = GetAddOnMemoryUsage(name)
            local cpu = isCpuProfiling and GetAddOnCPUUsage(name) or 0
            local row = {
                name = name,
                loaded = loadedOrLoading,
                memory = memory,
                cpu = cpu
            }
            table.insert(addons, row)
        end
    end

    table.sort(addons, SortAddOns)
end

function system_proto:GetFramerateIndex(value)
    -- return (value >= 30 and 1) or (value >= 20 and 2) or (value >= 10 and 3) or 4
    return value >= 30 and 1 or (value >= 20 and value < 30) and 2 or (value >= 10 and value < 20) and 3 or 4
end

function system_proto:GetFramerateColor(value)
    local index = self:GetFramerateIndex(value) or 4
    return STATUS_COLOR[index]
end

function system_proto:GetLatencyIndex(value)
    -- return (value < 150 and 1) or (value >= 150 and 2) or (value >= 300 and 3) or 4
    return value < 150 and 1 or (value >= 150 and value < 300) and 2 or (value >= 300 and value < 500) and 3 or 4
end

function system_proto:GetLatencyColor(value)
    local index = self:GetLatencyIndex(value)
    return STATUS_COLOR[index] or 4
end

local ipTypes = { "IPv4", "IPv6" }
function system_proto:CreateTooltip(tooltip)
    self.__tooltip = true

    -- latency
    local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats();
    latencyHome = self:GetLatencyColor(latencyHome):WrapTextInColorCode(latencyHome)
    latencyWorld = self:GetLatencyColor(latencyWorld):WrapTextInColorCode(latencyWorld)
	tooltip:AddLine(LATENCY)
	tooltip:AddDoubleLine(HOME, LATENCY_STRING:format(latencyHome), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
	tooltip:AddDoubleLine(WORLD, LATENCY_STRING:format(latencyWorld), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)

    -- protocol types
    local useIPv6 = GetCVarBool("useIPv6")
    if useIPv6 then
        local ipTypeHome, ipTypeWorld = GetNetIpTypes();
		string = format(MAINMENUBAR_PROTOCOLS_LABEL, ipTypes[ipTypeHome or 0] or UNKNOWN, ipTypes[ipTypeWorld or 0] or UNKNOWN);
		tooltip:AddLine(" ")
		tooltip:AddLine(PROTOCOL)
		tooltip:AddDoubleLine(HOME, ipTypes[ipTypeHome or 0] or UNKNOWN, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
	    tooltip:AddDoubleLine(WORLD, ipTypes[ipTypeWorld or 0] or UNKNOWN, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    -- framerate
	local framerate = GetFramerate()
    framerate = self:GetFramerateColor(framerate):WrapTextInColorCode(FRAMERATE_VALUE:format(framerate))
	tooltip:AddDoubleLine(FRAMERATE, FRAMERATE_STRING:format(framerate), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
	tooltip:AddLine(" ")
    
    -- bandwidth
	local bandwidth = GetAvailableBandwidth()
    if bandwidth ~= 0 then
        local downloaded = GetDownloadedPercentage()
        tooltip:AddDoubleLine(BANDWIDTH, BANDWIDTH_VALUE:format(bandwidth), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        tooltip:AddDoubleLine(DOWNLOAD, DOWNLOAD_VALUE:format(downloaded * 100), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        tooltip:AddLine(" ")
    end
    
    -- memory
    local memory = GetTotalMemory()
    tooltip:AddDoubleLine(ADDON_MEMORY, FormatMemory(memory), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    
    -- cpu
    local cpu = GetTotalCpuUsage()
    if cpu ~= 0 then
        cpu = ("%.0f"):format(cpu)
        tooltip:AddDoubleLine(ADDON_CPU, LATENCY_STRING:format(cpu), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end
    tooltip:AddLine(" ")
    
    for index, addon in next, addons do
        tooltip:AddDoubleLine(addon.name, FormatMemory(addon.memory), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end
    tooltip:AddLine(" ")

    tooltip:AddLine(COLLECT_GARBAGE)
end

function system_proto:CloseTooltip()
    self.__tooltip = false
end

function system_proto:OnMouseUp()
    local isDown = IsControlKeyDown() or IsAltKeyDown()
    if isDown then
        collectgarbage("collect")
        ResetCPUUsage()
    end
end

function system_proto:OnUpdate(elapsed)
    self.updateInterval = self.updateInterval - (elapsed or 1)
    if self.updateInterval <= 0 then
        local framerate = GetFramerate()
        local framerateText = self:GetFramerateColor(framerate):WrapTextInColorCode(FRAMERATE_VALUE:format(framerate))
        
        local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
        local latency = (latencyHome > latencyWorld) and latencyHome or latencyWorld
        local latencyText = self:GetLatencyColor(latency):WrapTextInColorCode(latency)

        if self.Text then
            self.Text:SetFormattedText(DATATEXT_STRING, framerateText, latencyText)
        end

        self.updateInterval = PERFORMANCEBAR_UPDATE_INTERVAL

        -- update tooltip when it is shown
        if self.__tooltip then
            self:OnEnter()
        end
    end

    self.updateAddonInterval = self.updateAddonInterval - (elapsed or 1)
    if self.updateAddonInterval <= 0 then
        UpdateAddonList()
        self.updateAddonInterval = 10
    end
end

function system_proto:Update()
    self:OnUpdate()
end

function system_proto:Enable()
    self.updateInterval = 0
    self.updateAddonInterval = 0
    
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", self.OnLeave)
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseUp", self.OnMouseUp)
	self:Update()
    self:Show()
end

function system_proto:Disable()
    if self.Text then
        self.Text:SetText("")
    end
    
	self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)
    self:Hide()
end

MODULE:AddElement("System", system_proto)
