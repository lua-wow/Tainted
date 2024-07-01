local addon, ns = ...
local E, C = ns.E, ns.C

-- Blizzard
local BUFF_MAX_DISPLAY = _G.BUFF_MAX_DISPLAY or 32;
local DEBUFF_MAX_DISPLAY = _G.DEBUFF_MAX_DISPLAY or 16;

--------------------------------------------------
-- Auras
--------------------------------------------------
if not C.auras.enabled then return end

local isInit = false
local auras = {}

local function UpdateAura(button, index)
    local filter = button:GetParent():GetAttribute("filter")
    if not auras[filter][button] then return end

    local aura = C_UnitAuras.GetAuraDataByIndex("player", index, filter)

    if aura then
        local count = aura.applications or 0
        local duration = aura.duration or 0
        local dispelName = aura.dispelName or "none"
        
        button.duration = aura.duration
        button.expirationTime = aura.expirationTime or (GetTime() + duration)

        if button.Icon then
            if aura.icon then
                button.Icon:SetTexture(aura.icon)
            end
        end

        if button.Count then
            button.Count:SetText((count > 1) and count or "")
        end

        if button.Duration then
            if (duration and duration > 0) then
                button.elapsed = 0
                button:SetScript("OnUpdate", button.OnUpdate)
                button.Duration:Show()
            else
                button:SetScript("OnUpdate", nil)
                button.Duration:SetText("")
            end
        end

        if button.Backdrop then
            if (filter == "HARMFUL") then
                local color = E.colors.debuff[dispelName]
                button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
            else
                local color = C.general.backdrop.color
                button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
            end
        end
    end
end

local function UpdateTempEnchant(button, slot)
    local filter = button:GetParent():GetAttribute("filter")
    if not auras[filter][button] then return end

    -- slot = 16 (main-hand)
    -- slot = 17 (off-hand)
    local offset = (slot == 16) and 1 or 5
    local enchant, expiration, charges = select(offset, GetWeaponEnchantInfo())

    local count = charges or 0
    local duration = (expiration or 0) / 1000

    if enchant then
        button.duration = duration
        button.expirationTime = GetTime() + duration

        if button.Icon then
            local icon = GetInventoryItemTexture("player", slot)
            if icon then
                button.Icon:SetTexture(icon)
            end
        end

        if button.Count then
            button.Count:SetText((count > 1) and count or "")
        end

        if button.Duration then
            if (duration and duration > 0) then
                button.elapsed = 0
                button:SetScript("OnUpdate", button.OnUpdate)
                button.Duration:Show()
            else
                button:SetScript("OnUpdate", nil)
                button.Duration:SetText("")
                button.Duration:Hide()
            end
        end

        if button.Backdrop then
            local color = E.colors.debuff["Curse"]
            button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)	
        end
    end
end

local button_proto = {}

