local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Bags")

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local NUM_REAGENTBAG_SLOTS = _G.NUM_REAGENTBAG_SLOTS
local NUM_TOTAL_EQUIPPED_BAG_SLOTS = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS
local KEYRING_CONTAINER = _G.KEYRING_CONTAINER
local TEXTURE_ITEM_QUEST_BANG = _G.TEXTURE_ITEM_QUEST_BANG

local GetContainerItemCooldown = _G.C_Container.GetContainerItemCooldown
local GetContainerItemInfo = _G.C_Container.GetContainerItemInfo
local GetContainerItemQuestInfo = _G.C_Container.GetContainerItemQuestInfo
local GetContainerNumFreeSlots = _G.C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = _G.C_Container.GetContainerNumSlots
local SortBags = _G.C_Container.SortBags
local GetKeyRingSize = _G.GetKeyRingSize
local GetItemQualityColor = _G.C_Item.GetItemQualityColor
local CooldownFrame_Set = _G.CooldownFrame_Set
local GameTooltip = _G.GameTooltip
local GameTooltip_Hide = _G.GameTooltip_Hide
local BAG_CLEANUP_BAGS = _G.BAG_CLEANUP_BAGS
local IsBagOpen = _G.IsBagOpen
local OpenAllBags = _G.OpenAllBags
local PlaySound = _G.PlaySound
local hooksecurefunc = _G.hooksecurefunc

-- Mine
local QUEST_COLOR = { r = 1, g = 0.82, b = 0 }
local FOOTER_HEIGHT = 20

local BLIZZARD_BAG_SLOTS = {
    "CharacterBag0Slot",
    "CharacterBag1Slot",
    "CharacterBag2Slot",
    "CharacterBag3Slot",
}

local function IsPlayerBag(bagID)
    return bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS
end

-- blizzard sizes the keyring with GetKeyRingSize, not GetContainerNumSlots
local function GetNumSlots(bagID)
    if bagID == KEYRING_CONTAINER then
        return GetKeyRingSize()
    end
    return GetContainerNumSlots(bagID)
end

local function AnyBagOpen(window)
    for _, bag in ipairs(window.bags) do
        if IsBagOpen(bag:GetID()) then
            return true
        end
    end
    return false
end

local function UpdateSearch(bagID, button)
    local info = GetContainerItemInfo(bagID, button:GetID())
    button.searchOverlay:SetShown(info and info.isFiltered or false)
end

local function UpdateCooldown(bagID, button)
    if button.hasItem then
        local start, duration, enable = GetContainerItemCooldown(bagID, button:GetID())
        CooldownFrame_Set(button.Cooldown, start, duration, enable)

        local shade = (duration > 0 and enable == 0) and 0.4 or 1
        button.icon:SetVertexColor(shade, shade, shade)
    else
        button.Cooldown:Hide()
    end
end

local function UpdateLock(bagID, button)
    local info = GetContainerItemInfo(bagID, button:GetID())
    button.icon:SetDesaturated(info and info.isLocked or false)
end

local function UpdateSlot(bagID, button)
    local slot = button:GetID()
    local info = GetContainerItemInfo(bagID, slot)
    local texture = info and info.iconFileID

    -- read by blizzard for tooltips, dress-up and the cursor, never on the click path
    button.hasItem = texture and 1 or nil
    button.readable = info and info.isReadable

    button.icon:SetTexture(texture)
    button.icon:SetDesaturated(info and info.isLocked or false)
    button.searchOverlay:SetShown(info and info.isFiltered or false)

    local count = info and info.stackCount or 0
    button.Count:SetText(count > 1 and count or "")

    local color = C.general.border.color
    local r, g, b = color.r, color.g, color.b
    local quest = texture and GetContainerItemQuestInfo(bagID, slot)
    if quest and (quest.questID or quest.isQuestItem) then
        r, g, b = QUEST_COLOR.r, QUEST_COLOR.g, QUEST_COLOR.b
    elseif info and info.quality and info.quality > 1 then
        r, g, b = GetItemQualityColor(info.quality)
    end
    button.Backdrop:SetBackdropBorderColor(r, g, b)
    button.IconQuestTexture:SetShown(quest and quest.questID and not quest.isActive or false)

    UpdateCooldown(bagID, button)

    if GameTooltip:GetOwner() == button then
        if texture then
            button:UpdateTooltip()
        else
            GameTooltip:Hide()
        end
    end
