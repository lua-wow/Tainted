local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Bags")

-- Blizzard
local KEYRING_CONTAINER = _G.KEYRING_CONTAINER or -2
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local NUM_CONTAINER_FRAMES = _G.NUM_CONTAINER_FRAMES or 13

local BAGTYPE_QUIVER = _G.BAGTYPE_QUIVER or -2

local GetKeyRingSize = _G.GetKeyRingSize

-- Mine
local BlizzardBags = {
	"CharacterBag0Slot",
	"CharacterBag1Slot",
	"CharacterBag2Slot",
	"CharacterBag3Slot",
	"CharacterReagentBag0Slot",
}

local close_proto = {}

do
end

local searchbox_proto = {
    placeholder = "Search"
}

do
    function searchbox_proto:OnEscapePressed()
        self:ClearFocus()
        self:SetText("")
    end

    function searchbox_proto:OnEnterPressed()
        self:ClearFocus()
        self:SetText("")
    end

    function searchbox_proto:OnTextChanged(value)
        local text = self:GetText()
        E:print(text, value, text == value)
        -- SetItemSearch(value)
    end

    function searchbox_proto:OnEditFocusLost()
        if self.Text then
            self.Text:Show()
        end

        if self.Backdrop then
            self.Backdrop:SetBackdropBorderColor(C.general.border.color:GetRGB())
        end
    end

    function searchbox_proto:OnEditFocusGained()
        if self.Text then
            self.Text:Hide()
        end

        if self.Backdrop then
            self.Backdrop:SetBackdropBorderColor(C.general.highlight.color:GetRGB())
        end
    end
end

local element_proto = {
    anchor = { "CENTER", UIParent, "CENTER", 200, 200 }
}

