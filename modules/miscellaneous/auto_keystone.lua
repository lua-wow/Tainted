local _, ns = ...
local C = ns.C

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4

--------------------------------------------------
-- Auto Keystone
--------------------------------------------------
if not C.miscellaneous.mythic.autokeystone then return end

local IsKeystone = function(itemID)
    -- instant variant: works for items not yet in the client cache
    local classID, subclassID = select(6, C_Item.GetItemInfoInstant(itemID))
    return (classID == Enum.ItemClass.Reagent and subclassID == Enum.ItemReagentSubclass.Keystone)
end

local GetKeystone = function()
    for containerIndex = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(containerIndex) or 0
        if slots > 0 then
            for slotIndex = 1, slots do
                local itemID = C_Container.GetContainerItemID(containerIndex, slotIndex)
                if itemID and IsKeystone(itemID) then
                    return containerIndex, slotIndex
                end
            end
        end
    end
end

-- using the key while the receptacle is shown slots it, as a bag click does
local UseKeystone = function(containerIndex, slotIndex)
    C_Container.UseContainerItem(containerIndex, slotIndex)
end

-- Blizzard's drag path (ChallengesKeystoneSlotMixin:OnReceiveDrag): key on the cursor, then slot it.
-- Alternative to UseKeystone if that stops slotting; unverified in-game. On failure the key stays
-- on the cursor and a click on the slot finishes the job.
local SlotKeystone = function(containerIndex, slotIndex) -- luacheck: ignore
    if CursorHasItem() then return end -- picking up would drop the cursor item into the bag slot
    C_Container.PickupContainerItem(containerIndex, slotIndex)
    C_ChallengeMode.SlotKeystone()
end

local keystone_proto = {}

function keystone_proto:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function keystone_proto:OnShow()
    local containerIndex, slotIndex = GetKeystone()
    if containerIndex then
        UseKeystone(containerIndex, slotIndex) -- or SlotKeystone
    end
end

function keystone_proto:Hook()
    local frame = _G.ChallengesKeystoneFrame
    if frame then
        frame:HookScript("OnShow", self.OnShow)
    end
end

function keystone_proto:ADDON_LOADED(addon)
    if addon ~= "Blizzard_ChallengesUI" then return end
    self:Hook()
    self:UnregisterEvent("ADDON_LOADED")
end

local keystone = Mixin(CreateFrame("Frame"), keystone_proto)
-- load-on-demand: another addon may have loaded it before us
if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
    keystone:Hook()
else
    keystone:RegisterEvent("ADDON_LOADED")
    keystone:SetScript("OnEvent", keystone.OnEvent)
end