do
    function button_proto:OnEnter()
        if GameTooltip:IsForbidden() then return end

		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", -5, -5)

        if self:GetAttribute("index") then
            GameTooltip:SetUnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self:GetAttribute("filter"))
        else
            GameTooltip:SetInventoryItem("player", self:GetID())
        end
    end

    function button_proto:OnLeave()
        if GameTooltip:IsForbidden() then return end
	    GameTooltip:Hide()
    end

    function button_proto:OnUpdate(elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if (self.elapsed >= 0.1) then
            local remaining = (self.expirationTime or 0) - GetTime()
            if (remaining > 0) then
                self.Duration:SetText(E.FormatTime(remaining))

                if (remaining < 60) then
                    if (remaining < 5) then
                        self.Duration:SetTextColor(255/255, 20/255, 20/255)
                    else
                        self.Duration:SetTextColor(255/255, 165/255, 0/255)
                    end
                else
                    self.Duration:SetTextColor(.9, .9, .9)
                end
            else
                self:SetScript("OnUpdate", nil)
                self.Duration:SetText("")
            end
            self.elapsed = 0
        end
    end

    function button_proto:OnAttributeChanged(attr, value)
        if (attr == "index") then
            UpdateAura(self, value)
        elseif (attr == "target-slot") then
            UpdateTempEnchant(self, value)
        end
    end
end

local header_proto = {}

do
    function UpdateButton(button, header)
        local fontObject = E.GetFont(C.auras.font)

        Mixin(button, button_proto)
        button:HookScript("OnAttributeChanged", button.OnAttributeChanged)
        button:SetScript("OnEnter", button.OnEnter)
        button:SetScript("OnLeave", button.OnLeave)
        button:RegisterForClicks("RightButtonDown", "RightButtonUp")
        button:CreateBackdrop()

        local icon = button:CreateTexture(nil, "BORDER")
        icon:SetAllPoints()
        icon:SetTexCoord(unpack(E.IconCoord))
        button.Icon = icon

        local count = button:CreateFontString(nil, "OVERLAY")
        count:SetPoint("BOTTOMRIGHT", -1, 1)
        count:SetFontObject(fontObject)
        button.Count = count

        local duration = button:CreateFontString(nil, "OVERLAY")
        duration:SetPoint("TOP", button, "BOTTOM", 0, -3)
        duration:SetFontObject(fontObject)
        button.Duration = duration

        button._parent = header

        return button
    end

    function header_proto:OnAttributeChanged(attr, value)
        local filter = self:GetAttribute("filter")
		-- if attr:match("^frameref%-child") or attr:match("^temp[Ee]nchant") then
		if attr:match("^frameref%-child") or attr:match("^child") or attr:match("^tempenchant") then
			if type(value) == "userdata" then
				value = GetFrameHandleFrame(value)
			end

			if not auras[filter][value] then
				UpdateButton(value, self)
				auras[filter][value] = true
			end
		end
    end
end

local function CreateHeader(filter)
    assert(filter == "HELPFUL" or filter == "HARMFUL", "Invalid filter. Must be 'HELPFUL' or 'HARMFUL'.")

    if not auras[filter] then
        auras[filter] = {}
    end

    local rows, cols = C.auras.rows or 3, C.auras.columns or 12
    local size, spacing = C.auras.size or 30, C.auras.spacing or 3
    local xOffset = size + spacing + 2
    local yOffset = size + 12 + spacing + 2

    local headerName = (filter == "HELPFUL") and "BuffHeader" or "DebuffHeader"
    local header = Mixin(CreateFrame("Frame", "Tainted" .. headerName, UIParent, "SecureAuraHeaderTemplate"), header_proto)
    header:SetClampedToScreen(true)
    
    header._unit = "player"
    header._filter = filter

    -- set attributes for the header
    header:HookScript("OnAttributeChanged", header.OnAttributeChanged)
    header:SetAttribute("unit", "player")
    header:SetAttribute("filter", filter)
    header:SetAttribute("template", "SecureActionButtonTemplate")
    header:SetAttribute("maxWraps", rows)
    header:SetAttribute("minHeight", rows * size + (rows - 1) * spacing)
    header:SetAttribute("minWidth", cols * size + (cols - 1) * spacing)
    header:SetAttribute("point", "TOPRIGHT")
    header:SetAttribute("separateOwn", 0)
    header:SetAttribute("sortDirection", C.auras.sort.direction or "+")
    header:SetAttribute("sortMethod", C.auras.sort.method or "TIME")
    header:SetAttribute("wrapAfter", cols)
    header:SetAttribute("wrapXOffset", 0)
    header:SetAttribute("wrapYOffset", -yOffset)
    header:SetAttribute("xOffset", -xOffset)
    header:SetAttribute("yOffset", 0)
    header:SetAttribute("initialConfigFunction", ([[
        self:SetAttribute("type2", "cancelaura")
        self:SetWidth(%d)
        self:SetHeight(%d)
    ]]):format(size, size))
    
    if (filter == "HELPFUL") then
        header:SetAttribute("includeWeapons", 1)
        header:SetAttribute("weaponTemplate", "SecureActionButtonTemplate")
    end
    
    -- register the header with the attribute driver
    RegisterAttributeDriver(header, "unit", "[vehicleui] vehicle; player")

    -- prevents SecureAuraHeader_Update spam
    header.visibility = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    SecureHandlerSetFrameRef(header.visibility, "AuraHeader", header)
    RegisterStateDriver(header.visibility, "visibility", "[petbattle] hide; show")
    header.visibility:SetAttribute("_onstate-visibility", [[
        local header = self:GetFrameRef("AuraHeader")
        local isShown = header:IsShown()
        if isShown and newstate == "hide" then
            header:Hide()
        elseif not isShown and newstate == "show" then
            header:Show()
        end
    ]])

    header:Show()

    return header
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function frame:PLAYER_LOGIN()
    if not isInit then
        self.BuffHeader = CreateHeader("HELPFUL")
        self.BuffHeader:SetPoint("TOPRIGHT", _G.Minimap, "TOPLEFT", -5, 0)
        
        self.DebuffHeader = CreateHeader("HARMFUL")
        self.DebuffHeader:SetPoint("TOPRIGHT", _G.Minimap, "BOTTOMLEFT", -5, 30)

        isInit = true
    end
end

local function ForceHide(frame)
    if frame then
        frame:Kill()
    end
end

function frame:PLAYER_ENTERING_WORLD(isLogin, isReload)
    if isLogin or isReload then
        ForceHide(_G.BuffFrame)
        ForceHide(_G.DebuffFrame)
        ForceHide(_G.DeadlyDebuffFrame)
        ForceHide(_G.TemporaryEnchantFrame)
    end
end
