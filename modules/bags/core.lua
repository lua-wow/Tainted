local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:CreateModule("Bags")

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

function MODULE:ToggleAllBags()
    if not UIParent:IsShown() then return end

    E:print("ToggleAllBags")
    if self.Bags:IsShown() and BankFrame:IsShown() and (not self.Bank:IsShown()) then

    end

    
end

function MODULE:Init()
    if not C.bags.enabled then return end
    
    local frame = self

    frame.Bags = frame:CreateBagContainer()
    -- self.Bank = self:CreateBankContainer()

    -- rewrite Blizzard Bags Functions
    _G.ToggleAllBags = function()
        frame:ToggleAllBags()
    end
	
    _G.UpdateContainerFrameAnchors = function() end
	_G.ToggleBag = _G.ToggleAllBags
	_G.ToggleBackpack = _G.ToggleAllBags
    _G.OpenBag = _G.ToggleAllBags
    _G.OpenBackpack = _G.ToggleAllBags
	
    -- function OpenAllBags(frame)
    --     if not UIParent:IsShown() then return end
        
    --     for i = 0, NUM_BAG_FRAMES, 1 do
    --         if (IsBagOpen(i)) then
    --             return;
    --         end
    --     end
    
    --     if( frame and not FRAME_THAT_OPENED_BAGS ) then
    --         FRAME_THAT_OPENED_BAGS = frame:GetName();
    --     end
    
    --     ContainerFrame1.allBags = true;
    --     OpenBackpack();
    --     for i=1, NUM_BAG_FRAMES, 1 do
    --         OpenBag(i);
    --     end
    --     ContainerFrame1.allBags = false;
    --     CheckBagSettingsTutorial();
    -- end
end
