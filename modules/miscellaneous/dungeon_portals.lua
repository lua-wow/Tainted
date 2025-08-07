local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Dungeon Portals
--------------------------------------------------
if not C.miscellaneous.mythic.autokeystone then return end

local portals = {
    -- Cataclysm
    [438] = { spells = { default = 410080 }, mapID = 657 }, -- The Vortex Pinnacle
    [456] = { spells = { default = 424142 }, mapID = 643 }, -- Throne of the Tides
    [507] = { spells = { default = 445424 }, mapID = 670 }, -- Grim Batol
    
    -- Mists of Pandaria
    [2]  = { spells = { default = 131204 }, mapID = 960 }, -- Temple of the Jade Serpent
    [56] = { spells = { default = 131205 }, mapID = 961 }, -- Stormstout Brewery
    [57] = { spells = { default = 131225 }, mapID = 962 }, -- Gate of the Setting Sun
    [58] = { spells = { default = 131206 }, mapID = 959 }, -- Shado-Pan Monastery
    [59] = { spells = { default = 131228 }, mapID = 1011 }, -- Siege of Niuzao Temple
    [60] = { spells = { default = 131222 }, mapID = 994 }, -- Mogu'shan Palace
    [76] = { spells = { default = 131232 }, mapID = 1007 }, -- Scholomance
    [77] = { spells = { default = 131231 }, mapID = 1001 }, -- Scarlet Halls
    [78] = { spells = { default = 131229 }, mapID = 1004 }, -- Scarlet Monastery
    
    -- WoD
    [161] = { spells = { default = 159898 }, mapID = 1209 }, -- Skyreach (Path of the Skies)
    [163] = { spells = { default = 159895 }, mapID = 1175 }, -- Bloodmaul Slag Mines (Path of the Bloodmaul)
    [164] = { spells = { default = 159897 }, mapID = 1182 }, -- Archindoun
    [165] = { spells = { default = 159899 }, mapID = 1176 }, -- Shadowmoon Burial Grounds
    [166] = { spells = { default = 159900 }, mapID = 1208 }, -- Grimmrail Depot (Path of the Dark Rail)
    [167] = { spells = { default = 159902 }, mapID = 1358 }, -- Upper Blackrock Spire (Path of the Burning Mountain)
    [168] = { spells = { default = 159901 }, mapID = 1279 }, -- The Everbloom
    [169] = { spells = { default = 159896 }, mapID = 1195 }, -- Iron Docks (Path of the Iron Prow)
    
    -- Legion
    [197] = { spells = nil, mapID = 1456}, -- Eye of Azshara
    [198] = { spells = { default = 424163 }, mapID = 1466 }, -- Darkheart Thicket
    [199] = { spells = { default = 424153 }, mapID = 1501 }, -- Black Rook Hold
    [200] = { spells = { default = 393764 }, mapID = 1477 }, -- Halls of Valor
    [206] = { spells = { default = 410078 }, mapID = 1458 }, -- Neltharion's Lair
    [207] = { spells = nil, mapID = 1493 }, -- Vault of the Wardens
    [208] = { spells = nil, mapID = 1492 }, -- Maw of Souls
    [209] = { spells = nil, mapID = 1516 }, -- The Arcway
    [210] = { spells = { default = 393766 }, mapID = 1571 }, -- Court of Stars
    [227] = { spells = { default = 373262 }, mapID = 1651 }, -- Return of Karazhan: Lower
    [233] = { spells = nil, mapID = 1677 }, -- Catheral of Eternal Night
    [234] = { spells = { default = 373262 }, mapID = 1651 }, -- Return of Karazhan: Upper
    [239] = { spells = nil, mapID = 1753 }, -- Seat of the Triumvirate
    
    -- Battle for Azeroth
    [244] = { spells = { default = 424187 }, mapID = 1763 }, -- Atal'Dazar
    [245] = { spells = { default = 410071 }, mapID = 1754 }, -- Freehold
    [246] = { spells = nil, mapID = 1771 }, -- Tol Dagor
    [247] = { spells = { Alliance = 467553, Horde = 467555 }, mapID = 1594 }, -- The MOTHERLODE!!
    [248] = { spells = { default = 424167 }, mapID = 1862 }, -- Waycrest Manor
    [249] = { spells = nil, mapID = 1762 }, -- Kings' Rest
    [250] = { spells = nil, mapID = 1877 }, -- Temple of Sethraliss
    [251] = { spells = { default = 410074 }, mapID = 1841 }, -- The Underrot
    [252] = { spells = nil, mapID = 1864 }, -- Temple of the Storm
    [353] = { spells = { Alliance = 445418, Horde = 464256 }, mapID = 1822 }, -- Siege of Boralus
    [369] = { spells = { default = 373274 }, mapID = 2097 }, -- Operation: Mechagon - Junkyard
    [370] = { spells = { default = 373274 }, mapID = 2097 }, -- Operation: Mechagon - Workshop
    
    -- Ny'alotha, the Walking City (2217)

    -- Shadowlands
    [375] = { spells = { default = 354464 }, mapID = 2290 }, -- Mists of Tirna Scithe (Path of the Misty Forest)
    [376] = { spells = { default = 354462 }, mapID = 2286 }, -- The Necrotic Wake (Path of the Courageous)
    [377] = { spells = { default = 354468 }, mapID = 2291 }, -- De Other Side (Path of the Scheming Loa)
    [378] = { spells = { default = 354465 }, mapID = 2287 }, -- Halls of Atonement (Path of the Sinful Soul)
    [379] = { spells = { default = 354463 }, mapID = 2289 }, -- Plaguefall (Path of the Plagued)
    [380] = { spells = { default = 354469 }, mapID = 2284 }, -- Sanguine Depths (Path of the Stone Warden)
    [381] = { spells = { default = 354466 }, mapID = 2285 }, -- Spires of Ascension (Path of the Ascendant)
    [382] = { spells = { default = 354467 }, mapID = 2293 }, -- Theater of Pain (Path of the Undefeated)
    [391] = { spells = { default = 367416 }, mapID = 2441 }, -- Tazavesh: Streets of Wonder (Path of the Streetwise Merchant)
    [392] = { spells = { default = 367416 }, mapID = 2441 }, -- Tazavesh: So'leash's Gambit (Path of the Streetwise Merchant)
    
    -- Shadowlands Raids
    ["Nathria"] = { spells = { default = 373190 }, mapID = 0 }, -- Castle Nathria (Path of the Sire)
    ["Sanctum"] = { spells = { default = 373191 }, mapID = 0 }, -- Sanctum of Domination (Path of the Tormented Soul)
    ["Sepulcher"] = { spells = { default = 373192 }, mapID = 2481 }, -- Sepulcher of the First Ones (Path of the First Ones)
    
    -- Dragonflight
    [399] = { spells = { default = 393256 }, mapID = 2521 }, -- Ruby Life Pools
    [400] = { spells = { default = 393262 }, mapID = 2516 }, -- The Nokhud Offensive
    [401] = { spells = { default = 393279 }, mapID = 2515 }, -- The Azure Vault
    [402] = { spells = { default = 393273 }, mapID = 2526 }, -- Algeth'ar Academy
    [403] = { spells = { default = 393222 }, mapID = 2551 }, -- Uldaman: Legacy of Tyr
    [404] = { spells = { default = 393276 }, mapID = 2519 }, -- Neltharus
    [405] = { spells = { default = 393267 }, mapID = 2520 }, -- Bracknhide Hollow
    [406] = { spells = { default = 393283 }, mapID = 2527 }, -- Halls of Infusion
    [463] = { spells = { default = 424197 }, mapID = 2579 }, -- Dawn of the Infinite: Galakrond's Fall
    [464] = { spells = { default = 424197 }, mapID = 2579 }, -- Dawn of the Infinite: Murozond's Rise
        
    -- Dragonflight Raids
    ["Vault"] = { spells = { default = 432254 }, mapID = 0 }, -- Vault of the Incarnates
    ["Aberrus"] = { spells = { default = 432257 }, mapID = 0 }, -- Aberrus, the Shadowed Crucible
    ["Amirdrassil"] = { spells = { default = 432258 }, mapID = 0 }, -- Amirdrassil, the Dream's Hope

    -- The War Within
    [499] = { spells = { default = 445444 }, mapID = 2649 }, -- Priory of the Sacred Flame
    [500] = { spells = { default = 445443 }, mapID = 2648 }, -- The Rookery
    [501] = { spells = { default = 445269 }, mapID = 2652 }, -- The Stonevault
    [502] = { spells = { default = 445416 }, mapID = 2669 }, -- City of Threads
    [503] = { spells = { default = 445417 }, mapID = 2660 }, -- Ara-Kara, City of Echos
    [504] = { spells = { default = 445441 }, mapID = 2651 }, -- Darkflame Cleft
    [505] = { spells = { default = 445414 }, mapID = 2662 }, -- The Dawnbreaker
    [506] = { spells = { default = 445440 }, mapID = 2661 }, -- Cinderbrew Meadery (Path of the Flaming Brewery)
    [525] = { spells = { default = 1216786 }, mapID = 2773 }, -- Operation: Floodgate
    [542] = { spells = { default = 1237215 }, mapID = 2830 }, -- Eco'Dome Al'dani
    
    -- The War Within Raids
    ["Nerub-ar Palace"] = { spells = { default = 0}, mapID = 2657 }, -- Liberation of Undermine (Path of the Full House)
    ["Undermine"] = { spells = { default = 1226482 }, mapID = 2769 }, -- Liberation of Undermine (Path of the Full House)
    ["Manaforge Omega"] = { spells = { default = 1239155 }, mapID = 0 }, -- Manaforge Omega (Path of the All-Devouring)
}

