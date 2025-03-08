local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Containers")

-- Blizzard

-- Mine
local itemFamilyIDs = {
	[1] = "Arrows",
	[2] = "Bullets",
	[3] = "Soul Shards",
	[4] = "Leatherworking Supplies",
	[5] = "Inscription Supplies",
	[6] = "Herbs",
	[7] = "Enchanting Supplies",
	[8] = "Engineering Supplies",
	[9] = "Keys",
	[10] = "Gems",
	[11] = "Mining Supplies",
	[12] = "Soulbound Equipment",
	[13] = "Vanity Pets",
	[14] = "Currency Tokens",
	[15] = "Quest Items",
	[16] = "Fishing Supplies",
	[17] = "Cooking Supplies",
	[20] = "Toys",
	[21] = "Archaeology",
	[22] = "Alchemy",
	[23] = "Blacksmithing",
	[24] = "First Aid",
	[25] = "Jewelcrafting",
	[26] = "Skinning",
	[27] = "Tailoring",
}

local BlizzardBags = {
	"CharacterBag0Slot",
	"CharacterBag1Slot",
	"CharacterBag2Slot",
	"CharacterBag3Slot",
	"CharacterReagentBag0Slot",
}

local container_proto = {}

do
    function container_proto:GetContainerNumSlots(containerIndex)
        if (containerIndex == KEYRING_CONTAINER) then
            return GetKeyRingSize()
        end
        return C_Container.GetContainerNumSlots(containerIndex)
    end
    
    -- function container_proto:GetBagType(index)
    --     local numFreeSlots, bagType = C_Container.GetContainerNumFreeSlots(index)
        
    --     if bit.band(bagType, BAGTYPE_QUIVER) > 0 then
    --         return Bag_Quiver
    --     elseif bit.band(bagType, BAGTYPE_SOUL) > 0 then
    --         return Bag_SoulShard
    --     elseif bit.band(bagType, BAGTYPE_PROFESSION) > 0 then
    --         return Bag_Profession
    --     end
    
    --     return Bag_Normal
    -- end

    function container_proto:Create()
        E:error(self:GetName() .. ".Create not implemented")
    end
end

function MODULE:CreateSlotsContainer()
    local size = 20 --C.bags.buttons.size or 32
    local spacing = C.bags.buttons.spacing or 5
    local xOffset = -(C.general.margin or 10)
    local yOffset = 140 --C.general.margin + C.chat.height

    local element = CreateFrame("Frame") --, "TaintedSlotContainers", self)
    element:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", xOffset, yOffset)
    element:SetHeight(size)
    element:CreateBackdrop()

    local num = 0
    local previous = nil
    for index, bag in next, BlizzardBags do
        local button = _G[bag]
        if button then
            button:SetParent(element)
            button:ClearAllPoints()
            button:SetSize(size, size)
            button:CreateBackdrop()

            if not previous then
                button:SetPoint("TOPRIGHT", element, "TOPRIGHT", 0, 0)
            else
                button:SetPoint("RIGHT", previous, "LEFT", -spacing, 0)
            end

            local icon = button.icon or _G[button:GetName() .. "IconTexture"]
            if icon then
                icon:SetTexCoord(unpack(E.IconCoord))
                icon:SetInside(button.Backdrop or button)
            end

            local NormalTexture = _G[button:GetName() .. "NormalTexture"]
            if NormalTexture then
                NormalTexture:SetAlpha(0)
            end

            -- local count = button.Count or _G[button:GetName() .. "Count"]
            -- if count then
            --     count:Hide()
            -- end

            if button.IconBorder then
                button.IconBorder:SetAlpha(0)
            end

            if button.SetNormalTexture then
                button:SetNormalTexture("")
            end

            if button.SetPushedTexture then
                button:SetPushedTexture("")
            end

            if button.SetCheckedTexture then
                button:SetCheckedTexture("")
            end

            if button.SetHighlightTexture then
                button:SetHighlightTexture("")
            end

            previous = button

            num = num + 1
        end
    end

    element:SetWidth((num * size) + ((num - 1) * spacing))

    return element
end

function MODULE:CreateContainer(storagetype, element_proto)
    local element = Mixin(CreateFrame("Frame", "Tainted" .. storagetype, UIParent), container_proto, element_proto)
    element:SetPoint(unpack(element.anchor))
    element:SetWidth(200)
    element:SetHeight(200)
    element:SetFrameStrata("LOW")
    element:SetFrameLevel(20)
    element:CreateBackdrop("transparent")
    element:EnableMouse(true)
    -- element:Hide()

    element:Create()

    self[storagetype] = element

    return element
end

function MODULE:Toggle()
    local frame = self.SlotContainers
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function MODULE:Init()
    -- if not C.bags.enabled then return end
    
    local frame = self
    frame.SlotContainers = self:CreateSlotsContainer()
    frame.SlotContainers:Hide()
end
