local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Bags")

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local BANK_CONTAINER = _G.BANK_CONTAINER or -1
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
local CloseBag = _G.CloseBag
local OpenBag = _G.OpenBag
local IsBagOpen = _G.IsBagOpen
local OpenAllBags = _G.OpenAllBags
local PlaySound = _G.PlaySound
local hooksecurefunc = _G.hooksecurefunc

-- Mine
local QUEST_COLOR = { r = 1, g = 0.82, b = 0 }
local FOOTER_HEIGHT = 20
local MARGIN = 10
local SECTION_SPACING = 10

-- shared with bank.lua
MODULE.FOOTER_HEIGHT = FOOTER_HEIGHT
MODULE.MARGIN = MARGIN

local BLIZZARD_BAG_SLOTS = {
    "CharacterBag0Slot",
    "CharacterBag1Slot",
    "CharacterBag2Slot",
    "CharacterBag3Slot",
}

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
        local button = CreateFrame("ItemButton", name, bag, bag.template or "ContainerFrameItemButtonTemplate")
        button:SetID(slot)
        button:SetSize(size, size)
        button:SetNormalTexture(0)
        button:CreateBackdrop()

        -- shown by default in the container template; only blizzard's container update hides it
        if button.BattlepayItemTexture then
            button.BattlepayItemTexture:Hide()
        end

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
        local step = size + spacing

        -- sections stack top to bottom, SECTION_SPACING apart; y is the next section's top
        local y = MARGIN
        for _, section in ipairs(self.sections) do
            local total = 0
            for _, bag in ipairs(section) do
                total = total + bag.numSlots
            end

            -- an extra section shorter than a row sits on the right
            local offset = section.extra and (columns - math.min(total, columns)) or 0

            local index = 0
            for _, bag in ipairs(section) do
                for slot = 1, math.max(bag.numSlots, #bag.slots) do
                    local button = bag.slots[slot]
                    if slot <= bag.numSlots then
                        button = button or self:CreateSlot(bag, slot)

                        local column = offset + index % columns
                        local row = math.floor(index / columns)
                        button:ClearAllPoints()
                        button:SetPoint("TOPLEFT", self, "TOPLEFT", MARGIN + column * step, -(y + row * step))
                        button:Show()

                        index = index + 1
                    else
                        button:Hide()
                    end
                end
            end

            if total > 0 then
                y = y + math.ceil(total / columns) * step - spacing + SECTION_SPACING
            end
        end

        if self.BagSlots and self.BagSlots:IsShown() then
            self.BagSlots:ClearAllPoints()
            self.BagSlots:SetPoint("TOPRIGHT", self, "TOPRIGHT", -MARGIN, -y)
            y = y + size + SECTION_SPACING
        end

        self:SetWidth(MARGIN + columns * step - spacing + MARGIN)
        self:SetHeight(y + FOOTER_HEIGHT + MARGIN)
    end

    -- extra sections (reagent bag, keyring) are not counted
    function element_proto:UpdateFreeSlots()
        local free, total = 0, 0
        for _, section in ipairs(self.sections) do
            if not section.extra then
                for _, bag in ipairs(section) do
                    free = free + GetContainerNumFreeSlots(bag:GetID())
                    total = total + bag.numSlots
                end
            end
        end
        self.FreeSlots:SetFormattedText("%d/%d", free, total)
    end

    function element_proto:AddSection(extra)
        local section = { extra = extra }
        self.sections[#self.sections + 1] = section
        return section
    end

    function element_proto:AddBag(section, bagID)
        local bag = CreateFrame("Frame", nil, self)
        bag:SetAllPoints(self)
        bag:SetID(bagID)
        bag.slots = {}
        bag.numSlots = 0
        bag.dirty = true
        section[#section + 1] = bag
        self.bags[#self.bags + 1] = bag
        self.bagsByID[bagID] = bag
        return bag
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
        elseif event == "PLAYERBANKSLOTS_CHANGED" then
            -- the bank container has no BAG_UPDATE; slots past its size are the bank bag slots
            local bag, bankSlot = self.bagsByID[BANK_CONTAINER], bagID
            if not bag then return end

            if self:IsShown() then
                local button = bag.slots[bankSlot]
                if button and bankSlot <= bag.numSlots then
                    UpdateSlot(BANK_CONTAINER, button)
                    self:UpdateFreeSlots()
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

-- a window without bags: sections are added with AddSection/AddBag
function MODULE:CreateWindow(name)
    local element = Mixin(CreateFrame("Frame", name, UIParent), element_proto)
    -- blizzard raises the action bars to MEDIUM whenever the cursor picks something up
    -- (ActionBarMixin:UpdateFrameStrata), above a MEDIUM window
    element:SetFrameStrata("HIGH")
    element:CreateBackdrop("transparent")
    element:EnableMouse(true)
    element:Hide()

    element.fontObject = E.GetFont(C.bags.font)

    local freeSlots = element:CreateFontString(nil, "OVERLAY")
    freeSlots:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)
    freeSlots:SetHeight(FOOTER_HEIGHT)
    freeSlots:SetFontObject(element.fontObject)
    element.FreeSlots = freeSlots

    element.bags = {}
    element.bagsByID = {}
    element.sections = {}

    element:SetScript("OnShow", element.OnShow)
    element:SetScript("OnEvent", element.OnEvent)

    for _, event in next, { "BAG_UPDATE", "BAG_CLOSED", "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN", "INVENTORY_SEARCH_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED" } do
        element:RegisterEvent(event)
    end

    return element
end

function MODULE:CreateBags()
    local element = self:CreateWindow("TaintedBags")
    element:SetPoint("BOTTOMRIGHT", _G.TaintedChatRight, "TOPRIGHT", 0, C.chat.margin)

    local searchAnchor = element.FreeSlots
    -- classic sorts with MODULE:Sort (sort.lua)
    if SortBags or self.Sort then
        element.SortButton = self:CreateSortButton(element)
        searchAnchor = element.SortButton
    end
    element.SearchBox = self:CreateSearchBox(element, searchAnchor)

    if E.isClassic then
        local buttons = {}
        for _, name in ipairs(BLIZZARD_BAG_SLOTS) do
            buttons[#buttons + 1] = _G[name]
        end
        element.BagSlots = self:CreateBagSlots(element, buttons)

        -- the rest of blizzard's bags bar (backpack and keyring buttons) has no use with the window.
        -- Hide alone is not enough: BagsBarMixin shows it again.
        if _G.BagsBar then
            _G.BagsBar:SetParent(E.Hider)
        end
    end

    local section = element:AddSection(false)
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        element:AddBag(section, bagID)
    end

    if NUM_REAGENTBAG_SLOTS and NUM_TOTAL_EQUIPPED_BAG_SLOTS then
        section = element:AddSection(true)
        for bagID = NUM_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            element:AddBag(section, bagID)
        end
    end

    if KEYRING_CONTAINER and GetKeyRingSize then
        element:AddBag(element:AddSection(true), KEYRING_CONTAINER)
    end

    return element
end

-- the template sets the item search on text change and clears it on hide
function MODULE:CreateSearchBox(window, anchor)
    local element = CreateFrame("EditBox", "TaintedBagsSearchBox", window, "BagSearchBoxTemplate")
    element:SetHeight(FOOTER_HEIGHT)
    element:SetPoint("BOTTOMLEFT", MARGIN, MARGIN)
    element:SetPoint("RIGHT", anchor, "LEFT", -C.bags.buttons.spacing, 0)
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
        if SortBags then
            SortBags()
        else
            MODULE:Sort()
        end
    end)
    element:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(BAG_CLEANUP_BAGS)
        GameTooltip:Show()
    end)
    element:SetScript("OnLeave", GameTooltip_Hide)

    return element
end

-- classic only: blizzard's bag slot buttons (equipped or bank bags), shown as a row under the item slots
function MODULE:CreateBagSlots(window, buttons)
    local size = C.bags.buttons.size
    local spacing = C.bags.buttons.spacing

    local element = CreateFrame("Frame", nil, window)
    element:SetSize(#buttons * (size + spacing) - spacing, size)

    for _, button in ipairs(buttons) do
        local name = button:GetName()

        button:SetParent(element)
        button:SetSize(size, size)
        button:CreateBackdrop()

        local icon = button.icon or (name and _G[name .. "IconTexture"])
        if icon then
            icon:SetTexCoord(unpack(E.IconCoord))
            icon:SetInside(button.Backdrop or button)
        end

        local normal = name and _G[name .. "NormalTexture"]
        if normal then
            normal:SetAlpha(0)
        end

        if button.IconBorder then
            button.IconBorder:SetAlpha(0)
        end

        -- bank bag slots glow while their (hidden) blizzard container frame is open (UpdateBagButtonHighlight)
        if button.HighlightFrame then
            button.HighlightFrame:Hide()
        end

        button:SetNormalTexture(0)
        button:SetPushedTexture(0)
        button:SetHighlightTexture(0)
        if button.SetCheckedTexture then
            button:SetCheckedTexture(0)
        end
    end

    -- BagsBarMixin:Layout re-anchors every bag button to the backpack button, also through closures
    -- that bypass a hook on BagsBar.Layout, so each button is anchored back whenever it is moved
    local offsets = {}
    local function Anchor(button)
        local _, relativeTo = button:GetPoint()
        if relativeTo == element then return end

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", element, "TOPLEFT", offsets[button], 0)
    end

    for index, button in ipairs(buttons) do
        offsets[button] = (index - 1) * (size + spacing)
        Anchor(button)
        hooksecurefunc(button, "SetPoint", Anchor)
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

-- blizzard keeps its bag state: frames holding a bag of a window are only reparented to the
-- hider, so IsBagOpen stays valid and blizzard still closes them (CloseAllBags, Escape). On classic
-- the bank bags are opened by ToggleAllBags at the bank; the bank window follows the bank session
-- instead. Frames reused for any other bag get their own parent back.
function MODULE:DisableBlizzard(window, bank)
    local parents = {}

    hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, _, bagID)
        parents[frame] = parents[frame] or frame:GetParent()

        if window.bagsByID[bagID] then
            frame:SetParent(E.Hider)
            window:Show()
        elseif bank and bank.bagsByID[bagID] then
            frame:SetParent(E.Hider)
        else
            frame:SetParent(parents[frame])
        end
    end)
end

function MODULE:Init()
    if not C.bags.enabled then return end

    local window = self:CreateBags()
    self.Bags = window

    -- classic only (bank.lua)
    if self.CreateBank then
        self.Bank = self:CreateBank()
    end

    self:DisableBlizzard(window, self.Bank)

    if SortBags then
        C_Container.SetSortBagsRightToLeft(true)
        C_Container.SetInsertItemsLeftToRight(true)
    end

    local bank = self.Bank
    local function CloseBags(element)
        for _, bag in ipairs(element.bags) do
            local bagID = bag:GetID()
            if IsBagOpen(bagID) then
                CloseBag(bagID)
            end
        end
    end

    -- OpenAllBags does nothing while any bag is open
    local function OpenBags(element)
        for _, bag in ipairs(element.bags) do
            local bagID = bag:GetID()
            if not IsBagOpen(bagID) then
                OpenBag(bagID)
            end
        end
    end

    -- the window is open while the backpack is. Blizzard's close functions (CloseAllBags on Escape,
    -- ToggleAllBags) leave the keyring open, so the window's other bags close with the backpack.
    local function Update()
        local shown = IsBagOpen(BACKPACK_CONTAINER) and true or false
        if not shown then
            CloseBags(window)
        end
        window:SetShown(shown)
    end

    for _, name in next, { "OpenAllBags", "CloseAllBags", "ToggleBackpack" } do
        hooksecurefunc(name, Update)
    end

    -- at the bank, ToggleAllBags with every bag open closes them, then reopens them with the bank bags
    hooksecurefunc("ToggleAllBags", function()
        if bank and AnyBagOpen(bank) then
            CloseBags(window)
            CloseBags(bank)
        end
        Update()
    end)

    -- the window shows every bag, so one bag toggles them all: a single closed bag would make
    -- ToggleAllBags reopen the bags instead of closing them. A bank bag frame shows nothing, and an
    -- open one would read as the bank case above.
    hooksecurefunc("ToggleBag", function(bagID)
        if window.bagsByID[bagID] then
            if IsBagOpen(bagID) then
                OpenBags(window)
            else
                CloseBags(window)
            end
        elseif bank and bank.bagsByID[bagID] then
            CloseBag(bagID)
        end
        Update()
    end)
end
