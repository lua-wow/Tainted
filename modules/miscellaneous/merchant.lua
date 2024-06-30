local _, ns = ...
local E, C, L = ns.E, ns.c, ns.L

-- Blizzard
local CanMerchantRepair = _G.CanMerchantRepair
local GetRepairAllCost = _G.GetRepairAllCost
local RepairAllItems = _G.RepairAllItems
local GetMoney = _G.GetMoney

local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or _G.GetContainerItemLink
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo or _G.GetContainerItemInfo
local UseContainerItem = C_Container and C_Container.UseContainerItem or _G.UseContainerItem
local GetItemInfo = _G.GetItemInfo

--------------------------------------------------
-- Merchant
--------------------------------------------------
local function ToMoneyText(money)
    local gold = math.floor(money / 10000)
    local silver = math.floor(money / 100 % 100)
    local copper = money % 100
    return "|cffffffff" .. gold .. L.gold .. " |cffffffff" .. silver .. L.silver .. " |cffffffff" .. copper .. L.copper
end

local function AutoRepair()
    -- check if the merchant can repair
    if CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair and repairCost > 0 then
            -- check if the player can afford the repair
            if repairCost <= GetMoney() then
                RepairAllItems()
                local message = string.format(L.merchant.repairCost, ToMoneyText(repairCost))
                DEFAULT_CHAT_FRAME:AddMessage(message, 255, 255, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage(L.merchant.notEnoughMoney, 255, 0, 0)
            end
        end
    end
end

local function SellJunkRetail()
    local numJunkItems = C_MerchantFrame.GetNumJunkItems()
    if C_MerchantFrame.IsSellAllJunkEnabled() and (numJunkItems > 0) then
        C_MerchantFrame.SellAllJunkItems()
        local message = string.format(L.merchant.junkSold, "")
        DEFAULT_CHAT_FRAME:AddMessage(message, 255, 255, 0)
    end
end

local function SellJunkClassic()
    local total = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
                expacID, setID, isCraftingReagent = GetItemInfo(itemLink)
                local containerItemInfo = GetContainerItemInfo(bag, slot)
                local stackCount = containerItemInfo and containerItemInfo.stackCount or 0
                if (itemQuality == 0) and (sellPrice > 0) then
                    total = total + (sellPrice * stackCount)
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
    if (total > 0) then
        local message = string.format(L.merchant.junkSold, " for " .. ToMoneyText(total))
        DEFAULT_CHAT_FRAME:AddMessage(message, 255, 255, 0)
    end
end

local SellJunk = E.isRetail and SellJunkRetail or SellJunkClassic

local function OnMerchantShow()
    AutoRepair()
    SellJunk()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", OnMerchantShow)
