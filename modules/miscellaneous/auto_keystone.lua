local _, ns = ...
local E = ns.E

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4

-- Mine
local IsKeystone = function(itemID)
    local classID, subclassID = select(12, C_Item.GetItemInfo(itemID))
    return (classID == Enum.ItemClass.Reagent and subclassID == Enum.ItemReagentSubclass.Keystone)
end

local GetKeystone = function()
    for containerIndex = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(containerIndex) or 0
        if slots > 0 then
            for slotIndex = 1, slots do
                local itemID = C_Container.GetContainerItemID(containerIndex, slotIndex)
                if itemID and IsKeystone(itemID) then
                    -- "|cffa335ee|Hkeystone:180653:353:7:160:10:152:0|h[Keystone: Siege of Boralus (7)]|h|r"
                    local itemLink = C_Container.GetContainerItemLink(containerIndex, slotIndex)
                    
                    return {
                        containerIndex = containerIndex,
                        slotIndex = slotIndex,
                        itemID = itemID,
                        itemLink = itemLink
                    }
                end
            end
        end
    end
    return nil
end

local keystone_proto = {}

function keystone_proto:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function keystone_proto:OnShow()
    local keystoneInfo = GetKeystone()
    if keystoneInfo then
        C_Container.UseContainerItem(keystoneInfo.containerIndex, keystoneInfo.slotIndex)
    end
end

function keystone_proto:ADDON_LOADED(addon)
    if addon ~= "Blizzard_ChallengesUI" then return end

    local frame = _G.ChallengesKeystoneFrame
    if not frame then return end

    frame:HookScript("OnShow", self.OnShow)
    
    self:UnregisterEvent("ADDON_LOADED")
end

local keystone = Mixin(CreateFrame("Frame", "TaintedAutoKeystone"), keystone_proto)
keystone:RegisterEvent("ADDON_LOADED")
keystone:SetScript("OnEvent", keystone.OnEvent)