do
    function element_proto:CreateSearchBox(parent)
        local fontObject = E.GetFont(C.bags.font)

        local element = Mixin(CreateFrame("EditBox", self:GetName() .. "SearchBox", self), searchbox_proto)
        element:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -5)
        element:SetWidth(self:GetWidth() - 28)
        element:SetHeight(16)
        element:SetFrameLevel(self:GetFrameLevel() + 10)
        element:SetMultiLine(false)
        element:EnableMouse(true)
        element:SetAutoFocus(false)
        element:SetFontObject(fontObject)
        element:CreateBackdrop()

        local text = element:CreateFontString(nil, "OVERLAY")
        text:SetAllPoints()
        text:SetFontObject(fontObject)
        text:SetJustifyH("CENTER")
        text:SetText(element.placeholder)
        element.Text = text

        element:SetScript("OnEditFocusGained", element.OnEditFocusGained)
        element:SetScript("OnEditFocusLost", element.OnEditFocusLost)
        element:SetScript("OnEnterPressed", element.OnEnterPressed)
        element:SetScript("OnEscapePressed", element.OnEscapePressed)
        element:SetScript("OnTextChanged", element.OnTextChanged)

        element._parent = parent

        return element
    end

    function element_proto:CreateSlotsContainer(parent)
        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5

        local element = CreateFrame("Frame", self:GetName() .. "SlotsContainer", self)
        element:SetPoint("TOP", parent, "BOTTOM", 0, -spacing)
        element:SetPoint("LEFT", self, "LEFT", spacing, 0)
        element:SetPoint("RIGHT", self, "RIGHT", -spacing, 0)
        element:SetHeight(size)
        -- element:CreateBackdrop()

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
            end
        end

        return element
    end

    function element_proto:CreateItemsContainer()
        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5

        local parent = self
        local top = parent.SlotsContainer or parent.SearchBox or parent

        local element = CreateFrame("Frame", parent:GetName() .. "ItemsContainer", parent)
        element:SetPoint("TOP", top, "BOTTOM", 0, -spacing)
        element:SetPoint("LEFT", parent, "LEFT", spacing, 0)
        element:SetPoint("RIGHT", parent, "RIGHT", -spacing, 0)
        element:SetHeight(200)
        -- element:CreateBackdrop()

        return element
    end

    function element_proto:CreateKeyringContainer()
        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5

        local parent = self
        local top = parent.ItemsContainer or parent.SlotsContainer or parent.SearchBox or parent

        local element = CreateFrame("Frame", parent:GetName() .. "KeyringContainer", parent)
        element:SetPoint("TOP", top, "BOTTOM", 0, -spacing)
        element:SetPoint("LEFT", parent, "LEFT", spacing, 0)
        element:SetPoint("RIGHT", parent, "RIGHT", -spacing, 0)
        element:SetHeight(size)
        element:CreateBackdrop()

        return element
    end

    function element_proto:Create()
        local element = self

        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5

        element.SearchBox = element:CreateSearchBox(element)
        
        element.SlotsContainer = element:CreateSlotsContainer(element.SearchBox)
        
        element.ItemsContainer = element:CreateItemsContainer(element.SlotsContainer)
        
        element.KeyringContainer = element:CreateKeyringContainer(element.ItemsContainer)

        local width = math.max(
            element.SearchBox:GetHeight(),
            element.SlotsContainer:GetHeight(),
            element.ItemsContainer:GetHeight(),
            element.KeyringContainer:GetHeight(),
            size
        )
        local height = element.SearchBox:GetHeight()
            + spacing
            + element.SlotsContainer:GetHeight()
            + spacing
            + element.ItemsContainer:GetHeight()
            + spacing
            + element.KeyringContainer:GetHeight()
            + (2 * 5) -- margin
        element:SetWidth(width)
        element:SetHeight(height)
    end

    function element_proto:GetContainerNumSlots(containerIndex)
        if (containerIndex == KEYRING_CONTAINER) then
            return GetKeyRingSize()
        end
        return C_Container.GetContainerNumSlots(containerIndex)
    end

    function element_proto:Update()
        -- local NumRows, LastRowButton, NumButtons, LastButton, NumRowReagent = 0, ContainerFrame1Item1, 1, ContainerFrame1Item1, 0
        -- local FirstButton, FirstReagentButton
    
        -- local containers = E.iSRetail and 6 or 5
        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5
        local columns = C.bags.buttons.columns or 10

        local rows = 0
        local first = nil
        local previous = nil
        local numButtons = 0
        local lastRowButton = nil
    
        local max = NUM_BAG_SLOTS + 2
        for index = 1, max do
            local containerIndex = (index ~= max) and (index - 1) or KEYRING_CONTAINER
            local slots = self:GetContainerNumSlots(containerIndex)
            
            for slot = slots, 1, -1 do
                local buttonName = "ContainerFrame" .. index .. "Item" .. slot
                local button = _G[buttonName]
                if button then
                    -- button:SetParent(self.ItemsContainer)
                    button:ClearAllPoints()
                    button:SetSize(size, size)
                    button.__containerIndex = containerIndex
                    button.__slot = slot

                    if not first then
                        first = button
                    end

                    if button == first then
                        local anchor = (containerIndex == KEYRING_CONTAINER) and self.KeyringContainer or self.ItemsContainer
                        button:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
                        lastRowButton = button
                    elseif (numButtons == columns) then
                        button:SetPoint("TOPLEFT", lastRowButton, "BOTTOMLEFT", 0, -spacing)
                        lastRowButton = button
                        numButtons = 0
                        rows = rows + 1
                    else
                        button:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
                    end

                    previous = button

                    numButtons = numButtons + 1
                else
                    E:error(buttonName, "do not exists.")
                end
            end
    
        --     for Item = Slots, 1, -1 do
        --         local Button = _G["ContainerFrame"..Bag.."Item"..Item]
        --         local IconTexture = _G["ContainerFrame"..Bag.."Item"..Item.."IconTexture"]
    
        --         Button:ClearAllPoints()
        --         Button:SetWidth(ButtonSize)
        --         Button:SetHeight(ButtonSize)
        --         Button:SetScale(1)
    
        --         Button.newitemglowAnim:Stop()
        --         Button.newitemglowAnim.Play = Noop
    
        --         Button.flashAnim:Stop()
        --         Button.flashAnim.Play = Noop
    
        --         if not C.Bags.ReagentInsideBag and Bag == 6 then
        --             if not FirstReagentButton then
        --                 FirstReagentButton = Button
        --             end
    
        --             if (Button == FirstReagentButton) then
        --                 NumButtons = 1
    
        --                 Button:SetPoint("TOPLEFT", Bags.BagReagent, "TOPLEFT", 10, -10)
    
        --                 LastRowButton = Button
        --                 LastButton = Button
        --             elseif (NumButtons == ItemsPerRow) then
        --                 Button:SetPoint("TOPRIGHT", LastRowButton, "TOPRIGHT", 0, -(ButtonSpacing + ButtonSize))
        --                 Button:SetPoint("BOTTOMLEFT", LastRowButton, "BOTTOMLEFT", 0, -(ButtonSpacing + ButtonSize))
        --                 LastRowButton = Button
        --                 NumRowReagent = NumRowReagent + 1
        --                 NumButtons = 1
        --             else
        --                 Button:SetPoint("TOPRIGHT", LastButton, "TOPRIGHT", (ButtonSpacing + ButtonSize), 0)
        --                 Button:SetPoint("BOTTOMLEFT", LastButton, "BOTTOMLEFT", (ButtonSpacing + ButtonSize), 0)
    
        --                 NumButtons = NumButtons + 1
        --             end
    
        --             LastButton = Button
        --         else
        --             if not FirstButton then
        --                 FirstButton = Button
        --             end
    
        --             if (Button == FirstButton) then
        --                 Button:SetPoint("TOPLEFT", Bags.Bag, "TOPLEFT", 10, -40)
        --                 LastRowButton = Button
        --                 LastButton = Button
        --             elseif (NumButtons == ItemsPerRow) then
        --                 Button:SetPoint("TOPRIGHT", LastRowButton, "TOPRIGHT", 0, -(ButtonSpacing + ButtonSize))
        --                 Button:SetPoint("BOTTOMLEFT", LastRowButton, "BOTTOMLEFT", 0, -(ButtonSpacing + ButtonSize))
        --                 LastRowButton = Button
        --                 NumRows = NumRows + 1
        --                 NumButtons = 1
        --             else
        --                 Button:SetPoint("TOPRIGHT", LastButton, "TOPRIGHT", (ButtonSpacing + ButtonSize), 0)
        --                 Button:SetPoint("BOTTOMLEFT", LastButton, "BOTTOMLEFT", (ButtonSpacing + ButtonSize), 0)
        --                 NumButtons = NumButtons + 1
        --             end
    
        --             LastButton = Button
        --         end
    
        --         if not Button.IsSkinned then
        --             Bags.SkinBagButton(Button)
        --         end
        --     end
    
        --     Bags:BagUpdate(ID)
    
        --     if IsBagOpen(KEYRING_CONTAINER) then
        --         break
        --     end
        end
        E:print("rows", rows)
        E:print("columns", columns)
        -- self.Bag:SetHeight(((ButtonSize + ButtonSpacing) * (NumRows + 1) + 64 + (ButtonSpacing * 4)) - ButtonSpacing)
        -- self.BagReagent:SetHeight(((ButtonSize + ButtonSpacing) * (NumRowReagent + 1) + ButtonSpacing + (ButtonSpacing * 4)) - ButtonSpacing)
    end

    function element_proto:UpdateContainer(containerIndex)
        local isKeyring = (containerIndex == KEYRING_CONTAINER)
        
        local numSlots = self:GetContainerNumSlots(containerIndex)
        local _, bagType = C_Container.GetContainerNumFreeSlots(containerIndex)

        local containerName = isKeyring and 1 or (containerIndex + 1)
        for slot = 1, numSlots do
            local name = ("ContainerFrame%dItem%d"):format(containerName, slot)
            local button = _G[name]
            if button then
                if not button:IsShown() then
                    button:Show()
                end

                button.__bagType = bagType
            end
        end
    end

    -- function element_proto:PLAYER_ENTERING_WORLD(isLogin, isReload)
        -- self:Update()
        -- self:UnregisterAllEvents("PLAYER_ENTERING_WORLD")
    -- end

    function element_proto:BAG_CONTAINER_UPDATE()
        -- self:Update()
    end

    function element_proto:BAG_UPDATE(containerIndex)
        self:UpdateContainer(containerIndex)
    end

    function element_proto:OnEvent(event, ...)
        if self[event] then
            self[event](self, ...)
        else
            E:print(event, ...)
        end
    end
