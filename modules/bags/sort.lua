local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Bags")

-- Blizzard
local ITEM_CLASS_CONTAINER = _G.Enum.ItemClass.Container
local ITEM_CLASS_QUIVER = _G.Enum.ItemClass.Quiver
local ITEM_QUALITY_POOR = _G.Enum.ItemQuality.Poor

local ClearCursor = _G.ClearCursor
local CursorHasItem = _G.CursorHasItem
local GetContainerItemInfo = _G.C_Container.GetContainerItemInfo
local GetContainerNumFreeSlots = _G.C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = _G.C_Container.GetContainerNumSlots
local PickupContainerItem = _G.C_Container.PickupContainerItem
local SplitContainerItem = _G.C_Container.SplitContainerItem
local GetItemFamily = _G.C_Item.GetItemFamily
local GetItemInfoInstant = _G.C_Item.GetItemInfoInstant
local GetItemMaxStackSizeByID = _G.C_Item.GetItemMaxStackSizeByID
local InCombatLockdown = _G.InCombatLockdown
local band = _G.bit.band

-- Mine
local HEARTHSTONE = 6948
-- a sort that stops making progress (rejected moves, data that never loads) gives up
local MAX_WAIT = 300 -- frames
local MAX_MOVES_PER_SLOT = 3

-- static per item id; nil while the client has no data for the item yet
local itemData = {}

local function GetItemData(itemID)
    local data = itemData[itemID]
    if not data then
        local _, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(itemID)
        local maxStack = GetItemMaxStackSizeByID(itemID)
        if not (classID and maxStack) then return end

        -- a bag's own family is the family it holds; bags never go into a special bag
        local family = 0
        if classID ~= ITEM_CLASS_CONTAINER and classID ~= ITEM_CLASS_QUIVER then
            family = GetItemFamily(itemID) or 0
        end

        data = { classID = classID, subClassID = subClassID, equipLoc = equipLoc, maxStack = maxStack, family = family }
        itemData[itemID] = data
    end
    return data
end

