local _, ns = ...
local E = ns.E

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4

-- Mine
-- local KEYSTONE_PATTERN = "|cffa335ee|Hkeystone:(%d+):(%d+):(%d+)(.-)|h%[Keystone: ([^%]]+) %((%d+)%)%]|h|r"
local KEYSTONE_PATTERN = "|Hkeystone:(%d+):(%d+):(%d+)(.-)|h%[Keystone: ([^%(]+)%s%((%d+)%)%]"

local keystone_proto = {}

function keystone_proto:IsKeystone(itemID)
    local classID, subclassID = select(12, C_Item.GetItemInfo(itemID))
    return (classID == Enum.ItemClass.Reagent and subclassID == Enum.ItemReagentSubclass.Keystone)
end

function keystone_proto:GetKeystone()
    for containerIndex = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(containerIndex) or 0
        if slots > 0 then
            for slotIndex = 1, slots do
                local itemID = C_Container.GetContainerItemID(containerIndex, slotIndex)
                if itemID and self:IsKeystone(itemID) then
                    -- "|cffa335ee|Hkeystone:180653:353:7:160:10:152:0|h[Keystone: Siege of Boralus (7)]|h|r"
                    return C_Container.GetContainerItemLink(containerIndex, slotIndex)
                end
            end
        end
    end
    return nil
end

function keystone_proto:GetAffixes()
    return self.affixes[1], self.affixes[2], self.affixes[3], self.affixes[4]
end

--[[
    Season 1: "|cffa335ee|Hkeystone:180653:353:7:160:10:152:0|h[Keystone: Siege of Boralus (7)]|h|r"
    Season 2: "|cffa335ee|Hkeystone:180653:506:4:148:0:0:0:0|h[Keystone: Cinderbrew Meadery (4)]|h|r"
]]
function keystone_proto:Parse(value)
    if not value or type(value) ~= "string" then return end

    local itemID, mapID, level, affixStr, mapName, _ = value:match(KEYSTONE_PATTERN)

    local affixes = {}
    for affix in affixStr:gmatch(":(%d+)") do
        table.insert(affixes, tonumber(affix))
    end

    return {
        itemID = tonumber(itemID),
        mapID = tonumber(mapID),
        mapName = mapName,
        level = tonumber(level),
        affixes = affixes
    }
end

--[[
    * 9 - Tyrannical
    * 10 - Fortified
    * 147 - Xal'atath's Guile
    * 148 - Xal'atath's Bargain: Ascendant
    * 152 - Challenger's Peril
]]
-- "|cffa335ee|Hkeystone:180653:503:12:10:152:9:147|h[Keystone: Ara-Kara, City of Echoes (12)]|h|r"
-- "|cffa335ee|Hkeystone:180653:375:10:148:10:152:9|h[Keystone: Mists of Tirna Scithe (9)]|h|r"
-- "|cffa335ee|Hkeystone:180653:375:9:148:10:152:0|h[Keystone: Mists of Tirna Scithe (9)]|h|r"
-- "|cffa335ee|Hkeystone:180653:503:6:148:10:0:0|h[Keystone: Ara-Kara, City of Echoes (6)]|h|r"
function keystone_proto:IsCurrenWeek(value)
    local info = self:Parse(value)
    if not info then return false end

    local affixes = info.affixes or {}
    local offset = (info.level >= 12) and 1 or 0

    for i = 1, math.max(#self.affixes, #affixes) do
        local actualAffix = affixes[i]
        local expectedAffix = self.affixes[i + offset]

        if expectedAffix and actualAffix and actualAffix ~= expectedAffix and actualAffix ~= 0 then
            return false
        end
    end

    return true
end

function keystone_proto:UpdateKeyStone()
    local keystone = self:GetKeystone()
    if keystone then
        E:SetKeyStone(keystone)
    else
        E:SetKeyStone(nil)
    end
end

function keystone_proto:UpdateWeeklyRewards()
    local data = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
    if (#data == 0) then return end
    
    local level, progress, threshold, activities = 0, 0, 0, {}
    for _, row in next, data do
        if row.level > level then level = row.level end
        if row.progress > progress then progress = row.progress end
        if row.threshold > threshold then threshold = row.threshold end
        table.insert(activities, { index = row.index, type = "mythic+", level = row.level, progress = row.progress, threshold = row.threshold })
    end

    E:SetVault({ level = level, progress = progress, threshold = threshold, activities = activities })
end

function keystone_proto:OnEvent(event, ...)
    self[event](self, ...)
end

function keystone_proto:PLAYER_LOGIN()
    self:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
    C_MythicPlus.RequestCurrentAffixes()
    C_MythicPlus.RequestMapInfo()
end

function keystone_proto:CHALLENGE_MODE_COMPLETED()
    self:UpdateWeeklyRewards()
end

function keystone_proto:WEEKLY_REWARDS_UPDATE()
    self:UpdateWeeklyRewards()
end

function keystone_proto:MYTHIC_PLUS_CURRENT_AFFIX_UPDATE()
    self.affixes = table.wipe(self.affixes or {})
    
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if mapID then
        local mapName, _ = C_ChallengeMode.GetMapUIInfo(mapID)
    end
    
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    local affixesInfo = C_MythicPlus.GetCurrentAffixes()
    if affixesInfo then
        for index, data in next, affixesInfo do
            local name, description, _ = C_ChallengeMode.GetAffixInfo(data.id)
            table.insert(self.affixes, data.id)
        end
    end
    
    self:UnregisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
end

function keystone_proto:BAG_UPDATE_DELAYED(...)
    self:UpdateKeyStone()
end

function keystone_proto:ITEM_CHANGED()
    self:UpdateKeyStone()
end

local frame = Mixin(CreateFrame("Frame"), keystone_proto)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("ITEM_CHANGED")
frame:SetScript("OnEvent", frame.OnEvent)

E:SetModule("KeyStone", frame)