local button_proto = {}

do
    function button_proto:OnEnter()
        if (GameTooltip:IsForbidden()) then return end
        if self.spellID and self.spellName then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end

    function button_proto:OnLeave()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end

    function button_proto:UpdateVisibility()
        self.isKnown = (self.spellID and IsSpellKnown(self.spellID) or false)
        local texture = self:GetNormalTexture()
        if texture then
            texture:SetDesaturated(not self.isKnown)
        end
    end

    function button_proto:UpdateCooldown()
        if not self.Cooldown then return end
        if self.spellID and self.spellName then
            local info = C_Spell.GetSpellCooldown(self.spellID)
            if info and info.isEnabled then
                self.Cooldown:SetCooldown(info.startTime, info.duration)
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

    function portal_proto:GetPortalSpell(mapID, faction)
        local dungeon = portals[mapID]
        return dungeon and dungeon.spells and (dungeon.spells[faction] or dungeon.spells.default) or nil
    end

    function portal_proto:CreateButton(index, mapID)
        local fontObject = E.GetFont(C.miscellaneous.font)
        
        local faction, _ = UnitFactionGroup("player")
        local mapName, _, _, mapTexture, mapBackgroundTexture = C_ChallengeMode.GetMapUIInfo(mapID)
        
        local spellID = self:GetPortalSpell(mapID, faction)
        if not spellID then
            E:error("Dungeon " .. mapName .. " (" .. mapID .. ") is missing the portal spellID")
            return nil
        end
        
        local spellName = C_Spell.GetSpellName(spellID)

        -- Create button for each known spell
        local button = Mixin(CreateFrame("Button", self:GetName() .. mapID, self, "SecureActionButtonTemplate"), button_proto)
        button:SetSize(30, 30)
        button:SetNormalTexture(mapTexture)
        button:EnableMouse(true)
        if spellName then
            button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", "/cast " .. spellName)
        else
            E:error("Dungeon " .. mapName .. " (" .. mapID .. ") portal spell " .. spellID .. " do not exists")
        end
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