end

local element_proto = {}

do
    function element_proto:CreateSlot(bag, slot)
        local size = C.bags.buttons.size
        local name = ("TaintedBag%dSlot%d"):format(bag:GetID(), slot)

        -- the bag is read by blizzard from the parent's id, never from a field on the button (taints)
        local button = CreateFrame("ItemButton", name, bag, "ContainerFrameItemButtonTemplate")
        button:SetID(slot)
        button:SetSize(size, size)
        button:SetNormalTexture(0)
        button:CreateBackdrop()

        -- shown by default in the template; only blizzard's container update hides it
        button.BattlepayItemTexture:Hide()

        -- classic templates only name these children
        button.Cooldown = button.Cooldown or _G[name .. "Cooldown"]
        button.IconQuestTexture = button.IconQuestTexture or _G[name .. "IconQuestTexture"]

        button.icon:ClearAllPoints()
        button.icon:SetAllPoints(button)
        button.icon:SetTexCoord(unpack(E.IconCoord))

        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", 0, 0)
        button.Count:SetFontObject(self.fontObject)
        button.Count:Show()

        button.Cooldown:ClearAllPoints()
        button.Cooldown:SetAllPoints(button)

        button.IconQuestTexture:ClearAllPoints()
        button.IconQuestTexture:SetAllPoints(button)
        button.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)

        bag.slots[slot] = button
        return button
    end

    function element_proto:Layout()
        local size = C.bags.buttons.size
        local spacing = C.bags.buttons.spacing
        local columns = C.bags.buttons.columns

        local index = 0
        for _, bag in ipairs(self.bags) do
            -- reagent bag and keyring start on their own row
            if bag.newRow and bag.numSlots > 0 then
                index = math.ceil(index / columns) * columns
            end

            for slot = 1, math.max(bag.numSlots, #bag.slots) do
                local button = bag.slots[slot]
                if slot <= bag.numSlots then
                    button = button or self:CreateSlot(bag, slot)

                    local column = index % columns
                    local row = math.floor(index / columns)
                    button:ClearAllPoints()
                    button:SetPoint("TOPLEFT", self, "TOPLEFT", spacing + column * (size + spacing), -(spacing + row * (size + spacing)))
                    button:Show()

                    index = index + 1
                else
                    button:Hide()
                end
            end
        end

        local rows = math.max(1, math.ceil(index / columns))
        if self.BagSlots and self.BagSlots:IsShown() then
            self.BagSlots:ClearAllPoints()
            self.BagSlots:SetPoint("TOPLEFT", self, "TOPLEFT", spacing, -(spacing + rows * (size + spacing)))
            rows = rows + 1
        end

        self:SetWidth(columns * (size + spacing) + spacing)
        self:SetHeight(rows * (size + spacing) + spacing + FOOTER_HEIGHT + spacing)
    end

    function element_proto:UpdateFreeSlots()
        local free, total = 0, 0
        for _, bag in ipairs(self.bags) do
            local bagID = bag:GetID()
            if IsPlayerBag(bagID) then
                free = free + GetContainerNumFreeSlots(bagID)
                total = total + bag.numSlots
            end
        end
        self.FreeSlots:SetFormattedText("%d/%d", free, total)
    end

    -- slot counts are only known once bag data is loaded and change when a bag is swapped
    function element_proto:Refresh()
        local changed = false
        for _, bag in ipairs(self.bags) do
            if bag.dirty then
                local numSlots = GetNumSlots(bag:GetID())
                if numSlots ~= bag.numSlots then
                    bag.numSlots = numSlots
                    changed = true
                end
            end
        end

        if changed then
            self:Layout()
        end

        local updated = false
        for _, bag in ipairs(self.bags) do
            if bag.dirty then
                local bagID = bag:GetID()
                for slot = 1, bag.numSlots do
                    UpdateSlot(bagID, bag.slots[slot])
                end
                bag.dirty = false
                updated = true
            end
        end

        if updated then
            self:UpdateFreeSlots()
        end
    end

    function element_proto:UpdateCooldowns()
        for _, bag in ipairs(self.bags) do
            local bagID = bag:GetID()
            for slot = 1, bag.numSlots do
                UpdateCooldown(bagID, bag.slots[slot])
            end
        end
        self.cooldownsDirty = false
    end

    function element_proto:UpdateSearch()
        for _, bag in ipairs(self.bags) do
            local bagID = bag:GetID()
            for slot = 1, bag.numSlots do
                UpdateSearch(bagID, bag.slots[slot])
            end
        end
        self.searchDirty = false
    end

    function element_proto:SetAllDirty()
        for _, bag in ipairs(self.bags) do
            bag.dirty = true
        end
    end

    -- a hidden window only marks what changed; OnShow catches up
    function element_proto:OnEvent(event, bagID, slot)
        if event == "BAG_UPDATE" or event == "BAG_CLOSED" then
            local bag = self.bagsByID[bagID]
            if bag then
                bag.dirty = true
            end
        elseif event == "BAG_UPDATE_DELAYED" then
            if self:IsShown() then
                self:Refresh()
            end
        elseif event == "ITEM_LOCK_CHANGED" then
            local bag = slot and self.bagsByID[bagID]
            if not bag then return end

            if self:IsShown() then
                local button = bag.slots[slot]
                if button and slot <= bag.numSlots then
                    UpdateLock(bagID, button)
                end
            else
                bag.dirty = true
            end
        elseif event == "BAG_UPDATE_COOLDOWN" then
            if self:IsShown() then
                self:UpdateCooldowns()
            else
                self.cooldownsDirty = true
            end
        elseif event == "INVENTORY_SEARCH_UPDATE" then
            if self:IsShown() then
                self:UpdateSearch()
            else
                self.searchDirty = true
            end
        elseif event == "QUEST_ACCEPTED" or event == "QUEST_REMOVED" then
            self:SetAllDirty()
            if self:IsShown() then
                self:Refresh()
            end
        end
    end

    function element_proto:OnShow()
        self:Refresh()
        if self.cooldownsDirty then
            self:UpdateCooldowns()
        end
        if self.searchDirty then
            self:UpdateSearch()
        end
    end
end

function MODULE:CreateBags()
    local element = Mixin(CreateFrame("Frame", "TaintedBags", UIParent), element_proto)
    element:SetPoint("BOTTOMRIGHT", _G.TaintedChatRight, "TOPRIGHT", 0, C.chat.margin)
    element:SetFrameStrata("MEDIUM")
    element:CreateBackdrop("transparent")
    element:EnableMouse(true)
    element:Hide()

    element.fontObject = E.GetFont(C.bags.font)

    local spacing = C.bags.buttons.spacing
    local freeSlots = element:CreateFontString(nil, "OVERLAY")
    freeSlots:SetPoint("BOTTOMRIGHT", -spacing, spacing)
    freeSlots:SetHeight(FOOTER_HEIGHT)
    freeSlots:SetFontObject(element.fontObject)
    element.FreeSlots = freeSlots

    local searchAnchor = freeSlots
    if SortBags then
        element.SortButton = self:CreateSortButton(element)
        searchAnchor = element.SortButton
    end
    element.SearchBox = self:CreateSearchBox(element, searchAnchor)

    if E.isClassic then
        element.BagSlots = self:CreateBagSlots(element)
    end

    element.bags = {}
    element.bagsByID = {}

    local function AddBag(bagID, newRow)
        local bag = CreateFrame("Frame", nil, element)
        bag:SetAllPoints(element)
        bag:SetID(bagID)
        bag.slots = {}
        bag.numSlots = 0
        bag.dirty = true
        bag.newRow = newRow
        element.bags[#element.bags + 1] = bag
        element.bagsByID[bagID] = bag
    end

    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        AddBag(bagID)
    end

    if NUM_REAGENTBAG_SLOTS and NUM_TOTAL_EQUIPPED_BAG_SLOTS then
        for bagID = NUM_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            AddBag(bagID, bagID == NUM_BAG_SLOTS + 1)
        end
    end

    if KEYRING_CONTAINER and GetKeyRingSize then
        AddBag(KEYRING_CONTAINER, true)
    end

    element:SetScript("OnShow", element.OnShow)
    element:SetScript("OnEvent", element.OnEvent)

    for _, event in next, { "BAG_UPDATE", "BAG_CLOSED", "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN", "INVENTORY_SEARCH_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED" } do
        element:RegisterEvent(event)
    end

    return element
end

-- the template sets the item search on text change and clears it on hide
function MODULE:CreateSearchBox(window, anchor)
    local spacing = C.bags.buttons.spacing

    local element = CreateFrame("EditBox", "TaintedBagsSearchBox", window, "BagSearchBoxTemplate")
    element:SetHeight(FOOTER_HEIGHT)
    element:SetPoint("BOTTOMLEFT", spacing, spacing)
    element:SetPoint("RIGHT", anchor, "LEFT", -spacing, 0)
    element:StripTextures("BACKGROUND")
    element:CreateBackdrop()

    return element
end

function MODULE:CreateSortButton(window)
    local element = CreateFrame("Button", nil, window)
    element:SetSize(FOOTER_HEIGHT, FOOTER_HEIGHT)
    element:SetPoint("RIGHT", window.FreeSlots, "LEFT", -C.bags.buttons.spacing, 0)
    element:SetNormalAtlas("bags-button-autosort-up")
    element:SetPushedAtlas("bags-button-autosort-down")

    element:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
        SortBags()
    end)
    element:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(BAG_CLEANUP_BAGS)
        GameTooltip:Show()
    end)
    element:SetScript("OnLeave", GameTooltip_Hide)

    return element
