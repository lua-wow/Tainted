local _, ns = ...
local oUF = ns.oUF
local E, C, A = ns.E, ns.C, ns.A

--------------------------------------------------
-- Skyriding Race
--------------------------------------------------
if not C.miscellaneous.skyriding_race then return end

local RACES = {
    -- Isle of Dorn
    [444141] = true, -- Dornogal Drift
    [444142] = true, -- Storm's Watch Survey
    [444143] = true, -- Basin Bypass
    [444144] = true, -- The Wold Ways
    [444146] = true, -- Thunderhead Trail
    [444147] = true, -- Orecreg's Doglegs

    -- The Ringing Deeps
    [444148] = true, -- Earthenworks Weave
    [444149] = true, -- Ringing Deeps Ramble
    [444150] = true, -- Chittering Concourse
    [444151] = true, -- Cataract River Cruise
    [444152] = true, -- Taellonch Twist
    [444154] = true, -- Opportunity Point Amble

    -- Hallowfall
    [444155] = true, -- Dunelle's Detour
    [444156] = true, -- Tenir's Traversal
    [444157] = true, -- Light's Redoubt Descent
    [444158] = true, -- Stillstone Slalom
    [444159] = true, -- Mereldar Meander
    [444161] = true, -- Velhan's Venture
    
    -- Azj'kahet
    [444162] = true, -- City of Threads Twist
    [444163] = true, -- Maddening Deep Dip
    [444164] = true, -- The Weaver's Wing
    [444167] = true, -- Rak-Ahat Rush
    [444168] = true, -- Pit Plunge
    [444169] = true, -- Siegehold Scuttle
}

local RACE_STARTING = {
    --------------------------------------------------
    -- Isle of Dorn
    --------------------------------------------------
    -- Dornagol Drift
    [439233] = { duration = 48, difficulty = "Normal" },
    [439241] = { duration = 43, difficulty = "Advanced" },
    [439248] = { duration = 43, difficulty = "Reverse" },
    -- Storm's Watch Survey
    [439234] = { duration = 63, difficulty = "Normal" },
    [439243] = { duration = 60, difficulty = "Advanced" },
    [439249] = { duration = 62, difficulty = "Reverse" },
    -- Basin Bypass
    [439235] = { duration = 58, difficulty = "Normal" },
    [439244] = { duration = 54, difficulty = "Advanced" },
    [439250] = { duration = 57, difficulty = "Reverse" },
    -- The Wold Ways
    [439236] = { duration = 68, difficulty = "Normal" },
    [439245] = { duration = 68, difficulty = "Advanced" },
    [439251] = { duration = 70, difficulty = "Reverse" },
    -- Thunderhead Trail
    [439238] = { duration = 70, difficulty = "Normal" },
    [439246] = { duration = 66, difficulty = "Advanced" },
    [439252] = { duration = 66, difficulty = "Reverse" },
    -- Orecreg's Doglegs
    [439239] = { duration = 65, difficulty = "Normal" },
    [439247] = { duration = 61, difficulty = "Advanced" },
    [439254] = { duration = 61, difficulty = "Reverse" },

    --------------------------------------------------
    -- The Ringing Deeps
    --------------------------------------------------
    -- Earthenworks Weave
    [439257] = { duration = 52, difficulty = "Normal" },
    [439265] = { duration = 49, difficulty = "Advanced" },
    [439271] = { duration = 50, difficulty = "Reverse" },
    -- Ringing Deeps Ramble
    [439258] = { duration = 57, difficulty = "Normal" },
    [439266] = { duration = 57, difficulty = "Advanced" },
    [439272] = { duration = 57, difficulty = "Reverse" },
    -- Chittering Concourse
    [439260] = { duration = 56, difficulty = "Normal" },
    [439267] = { duration = 53, difficulty = "Advanced" },
    [439273] = { duration = 54, difficulty = "Reverse" },
    -- Cataract River Cruise
    [439261] = { duration = 60, difficulty = "Normal" },
    [439268] = { duration = 58, difficulty = "Advanced" },
    [439274] = { duration = 57, difficulty = "Reverse" },
    -- Taelloch Twist
    [439262] = { duration = 47, difficulty = "Normal" },
    [439269] = { duration = 43, difficulty = "Advanced" },
    [439275] = { duration = 44, difficulty = "Reverse" },
    -- Opportunity Point Amble
    [439263] = { duration = 77, difficulty = "Normal" },
    [439270] = { duration = 71, difficulty = "Advanced" },
    [439276] = { duration = 72, difficulty = "Reverse" },

    --------------------------------------------------
    -- Hallowfall
    --------------------------------------------------
    -- Dunelle's  Detour
    [439277] = { duration = 65, difficulty = "Normal" },
    [439286] = { duration = 62, difficulty = "Advanced" },
    [439292] = { duration = 64, difficulty = "Reverse" },
    -- Tenir's Traversal
    [439278] = { duration = 65, difficulty = "Normal" },
    [439287] = { duration = 60, difficulty = "Advanced" },
    [439293] = { duration = 63, difficulty = "Reverse" },
    -- Light's Redoubt Descent
    [439281] = { duration = 63, difficulty = "Normal" },
    [439288] = { duration = 62, difficulty = "Advanced" },
    [439294] = { duration = 62, difficulty = "Reverse" },
    -- Stillstone Slalom
    [439282] = { duration = 56, difficulty = "Normal" },
    [439289] = { duration = 54, difficulty = "Advanced" },
    [439295] = { duration = 56, difficulty = "Reverse" },
    -- Mereldar Meander
    [439283] = { duration = 76, difficulty = "Normal" },
    [439290] = { duration = 71, difficulty = "Advanced" },
    [439296] = { duration = 71, difficulty = "Reverse" },
    -- Velhan's Venture
    [439284] = { duration = 55, difficulty = "Normal" },
    [439291] = { duration = 50, difficulty = "Advanced" },
    [439298] = { duration = 50, difficulty = "Reverse" },

    --------------------------------------------------
    -- Azj'kahet
    --------------------------------------------------
    -- City of Threads Twist
    [439300] = { duration = 78, difficulty = "Normal" },
    [439307] = { duration = 74, difficulty = "Advanced" },
    [439316] = { duration = 74, difficulty = "Reverse" },
    -- Meddening Deep Dip
    [439301] = { duration = 58, difficulty = "Normal" },
    [439308] = { duration = 54, difficulty = "Advanced" },
    [439317] = { duration = 56, difficulty = "Reverse" },
    -- The Weaver's Wing
    [439302] = { duration = 54, difficulty = "Normal" },
    [439309] = { duration = 51, difficulty = "Advanced" },
    [439318] = { duration = 50, difficulty = "Reverse" },
    -- Rak-Ahat Rush
    [439303] = { duration = 70, difficulty = "Normal" },
    [439310] = { duration = 66, difficulty = "Advanced" },
    [439319] = { duration = 66, difficulty = "Reverse" },
    -- Pit Plunge
    [439304] = { duration = 70, difficulty = "Normal" },
    [439311] = { duration = 66, difficulty = "Advanced" },
    [439320] = { duration = 63, difficulty = "Reverse" },
    -- Siegehold Scuttle
    [439305] = { duration = 70, difficulty = "Normal" },
    [439313] = { duration = 66, difficulty = "Advanced" },
    [439321] = { duration = 63, difficulty = "Reverse" },
}

