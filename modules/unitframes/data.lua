local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

local CreatureTypes = {
    CASTER = "caster",
    FRONTAL = "frontal",
    IMPORTANT = "important"
}

E.CreatureTypes = CreatureTypes

local creatures = {
    --------------------------------------------------
    -- Dragonflight
    --------------------------------------------------
    -- Algeth'ar Academy
    [196044] = CreatureTypes.CASTER, -- Unruly Textbook
    [196045] = CreatureTypes.CASTER, -- Corrupted Manafiend
    [196202] = CreatureTypes.CASTER, -- Spectral Invoker
    [192333] = CreatureTypes.FRONTAL, -- Alpha Eagle
    [196671] = CreatureTypes.FRONTAL, -- Arcane Ravager
    [196576] = CreatureTypes.IMPORTANT, -- Spellbound Scepter

    --------------------------------------------------
    -- The War Within
    --------------------------------------------------
    -- Ara-Kara, City of Echos
    [216293] = CreatureTypes.CASTER, -- Trilling Attendant
    [216364] = CreatureTypes.CASTER, -- Blood Overseer
    [217531] = CreatureTypes.CASTER, -- Ixin
    [217533] = CreatureTypes.CASTER, -- Atik
    [218324] = CreatureTypes.CASTER, -- Nakt
    [223253] = CreatureTypes.CASTER, -- Bloodstained Webmage
    [216338] = CreatureTypes.FRONTAL, -- Hulking Bloodguard
    [217039] = CreatureTypes.FRONTAL, -- Nerubian Hauler
    [216340] = CreatureTypes.IMPORTANT, -- Sentry Stagshell
    
    -- City of Threads
    [216326] = CreatureTypes.CASTER, -- Ascendend Neophyte
    [216339] = CreatureTypes.CASTER, -- Sureki Unnaturaler
    [219984] = CreatureTypes.CASTER, -- Xeph'itik
    [220195] = CreatureTypes.CASTER, -- Sureki Silkbinder
    [220196] = CreatureTypes.CASTER, -- Herald of Ansurek
    [221102] = CreatureTypes.CASTER, -- Elder Shadeweaver
    [223844] = CreatureTypes.CASTER, -- Covert Webmancer
    [224732] = CreatureTypes.CASTER, -- Covert Webmancer
    [220197] = CreatureTypes.FRONTAL, -- Royal Swarmguard
    [220730] = CreatureTypes.FRONTAL, -- Royal Venomshell
    [221103] = CreatureTypes.FRONTAL, -- Hulking Warshell
    [219983] = CreatureTypes.IMPORTANT, -- Eye of the Queen

    -- The Danwbreaker (*)
    [210966] = CreatureTypes.CASTER, -- Sureki Webmage
    [214762] = CreatureTypes.CASTER, -- Nightfall Commander
    [214761] = CreatureTypes.CASTER, -- Nightfall Ritualist
    [213892] = CreatureTypes.CASTER, -- Nightfall Shadowmage
    [213893] = CreatureTypes.CASTER, -- Nightfall Darkcaster
    [225605] = CreatureTypes.CASTER, -- Nightfall Darkcaster
    [213934] = CreatureTypes.FRONTAL, -- Nightfall Tactician
    -- [213932] = CreatureTypes.CASTER, -- Sureki Militant
    -- [228540] = CreatureTypes.CASTER, -- Nightfall Shadowmage

    -- The Stonevault
    [212389] = CreatureTypes.CASTER, -- Cursedheart Invader
    [212403] = CreatureTypes.CASTER, -- Cursedheart Invader
    [213338] = CreatureTypes.CASTER, -- Forgebound Mender
    [214066] = CreatureTypes.CASTER, -- Curseforge Stoneshaper
    [214350] = CreatureTypes.CASTER, -- Turned Speaker (Silence)
    [221979] = CreatureTypes.CASTER, -- Void Boun Howler
    [224962] = CreatureTypes.CASTER, -- Cursedforge Mender
    [210109] = CreatureTypes.FRONTAL, -- Earth Infused Golem
    [213343] = CreatureTypes.FRONTAL, -- Forge Loader
    [214264] = CreatureTypes.FRONTAL, -- Cursedforge Honor Guard
    [212453] = CreatureTypes.IMPORTANT, -- Ghastly Voidsoul (Howling Fear)
    [214287] = CreatureTypes.IMPORTANT, -- Earth Burst Totem

    -- Mists of Tirna Scithe
    [164921] = CreatureTypes.CASTER, -- Drust Harvester
    [166275] = CreatureTypes.CASTER, -- Mistveil Shaper (Shield)
    [166299] = CreatureTypes.CASTER, -- Mistveil Tender (Heal)
    [164929] = CreatureTypes.FRONTAL, -- Tirnenn Villager (Bewildering Pollen)
    [167111] = CreatureTypes.IMPORTANT, -- Spinemaw Staghorn

    -- Siege of Boralus (*)
    [129370] = CreatureTypes.CASTER, -- Irontide Waveshaper
    [144071] = CreatureTypes.CASTER, -- Irontide Waveshaper
    [128969] = CreatureTypes.CASTER, -- Ashvane Commander
    [135241] = CreatureTypes.CASTER, -- Bilge Rat Pillager
    [129367] = CreatureTypes.CASTER, -- Bilge Rat Tempest
    [129374] = CreatureTypes.FRONTAL, -- Scrimshaw Enforcer
    [129879] = CreatureTypes.FRONTAL, -- Irontide Cleaver
    [129996] = CreatureTypes.FRONTAL, -- Irontide Cleaver
    [136549] = CreatureTypes.FRONTAL, -- Ashvane Cannoneer
    [138465] = CreatureTypes.FRONTAL, -- Ashvane Cannoneer
    [137516] = CreatureTypes.IMPORTANT, -- Ashvane Invader (strong poison)

    -- The Necrotic Wake (*)
    [166302] = CreatureTypes.CASTER, -- Corpse Harvester
    [163128] = CreatureTypes.CASTER, -- Zolramus Sorcerer
    [163618] = CreatureTypes.CASTER, -- Zolramus Necromancer
    [165824] = CreatureTypes.CASTER, -- Nar'zudah
    [165872] = CreatureTypes.CASTER, -- Flesh Crafter
    [173016] = CreatureTypes.CASTER, -- Corpse Collector
    [163621] = CreatureTypes.FRONTAL, -- Goregrind
    [165919] = CreatureTypes.IMPORTANT, -- Skeletal Marauder (Fear)

    -- Grim Batol (*)
    [40167] = CreatureTypes.CASTER, -- Twilight Beguiler
    [224219] = CreatureTypes.CASTER, -- Twilight Earthcaller
    [224271] = CreatureTypes.CASTER, -- Twilight Warlock
    [462216] = CreatureTypes.FRONTAL, -- Blazing Shadowflame
    [224249] = CreatureTypes.FRONTAL, -- Twilight Lavabender

    -- Cinderbrew Meadery
    [218671] = CreatureTypes.CASTER, -- Venture Co. Pyromaniac
    [214673] = CreatureTypes.CASTER, -- Flavor Scientist
    [222964] = CreatureTypes.CASTER, -- Flavor Scientist
    [220141] = CreatureTypes.CASTER, -- Royal Jelly Purveyor
    [223423] = CreatureTypes.FRONTAL, -- Careless Hopgoblin
    [210264] = CreatureTypes.FRONTAL, -- Bee Wrangler
    [220946] = CreatureTypes.FRONTAL, -- Venture Co. Honey Harvester
    [210269] = CreatureTypes.FRONTAL, -- Hired Muscle
    [214697] = CreatureTypes.IMPORTANT, -- Chef Chewie
    [220368] = CreatureTypes.IMPORTANT, -- Failed Batch
    
    -- Darkflame Cleft
    [210812] = CreatureTypes.CASTER, -- Royal Wicklighter
    [210818] = CreatureTypes.CASTER, -- Lowly Moleherd
    [220815] = CreatureTypes.CASTER, -- Blazing Fiend
    [212412] = CreatureTypes.FRONTAL, -- Sootsnout
    [208450] = CreatureTypes.IMPORTANT, -- Wandering Candle
    [208456] = CreatureTypes.IMPORTANT, -- Shuffling Horror
    [212411] = CreatureTypes.IMPORTANT, -- Torchsnarl
    -- [211121] = CreatureTypes.FRONTAL, -- Rank Overseer
    -- [213913] = CreatureTypes.CASTER, -- Kobold Flametender
    
    -- Piory of the Sacred Flame
    [206697] = CreatureTypes.CASTER, -- Devout Priest
    [206698] = CreatureTypes.CASTER, -- Fanatical Conjurer
    [211289] = CreatureTypes.CASTER, -- Taener Duelmal
    [212827] = CreatureTypes.CASTER, -- High Priest Aemya
    [221760] = CreatureTypes.CASTER, -- Risen Mage
    [206704] = CreatureTypes.IMPORTANT, -- Ardente Paladin
    [206710] = CreatureTypes.IMPORTANT, -- Lightspawn
    [211290] = CreatureTypes.IMPORTANT, -- Elaena Emberlanz
    [211291] = CreatureTypes.IMPORTANT, -- Sergeant Shaynemail
    [212826] = CreatureTypes.IMPORTANT, -- Guard Captain Suleyman
    [212831] = CreatureTypes.IMPORTANT, -- Forge Master Damian
    [217658] = CreatureTypes.IMPORTANT, -- Sir Braunpyke
    -- [207949] = "none", -- Zaelous Templar
    -- [212835] = "none", -- Risen Footman
    -- [206705] = "none", -- Arathi Footman (Shield)
    -- [206696] = "none", -- Arathi Knight
    -- [206694] = "none", -- Fervent Sharpshooter

    -- The Rookery
    [207186] = CreatureTypes.FRONTAL, -- Unruly Stormrook
    [207198] = CreatureTypes.CASTER, -- Cursed Thunderer
    [207199] = CreatureTypes.CASTER, -- Cursed Rooktender
    [207202] = CreatureTypes.CASTER, -- Void Fragment
    [209801] = CreatureTypes.FRONTAL, -- Quartermaster Koratite
    [212786] = CreatureTypes.IMPORTANT, -- Voidrider
    [212793] = CreatureTypes.CASTER, -- Void Ascendant
    [214419] = CreatureTypes.FRONTAL, -- Void Cursed Crusher
    [214421] = CreatureTypes.CASTER, -- Coalescing Void Diffuser
    [214439] = CreatureTypes.IMPORTANT, -- Corrupted Oracle
}

function E:GetNPCID(unit)
    local guid = UnitGUID(unit)
    if guid then
        local unitType, _, _, _, _, npcID, _ = string.split("-", guid)
        if (unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet") and npcID then
            return tonumber(npcID)
        end
    end
    return nil
end

function E:GetCreatureType(unit)
    local npcID = self:GetNPCID(unit)
    return creatures[npcID or 0]
end