end

-- classic only: the equipped bag slots, shown as a row under the item slots
function MODULE:CreateBagSlots(window)
    local size = C.bags.buttons.size
    local spacing = C.bags.buttons.spacing

    local element = CreateFrame("Frame", nil, window)
    element:SetSize(#BLIZZARD_BAG_SLOTS * (size + spacing) - spacing, size)
    element:Hide()

    local previous
    for _, name in ipairs(BLIZZARD_BAG_SLOTS) do
        local button = _G[name]
        if button then
            button:SetParent(element)
            button:ClearAllPoints()
            button:SetSize(size, size)
            button:CreateBackdrop()

            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
            else
                button:SetPoint("TOPLEFT", element, "TOPLEFT", 0, 0)
            end

            local icon = button.icon or _G[name .. "IconTexture"]
            if icon then
                icon:SetTexCoord(unpack(E.IconCoord))
                icon:SetInside(button.Backdrop or button)
            end

            local normal = _G[name .. "NormalTexture"]
            if normal then
                normal:SetAlpha(0)
            end

            if button.IconBorder then
                button.IconBorder:SetAlpha(0)
            end

            button:SetNormalTexture(0)
            button:SetPushedTexture(0)
            button:SetHighlightTexture(0)
            if button.SetCheckedTexture then
                button:SetCheckedTexture(0)
            end

            previous = button
        end
    end

    return element
end

-- false where the window has no bag-slot row (mainline keeps blizzard's bags bar)
function MODULE:ToggleBagSlots()
    local window = self.Bags
    local slots = window and window.BagSlots
    if not slots then return false end

    slots:SetShown(not slots:IsShown())
    window:Layout()

    if not window:IsShown() then
        OpenAllBags()
    end
    return true
end

-- blizzard keeps its bag state: frames holding a bag of the window are only reparented to the
-- hider, so IsBagOpen stays valid and blizzard still closes them (CloseAllBags, Escape). Classic
-- reuses frames for bank bags, which get their own parent back.
function MODULE:DisableBlizzard(window)
    local parents = {}

    hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, _, bagID)
        parents[frame] = parents[frame] or frame:GetParent()

        if window.bagsByID[bagID] then
            frame:SetParent(E.Hider)
            window:Show()
        else
            frame:SetParent(parents[frame])
        end
    end)
end

function MODULE:Init()
    if not C.bags.enabled then return end

    local window = self:CreateBags()
    self.Bags = window

    self:DisableBlizzard(window)

    if SortBags then
        C_Container.SetSortBagsRightToLeft(true)
        C_Container.SetInsertItemsLeftToRight(true)
    end

    -- the window mirrors blizzard's bag state after every toggle
    local function Update()
        window:SetShown(AnyBagOpen(window))
    end

    for _, name in next, { "ToggleAllBags", "OpenAllBags", "CloseAllBags", "ToggleBag", "ToggleBackpack" } do
        hooksecurefunc(name, Update)
    end
end