local RACING = 369968 -- Racing
local COUTDOWN = 394884 -- Countdown
local FAIL = 382142 -- Fail

local element_proto = {
    auras = {},
    actives = {}
}

function element_proto:OnUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.1 then
        local timeleft = self.expirationTime - GetTime()
        self:SetValue(timeleft)
        if self.Value then
            self.Value:SetFormattedText("%0.2fs", timeleft)

            if timeleft < 0 then
                self.Value:SetTextColor(1, 0, 0)
            else
                self.Value:SetTextColor(1, 1, 1)
            end
        end
        self.elapsed = 0
    end
end

function element_proto:OnEvent(event, ...)
    self[event](self, ...)
end

function element_proto:PreRaceStart(data)
    if self._raceID then return end

    if self:IsRace(data) then
        self._race = data.name
        self._raceID = data.spellId

        local name = data.name:gsub("Race Times:%s*", "")
        self._name = name

        if self.Text then
            self.Text:SetText(name)
        end
    end

    if self:IsShown() then
        self:Hide()
    end
end

function element_proto:RaceStart(data)
    if self._racing then return end

    local info = self:GetRaceInfo(data)
    if info then
        self.duration = info.duration or 0
        self.expirationTime = GetTime() + self.duration
        self.elapsed = 0
        
        -- update status bar
        self:SetMinMaxValues(0, self.duration)
        self:SetValue(self.duration)

        if self.Text then
            self.Text:SetFormattedText("%s: %s", self._name or "none", info.difficulty or "none")
        end
        
        -- initialize timer
        self:SetScript("OnUpdate", self.OnUpdate)
        
        if not self:IsShown() then
            self:Show()
        end

        self._racing = true
    end
end

function element_proto:RaceEnd(data)
    local element = self
    if element:IsRacing(data) or element:IsCountdown(data) or element:IsFail(data) then
        element._racing = false
        element:SetScript("OnUpdate", nil)
        C_Timer.After(5, function() element:Hide() end)
    end
end

function element_proto:GetRaceInfo(data)
    local spellID = data and data.spellId or 0
    return spellID and RACE_STARTING[spellID] or nil
