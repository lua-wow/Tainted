local _, ns = ...

local NUM_BAG_FRAMES = _G.NUM_BAG_FRAMES or 4

local IsKeystone = function(itemId)
    if itemId then
        local classID, subclassID = select(12, C_Item.GetItemInfo(itemId))
        return (classID == Enum.ItemClass.Reagent and subclassID == Enum.ItemReagentSubclass.Keystone)
    end
    return false
end

local keystone = CreateFrame("Frame", "TaintedAutoKeystone")
keystone:RegisterEvent("ADDON_LOADED")
keystone:SetScript("OnEvent", function(self, event, ...)
    if event ~= "ADDON_LOADED" then return end

    local addon = ...
    if addon ~= "Blizzard_ChallengesUI" then return end

    local frame = _G.ChallengesKeystoneFrame
    if not frame then return end

    frame:HookScript("OnShow", self.OnShow)
    
    self:UnregisterEvent(event)
end)

function keystone:OnShow()
    for containerIndex = 1, NUM_BAG_FRAMES do
        local slots = C_Container.GetContainerNumSlots(containerIndex) or 0
        if slots > 0 then
            for slotIndex = 1, slots do
                local itemId = C_Container.GetContainerItemID(containerIndex, slotIndex)
                if IsKeystone(itemId) then
                    return C_Container.UseContainerItem(containerIndex, slotIndex)
                end
            end
        end
    end
end
