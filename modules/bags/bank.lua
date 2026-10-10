local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Bags")

-- Blizzard
local BANK_CONTAINER = _G.BANK_CONTAINER or -1
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local NUM_BANKBAGSLOTS = _G.NUM_BANKBAGSLOTS
local NUM_BANKGENERIC_SLOTS = _G.NUM_BANKGENERIC_SLOTS
local BANKSLOTPURCHASE = _G.BANKSLOTPURCHASE
local BANK_BAG_PURCHASE = _G.BANK_BAG_PURCHASE
local COSTS_LABEL = _G.COSTS_LABEL

local BankFrameItemButton_Update = _G.BankFrameItemButton_Update
local CloseAllBags = _G.CloseAllBags
local CloseBankFrame = _G.CloseBankFrame
local GameTooltip = _G.GameTooltip
local GameTooltip_Hide = _G.GameTooltip_Hide
local GetBankSlotCost = _G.GetBankSlotCost
local GetMoneyString = _G.GetMoneyString
local GetNumBankSlots = _G.GetNumBankSlots
local OpenAllBags = _G.OpenAllBags
local PlaySound = _G.PlaySound
local StaticPopup_Show = _G.StaticPopup_Show
local UpdateBagSlotStatus = _G.UpdateBagSlotStatus

local bank_proto = {}

do
    function bank_proto:UpdateBagSlots()
        for _, button in ipairs(self.bagSlotButtons) do
            BankFrameItemButton_Update(button)
        end

        -- tints the slots not bought yet and sets BankFrame.nextSlotCost, read by the purchase popup
        UpdateBagSlotStatus()

        local _, full = GetNumBankSlots()
        self.PurchaseButton:SetShown(not full)
    end

    -- the window follows the bank session; blizzard's BankFrame only keeps it open
    function bank_proto:OnBankEvent(event, ...)
        if event == "BANKFRAME_OPENED" then
            self:SetAllDirty()
            self:Show()
            self:UpdateBagSlots()
            OpenAllBags(self)
        elseif event == "BANKFRAME_CLOSED" then
            self:Hide()
        elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
            self:UpdateBagSlots()
        elseif event == "PLAYERBANKSLOTS_CHANGED" and ... > NUM_BANKGENERIC_SLOTS then
            self:UpdateBagSlots()
        else
            self:OnEvent(event, ...)
        end
    end

    -- also reached by Escape (UISpecialFrames); CloseAllBags only closes the bags the bank opened
    function bank_proto:OnHide()
        CloseAllBags(self)
        CloseBankFrame()
    end
end

function MODULE:CreateBank()
    local element = Mixin(self:CreateWindow("TaintedBank"), bank_proto)
    element:SetPoint("BOTTOMLEFT", _G.TaintedChatLeft, "TOPLEFT", 0, C.chat.margin)

    element.PurchaseButton = self:CreatePurchaseButton(element)

    element.bagSlotButtons = {}
    for index = 1, NUM_BANKBAGSLOTS do
        element.bagSlotButtons[index] = _G.BankSlotsFrame["Bag" .. index]
    end
    element.BagSlots = self:CreateBagSlots(element, element.bagSlotButtons)

    local section = element:AddSection(false)
    element:AddBag(section, BANK_CONTAINER).template = "BankItemButtonGenericTemplate"
    for bagID = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        element:AddBag(section, bagID)
    end

    element:SetScript("OnEvent", element.OnBankEvent)
    element:SetScript("OnHide", element.OnHide)

    for _, event in next, { "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED" } do
        element:RegisterEvent(event)
    end

    -- blizzard still opens and closes BankFrame, which keeps the bank session and BankFrame:IsShown()
    -- (read by ToggleAllBags); hiding it instead would close the bank (BankFrame_OnHide)
    _G.BankFrame:SetParent(E.Hider)
    table.insert(_G.UISpecialFrames, element:GetName())

    return element
end

function MODULE:CreatePurchaseButton(window)
    local element = CreateFrame("Button", nil, window)
    element:SetHeight(self.FOOTER_HEIGHT)
    element:SetPoint("BOTTOMLEFT", self.MARGIN, self.MARGIN)
    element:CreateBackdrop()

    local text = element:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(window.fontObject)
    text:SetPoint("CENTER")
    text:SetText(BANKSLOTPURCHASE)
    element:SetWidth(text:GetStringWidth() + 2 * self.MARGIN)

    element:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
    end)
    element:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(BANK_BAG_PURCHASE)
        GameTooltip:AddDoubleLine(COSTS_LABEL, GetMoneyString(GetBankSlotCost(GetNumBankSlots())), nil, nil, nil, 1, 1, 1)
        GameTooltip:Show()
    end)
    element:SetScript("OnLeave", GameTooltip_Hide)

    return element
end
