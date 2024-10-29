local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Dungeon Portals
--------------------------------------------------
if not C.miscellaneous.mythic.autokeystone then return end

local portals = {
    -- Cataclysm
    [438] = { spellID = 410080 }, -- The Vortex Pinnacle
    [456] = { spellID = 424142 }, -- Throne of the Tides
    [507] = { spellID = 445424 }, -- Grim Batol
    -- Mists of Pandaria
    [2] = { spellID = 131204 }, -- Temple of the Jade Serpent
    [56] = { spellID = 131205 }, -- Stormstout Brewery
    [57] = { spellID = 131225 }, -- Gate of the Setting Sun
    [58] = { spellID = 131206 }, -- Shado-Pan Monastery
    [59] = { spellID = 131228 }, -- Siege of Niuzao Temple
    [60] = { spellID = 131222 }, -- Mogu'shan Palace
    [76] = { spellID = 131232 }, -- Scholomance
    [77] = { spellID = 131231 }, -- Scarlet Halls
    [78] = { spellID = 131229 }, -- Scarlet Monastery
    -- WoD
    [161] = nil, -- Skyreach
    [163] = nil, -- Bloodmaul Slag Mines
    [164] = nil, -- Archindoun
    [165] = { spellID = 159899 }, -- Shadowmoon Burial Grounds
    [166] = nil, -- Grimmrail Depot
    [167] = nil, -- Upper Blackrock Spire
    [168] = { spellID = 159901 }, -- The Everbloom
    [169] = nil, -- Iron Docks
    -- Legion
    [197] = nil, -- Eye of Azshara
    [198] = { spellID = 424163 }, -- Darkheart Thicket
    [199] = { spellID = 424153 }, -- Black Rook Hold
    [200] = { spellID = 393764 }, -- Halls of Valor
    [206] = { spellID = 410078 }, -- Neltharion's Lair
    [207] = nil, -- Vault of the Wardens
    [208] = nil, -- Maw of Souls
    [209] = nil, -- The Arcway
    [210] = { spellID = 393766 }, -- Court of Stars
    [227] = nil, -- Return of Karazhan: Lower
    [233] = nil, -- Catheral of Eternal Night
    [234] = nil, -- Return of Karazhan: Upper
    [239] = nil, -- Seat of the Triumvirate
    -- Battle for Azeroth
    [244] = { spellID = 424187 }, -- Atal'Dazar
    [245] = { spellID = 410071 }, -- Freehold
    [246] = nil, -- Tol Dagor
    [247] = nil, -- The MOTHERLODE!!
    [248] = { spellID = 424167 }, -- Waycrest Manor
    [249] = nil, -- Kings' Rest
    [250] = nil, -- Temple of Sethraliss
    [251] = { spellID = 410074 }, -- The Underrot
    [252] = nil, -- Temple of the Storm
    [353] = { ["Alliance"] = 445418, ["Horde"] = 464256 }, -- Siege of Boralus
    [369] = nil, -- Operation: Mechagon - Junkyard
    [370] = nil, -- Operation: Mechagon - Workshop
    -- Shadowlands
    [375] = { spellID = 354464 }, -- Mists of Tirna Scithe
    [376] = { spellID = 354462 }, -- The Necrotic Wake
    [377] = nil, -- De Other Side
    [378] = nil, -- Halls of Atonement
    [379] = nil, -- Plaguefall
    [380] = nil, -- Sanguine Depths
    [381] = { spellID = 354462 }, -- Spires of Ascensione
    [382] = nil, -- Theather of Pain
    [391] = nil, -- Tazavesh: Streets of Wonder
    [392] = nil, -- Tazavesh: So'leash's Gambit
    -- Dragonflight
    [399] = { spellID = 393256 }, -- Ruby Life Pools
    [400] = { spellID = 393262 }, -- The Nokhud Offensive
    [401] = { spellID = 393279 }, -- The Azure Vault
    [402] = { spellID = 393273 }, -- Algeth'ar Academy
    [403] = { spellID = 393222 }, -- Uldaman: Legacy of Tyr
    [404] = { spellID = 393276 }, -- Neltharus
    [405] = { spellID = 393267 }, -- Bracknhide Hollow
    [406] = { spellID = 393283 }, -- Halls of Infusion
    [463] = { spellID = 424197 }, -- Dawn of the Infinite: Galakrond's Fall
    [464] = { spellID = 424197 }, -- Dawn of the Infinite: Murozond's Rise
    -- The War Within
    [499] = nil, -- Priory of the Sacred Flame
    [500] = nil, -- The Rookery
    [501] = { spellID = 445269 }, -- The Stonevault
    [502] = { spellID = 445416 }, -- City of Threads
    [503] = { spellID = 445417 }, -- Ara-Kara, City of Echos
    [504] = nil, -- Darkflame Cleft
    [505] = { spellID = 445414 }, -- The Dawnbreaker
    [506] = nil, -- Cinderbrew Meadery
}