-- every slot of the bags in window order; nil while a slot is locked or an item has no data yet
local function Read(bagIDs)
    local slots = {}
    for _, bagID in ipairs(bagIDs) do
        local _, family = GetContainerNumFreeSlots(bagID)
        for slot = 1, GetContainerNumSlots(bagID) do
            local entry = { bag = bagID, slot = slot, family = family or 0 }
            local info = GetContainerItemInfo(bagID, slot)
            if info then
                local data = GetItemData(info.itemID)
                if info.isLocked or not data or not info.quality then return end

                -- stackable items are interchangeable; others keep their suffix/enchant apart
                entry.key = data.maxStack > 1 and info.itemID or info.hyperlink
                entry.count = info.stackCount
                entry.itemID = info.itemID
                entry.name = info.itemName
                entry.quality = info.quality
                entry.data = data
            end
            slots[#slots + 1] = entry
        end
    end
    return slots
end

local function Compare(a, b)
    if (a.itemID == HEARTHSTONE) ~= (b.itemID == HEARTHSTONE) then
        return a.itemID == HEARTHSTONE
    end
    local da, db = a.data, b.data
    if da.classID ~= db.classID then return da.classID < db.classID end
    -- descending, like retail's sort: food before flasks before potions
    if da.subClassID ~= db.subClassID then return da.subClassID > db.subClassID end
    if da.equipLoc ~= db.equipLoc then return da.equipLoc < db.equipLoc end
    if a.quality ~= b.quality then return a.quality > b.quality end
    if a.name ~= b.name then return a.name < b.name end
    if a.itemID ~= b.itemID then return a.itemID < b.itemID end
    return a.key < b.key
end

local function Fits(slot, data)
    return slot.family == 0 or band(data.family, slot.family) ~= 0
end

-- sets slot.target (an item and a count) for every slot that should hold something.
-- Special bags take what fits them first, then normal slots fill from the first one,
-- junk backwards from the last one. Full stacks come before the remainder.
local function Plan(slots)
    local items, byKey = {}, {}
    for _, slot in ipairs(slots) do
        if slot.key then
            local item = byKey[slot.key]
            if not item then
                item = { key = slot.key, itemID = slot.itemID, name = slot.name, quality = slot.quality, data = slot.data, count = 0 }
                byKey[slot.key] = item
                items[#items + 1] = item
            end
            item.count = item.count + slot.count
        end
    end
    table.sort(items, Compare)

    local stacks = {}
    for _, item in ipairs(items) do
        local count, max = item.count, item.data.maxStack
        while count > 0 do
            local size = math.min(count, max)
            stacks[#stacks + 1] = { item = item, count = size }
            count = count - size
        end
    end

    local normal = {}
    for _, slot in ipairs(slots) do
        if slot.family == 0 then
            normal[#normal + 1] = slot
        else
            for _, stack in ipairs(stacks) do
                if not stack.placed and Fits(slot, stack.item.data) then
                    stack.placed = true
                    slot.target = stack
                    break
                end
            end
        end
    end

    local first, last = 1, #normal
    for _, stack in ipairs(stacks) do
        if first > last then break end
        if not stack.placed then
            if stack.item.quality == ITEM_QUALITY_POOR then
                normal[last].target = stack
                last = last - 1
            else
                normal[first].target = stack
                first = first + 1
            end
        end
    end
end

local function IsDone(slot)
    local target = slot.target
    if target then
        return slot.key == target.item.key and slot.count == target.count
    end
    return not slot.key
end

local function Find(slots, test)
    for _, slot in ipairs(slots) do
        if test(slot) then
            return slot
        end
    end
end

local function Move(from, to)
    PickupContainerItem(from.bag, from.slot)
    PickupContainerItem(to.bag, to.slot)
end

-- one move toward the plan, on the first slot that is not done; false when nothing can move
local function Step(slots)
    for _, dst in ipairs(slots) do
        local target = dst.target
        if target and not IsDone(dst) then
            local key = target.item.key

            if dst.key == key and dst.count > target.count then
                -- too many: split the excess onto a short stack of the item, or an empty slot
                local to = Find(slots, function(s)
                    return s ~= dst and s.key == key and s.target and s.target.item.key == key and s.count < s.target.count
                end) or Find(slots, function(s)
                    return not s.key and Fits(s, dst.data)
                end)
                if to then
                    SplitContainerItem(dst.bag, dst.slot, dst.count - target.count)
                    PickupContainerItem(to.bag, to.slot)
                    return true
                end
            elseif dst.key == key then
                -- too few: top up from a stack of the item that is not in place
                local from = Find(slots, function(s)
                    return s ~= dst and s.key == key and not IsDone(s)
                end)
                if from then
                    Move(from, dst)
                    return true
                end
            else
                -- wrong item or empty: swap the target item in, prefering a stack of the right size.
                -- What dst holds goes to the source slot, which must accept it.
                local function Source(s)
                    return s ~= dst and s.key == key and not IsDone(s) and (not dst.key or Fits(s, dst.data))
                end
                local from = Find(slots, function(s) return Source(s) and s.count == target.count end)
                    or Find(slots, Source)
                if from then
                    Move(from, dst)
                    return true
                end

                -- no source takes what dst holds: move it out to an empty slot first
                local to = dst.key and Find(slots, function(s)
                    return not s.key and Fits(s, dst.data)
                end)
                if to then
                    Move(dst, to)
                    return true
                end
            end
        end
    end
    return false
end

-- one frame, one move; the next move waits for the locks of the last one to clear
local driver = CreateFrame("Frame")
driver:Hide()

local queue = {}
local waits, moves, maxMoves = 0, 0, 0

local function Begin()
    local bagIDs = queue[1]
    if not bagIDs then
        driver:Hide()
        return
    end

    waits, moves, maxMoves = 0, 0, 0
    for _, bagID in ipairs(bagIDs) do
        maxMoves = maxMoves + GetContainerNumSlots(bagID) * MAX_MOVES_PER_SLOT
    end
    driver:Show()
end

local function Next()
    table.remove(queue, 1)
    Begin()
end

driver:SetScript("OnUpdate", function()
    -- a rejected move leaves the item on the cursor
    if CursorHasItem() then
        ClearCursor()
        return
    end

    local slots = Read(queue[1])
    if not slots then
        waits = waits + 1
        if waits > MAX_WAIT then
            Next()
        end
        return
    end

    Plan(slots)
    if moves >= maxMoves or not Step(slots) then
        Next()
    else
        waits, moves = 0, moves + 1
    end
end)

-- combat aborts; the bank sort needs the bank
driver:SetScript("OnEvent", function()
    table.wipe(queue)
    driver:Hide()
end)
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("BANKFRAME_CLOSED")

-- the bags of the window's main section (no keyring)
local function GetBagIDs(window)
    local bagIDs = {}
    for _, section in ipairs(window.sections) do
        if not section.extra then
            for _, bag in ipairs(section) do
                bagIDs[#bagIDs + 1] = bag:GetID()
            end
        end
    end
    return bagIDs
end

-- classic has no C_Container.SortBags; the bags, then the open bank (C.bags.sort_bank), are sorted apart
function MODULE:Sort()
    if driver:IsShown() or InCombatLockdown() then return end

    queue[1] = GetBagIDs(self.Bags)
    if C.bags.sort_bank and self.Bank and self.Bank:IsShown() then
        queue[2] = GetBagIDs(self.Bank)
    end

    Begin()
end
