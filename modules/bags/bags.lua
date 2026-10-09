local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Bags")

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local TEXTURE_ITEM_QUEST_BANG = _G.TEXTURE_ITEM_QUEST_BANG

local GetContainerItemCooldown = _G.C_Container.GetContainerItemCooldown
local GetContainerItemInfo = _G.C_Container.GetContainerItemInfo
local GetContainerItemQuestInfo = _G.C_Container.GetContainerItemQuestInfo
local GetContainerNumFreeSlots = _G.C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = _G.C_Container.GetContainerNumSlots
local GetItemQualityColor = _G.C_Item.GetItemQualityColor
local CooldownFrame_Set = _G.CooldownFrame_Set
local GameTooltip = _G.GameTooltip
local IsBagOpen = _G.IsBagOpen
local hooksecurefunc = _G.hooksecurefunc

-- Mine
local QUEST_COLOR = { r = 1, g = 0.82, b = 0 }

local function IsPlayerBag(bagID)
    return bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS
end

local function AnyPlayerBagOpen()
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        if IsBagOpen(bagID) then
            return true
        end
    end
    return false
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

        local _, fontHeight = self.fontObject:GetFont()
        local rows = math.max(1, math.ceil(index / columns))
        self:SetWidth(columns * (size + spacing) + spacing)
        self:SetHeight(rows * (size + spacing) + spacing + fontHeight + spacing)
    end

    function element_proto:UpdateFreeSlots()
        local free, total = 0, 0
        for _, bag in ipairs(self.bags) do
            free = free + GetContainerNumFreeSlots(bag:GetID())
            total = total + bag.numSlots
        end
        self.FreeSlots:SetFormattedText("%d/%d", free, total)
    end

    -- slot counts are only known once bag data is loaded and change when a bag is swapped
    function element_proto:Refresh()
        local changed = false
        for _, bag in ipairs(self.bags) do
            if bag.dirty then
                local numSlots = GetContainerNumSlots(bag:GetID())
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
    freeSlots:SetFontObject(element.fontObject)
    element.FreeSlots = freeSlots

    element.bags = {}
    element.bagsByID = {}
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local bag = CreateFrame("Frame", nil, element)
        bag:SetAllPoints(element)
        bag:SetID(bagID)
        bag.slots = {}
        bag.numSlots = 0
        bag.dirty = true
        element.bags[#element.bags + 1] = bag
        element.bagsByID[bagID] = bag
    end

    element:SetScript("OnShow", element.OnShow)
    element:SetScript("OnEvent", element.OnEvent)

    for _, event in next, { "BAG_UPDATE", "BAG_CLOSED", "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN", "QUEST_ACCEPTED", "QUEST_REMOVED" } do
        element:RegisterEvent(event)
    end

    return element
end

-- blizzard keeps its bag state: frames holding a player bag are only reparented to the hider,
-- so IsBagOpen stays valid and blizzard still closes them (CloseAllBags, Escape). Classic reuses
-- frames for bank bags and the keyring, which get their own parent back.
function MODULE:DisableBlizzard(window)
    local parents = {}

    hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, _, bagID)
        parents[frame] = parents[frame] or frame:GetParent()

        if IsPlayerBag(bagID) then
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

    -- the window mirrors blizzard's bag state after every toggle
    local function Update()
        window:SetShown(AnyPlayerBagOpen())
    end

    for _, name in next, { "ToggleAllBags", "OpenAllBags", "CloseAllBags", "ToggleBag", "ToggleBackpack" } do
        hooksecurefunc(name, Update)
    end
end