local button_proto = {}

do
    function button_proto:OnEnter()
        if (GameTooltip:IsForbidden()) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spellID)
        GameTooltip:Show()
    end

    function button_proto:OnLeave()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end

    function button_proto:UpdateVisibility()
        if self.spellID and IsSpellKnown(self.spellID) then
            self.isKnown = true
            self:Show()
        else
            self.isKnown = false
            self:Hide()
        end
    end

    function button_proto:UpdateCooldown()
        if not self.Cooldown then return end
        if self.spellID then
            local spellCooldownInfo = C_Spell.GetSpellCooldown(self.spellID)
            if spellCooldownInfo and spellCooldownInfo.isEnabled then
                self.Cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration)
            end
        end
    end

    function button_proto:OnShow()
        self:UpdateCooldown()
    end
end

local portal_proto = {}

do
    portal_proto.SortButtons = function(a, b)
        if a.isKnown ~= b.isKnown then
            return a.isKnown
        end
        if a.dungeonScore ~= b.dungeonScore then
            return a.dungeonScore > b.dungeonScore
        end
        return a.mapID > b.mapID
    end

    function portal_proto:UpdatePosition(button, index)
        button:ClearAllPoints()
        if index == 1 then
            button:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
        else
            local prev = self.buttons[index - 1]
            button:SetPoint("TOP", prev, "BOTTOM", 0, -5)
        end
    end

    function portal_proto:CreateButton(index, mapID)
        local fontObject = E.GetFont(C.miscellaneous.font)

        local faction, _ = UnitFactionGroup("player")
        local mapName, _, _, mapTexture, mapBackgroundTexture = C_ChallengeMode.GetMapUIInfo(mapID)

        local portalData = portals[mapID]
        local spellID = portalData.spellID or portalData[faction] or 8690
        local spellName = C_Spell.GetSpellName(spellID)

        if spellID == 8690 then
            E:error("Missing portal spell for " .. mapName .. " (" .. mapID .. ")")
        end

        -- Create button for each known spell
        local button = Mixin(CreateFrame("Button", self:GetName() .. mapID, self, "SecureActionButtonTemplate"), button_proto)
        button:SetSize(30, 30)
        button:SetNormalTexture(mapTexture)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", "/cast " .. spellName)
        button:SetScript("OnEnter", button.OnEnter)
        button:SetScript("OnLeave", button.OnLeave)
        button:HookScript("OnShow", button.OnShow)
        button:CreateBackdrop()
        
        button.index = index
        button.mapID = mapID
        button.mapName = mapName
        button.spellID = spellID
        button.spellName = spellName
        button.isKnown = IsSpellKnown(spellID)
        
        local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
        cd:SetAllPoints(button)
        -- cd:SetReverse(true)
        button.Cooldown = cd

        local timer = cd:GetCooldownTimer()
        if timer then
            timer:SetFontObject(fontObject)
            cd.Timer = timer
        end
        
        self:UpdatePosition(button, index)
        -- button:Show()

        return button
    end

    function portal_proto:Update()
        if InCombatLockdown() then return end

        for index, button in next, self.buttons do
            local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(button.mapID)
            button.dungeonScore = (intimeInfo and intimeInfo.dungeonScore) or (overtimeInfo and overtimeInfo.dungeonScore) or 0

            button:UpdateVisibility()
            button:UpdateCooldown()
        end

        table.sort(self.buttons, self.SortButtons)

        for index, button in next, self.buttons do
            self:UpdatePosition(button, index)
        end
    end

    function portal_proto:OnEvent(event, ...)
        if event == "SPELLS_CHANGED" then
            self:Update()
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_self, event, ...)
    if event ~= "ADDON_LOADED" then return end
    
    local addon = ...
    if addon ~= "Blizzard_ChallengesUI" then return end

    local ChallengesFrame = _G.ChallengesFrame
    if not ChallengesFrame then return end
    
    hooksecurefunc(ChallengesFrame, "Update", function(self)
        if not self.Portals then
            local element = Mixin(CreateFrame("Frame", self:GetName() .. "Portals", self), portal_proto)
            element:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -30)
            element:SetSize(30, 200)
            element:SetFrameLevel(self:GetFrameLevel() + 10)

            element.buttons = table.wipe(element.buttons or {})

            for index, mapID in next, self.maps do
                local button = element:CreateButton(index, mapID)
                table.insert(element.buttons, button)
            end

            element:RegisterEvent("SPELLS_CHANGED")
            element:SetScript("OnEvent", element.OnEvent)
            
            self.Portals = element
        end

        if self.Portals then
            self.Portals:Update()
        end
    end)
end)