end

function element_proto:IsRace(data)
    return data and RACES[data.spellId] or false
end

function element_proto:IsCountdown(data)
    return data and data.spellId == COUTDOWN
end

function element_proto:IsRacing(data)
    return data and data.spellId == RACING
end

function element_proto:IsFail(data)
    return data and data.spellId == FAIL
end

function element_proto:PLAYER_LOGIN()
    self:UNIT_AURA("player", nil)
    self:RegisterUnitEvent("UNIT_AURA", "player")
    self:UnregisterEvent("PLAYER_LOGIN")
end

function element_proto:FilterAura(data)
    return self:IsRace(data) or self:IsRacing() or self:IsCountdown() or self:IsFail() or self:GetRaceInfo(data) or false
end

function element_proto:UNIT_AURA(unit, updateInfo)
    local changed = false
    local filter = nil --"HELPFUL"

    local isFullUpdate = (not updateInfo) or updateInfo.isFullUpdate
    if isFullUpdate then
        self.auras = table.wipe(self.auras or {})
        self.actives = table.wipe(self.actives or {})
        
        local slots = { C_UnitAuras.GetAuraSlots(unit, filter) }
        for i = 2, #slots do
            local data = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
            if data then
                self.auras[data.auraInstanceID] = data
                self.actives[data.auraInstanceID] = true
                self:PreRaceStart(data)
                self:RaceStart(data)
            end
        end

        changed = true
    else
        if (updateInfo.addedAuras) then
            for _, data in next, updateInfo.addedAuras do
                self.auras[data.auraInstanceID] = data
                self.actives[data.auraInstanceID] = true
                self:PreRaceStart(data)
                changed = true
            end
        end

        if (updateInfo.updatedAuraInstanceIDs) then
            for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs do
                if self.auras[auraInstanceID] then
                    local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
                    if data then
                        self.auras[auraInstanceID] = data
                        if self.actives[auraInstanceID] then
                            self.actives[auraInstanceID] = true
                            self:PreRaceStart(data)
                            changed = true
                        end
                    end
                end
            end
        end

        if (updateInfo.removedAuraInstanceIDs) then
            for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs do
                local data = self.auras[auraInstanceID]
                if data then
                    self.auras[auraInstanceID] = nil

                    if self.actives[auraInstanceID] then
                        self.actives[auraInstanceID] = nil
                        self:RaceStart(data)
                        self:RaceEnd(data)
                        changed = true
                    end

                    -- how the fuck do you check if the player is farm from the race start point ???
                    if (data.spellId == self._raceID) and (self._racing == false) and not self.actives[auraInstanceID] then
                        self._race = nil
                        self._raceID = nil
                        self._racing = nil
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                    end
                end
            end
        end
    end
end

-- STOP WATCH
function element_proto:Start_StopWatch(duration)
    if not StopwatchFrame:IsShown() then
        StopwatchFrame:Show()
    end

    -- resets the stopwatch to 00:00:00
    Stopwatch_Clear()
    
    if duration and duration > 0 then
        -- countdown from the duration
        Stopwatch_StartCountdown(duration)
    end

    -- starts the stopwatch
    Stopwatch_Play()
end

function element_proto:Pause_StopWatch()
    if StopwatchFrame:IsShown() then
        Stopwatch_Pause()
    end
end

local fontObject = E.GetFont(C.miscellaneous.font)
local texture = C.miscellaneous.texture

local element = Mixin(CreateFrame("StatusBar", "TaintedRaceTracker", UIParent), element_proto)
element:SetPoint("TOP", UIParent, "TOP", 0, -10)
element:SetSize(250, 20)
element:SetFrameStrata("HIGH")
element:SetReverseFill(true)
element:SetStatusBarTexture(texture)
element:SetStatusBarColor(1.00, 1.00, 0.00, 0.75)
element:SetMinMaxValues(0, 1)
element:SetValue(0)
element:CreateBackdrop()
element:RegisterEvent("PLAYER_LOGIN")
element:SetScript("OnEvent", element.OnEvent)
element:Hide()

local bg = element:CreateTexture(nil, "BORDER")
bg:SetPoint("TOPLEFT", element, 0, 0)
bg:SetPoint("BOTTOMRIGHT", element, 0, 0)
bg:SetTexture(texture)
bg:SetColorTexture(0, 0, 0)
bg.multiplier = C.general.background.multiplier or 0.15

local text = element:CreateFontString(nil, "OVERLAY")
text:SetPoint("LEFT", element, 10, 0)
text:SetFontObject(fontObject)

local value = element:CreateFontString(nil, "OVERLAY")
value:SetPoint("RIGHT", element, -10, 0)
value:SetFontObject(fontObject)

element.bg = bg
element.Text = text
element.Value = value