end

function MODULE:CreateBagContainer()
    local element = self:CreateContainer("Bags", element_proto)
    -- element:RegisterEvent("PLAYER_ENTERING_WORLD")
    element:RegisterEvent("BAG_CONTAINER_UPDATE")
    element:RegisterEvent("BAG_UPDATE")
    element:RegisterEvent("BAG_CLOSED")

	-- element:RegisterEvent("UNIT_INVENTORY_CHANGED")
	-- element:RegisterEvent("ITEM_LOCK_CHANGED")
	-- element:RegisterEvent("BAG_UPDATE_COOLDOWN")
	-- element:RegisterEvent("DISPLAY_SIZE_CHANGED")
	-- element:RegisterEvent("INVENTORY_SEARCH_UPDATE")
	-- element:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
	-- element:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
	-- element:RegisterEvent("ENGRAVING_MODE_CHANGED")
	-- element:RegisterEvent("ENGRAVING_TARGETING_MODE_CHANGED")
	-- element:RegisterEvent("RUNE_UPDATED")

    -- element:RegisterEvent("BAG_UPDATE")
	-- element:RegisterEvent("BAG_CLOSED")

	-- element:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	-- element:RegisterEvent("BANKFRAME_CLOSED")
	-- element:RegisterEvent("BANKFRAME_OPENED")
	-- element:RegisterEvent("MERCHANT_CLOSED")
	-- element:RegisterEvent("MAIL_CLOSED")

    -- if E.isRetail then
    --     element:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
    --     element:RegisterEvent("SOULBIND_FORGE_INTERACTION_STARTED")
    --     element:RegisterEvent("SOULBIND_FORGE_INTERACTION_ENDED")
    -- end
    -- element:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

    element:SetScript("OnEvent", element.OnEvent)
    return element
end
