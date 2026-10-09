local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Bags")

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4

local GetContainerNumSlots = _G.C_Container.GetContainerNumSlots
local IsBagOpen = _G.IsBagOpen
local hooksecurefunc = _G.hooksecurefunc

-- Mine
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

local element_proto = {}

do
    function element_proto:CreateSlot(bag, slot)
        local size = C.bags.buttons.size

        -- the bag is read by blizzard from the parent's id, never from a field on the button (taints)
        local button = CreateFrame("ItemButton", ("TaintedBag%dSlot%d"):format(bag:GetID(), slot), bag, "ContainerFrameItemButtonTemplate")
        button:SetID(slot)
        button:SetSize(size, size)
        button:SetNormalTexture(0)
        button:CreateBackdrop()

        -- shown by default in the template; only blizzard's container update hides it
        button.BattlepayItemTexture:Hide()

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

        local rows = math.max(1, math.ceil(index / columns))
        self:SetWidth(columns * (size + spacing) + spacing)
        self:SetHeight(rows * (size + spacing) + spacing)
    end

    -- slot counts are only known once bag data is loaded and change when a bag is swapped
    function element_proto:OnShow()
        local changed = false
        for _, bag in ipairs(self.bags) do
            local numSlots = GetContainerNumSlots(bag:GetID())
            if numSlots ~= bag.numSlots then
                bag.numSlots = numSlots
                changed = true
            end
        end

        if changed then
            self:Layout()
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

    element.bags = {}
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local bag = CreateFrame("Frame", nil, element)
        bag:SetAllPoints(element)
        bag:SetID(bagID)
        bag.slots = {}
        bag.numSlots = 0
        element.bags[#element.bags + 1] = bag
    end

    element:SetScript("OnShow", element.OnShow)

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
