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
local element_proto = {
    anchor = { "CENTER", UIParent, "CENTER", 200, 200 }
}

do
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

    function element_proto:Create()
        local element = self

        local size = C.bags.buttons.size or 32
        local spacing = C.bags.buttons.spacing or 5

        element.SlotsContainer = element:CreateSlotsContainer(element.SearchBox)
        
        element.ItemsContainer = element:CreateItemsContainer(element.SlotsContainer)
        
        local width = math.max(
            element.SlotsContainer:GetHeight(),
            element.ItemsContainer:GetHeight(),
            element.KeyringContainer:GetHeight(),
            size
        )
        local height = element.SlotsContainer:GetHeight()
            + spacing
            + element.ItemsContainer:GetHeight()
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
    end

    function element_proto:UpdateContainer(containerIndex)
    end

    function element_proto:PLAYERBANKSLOTS_CHANGED(slot)
        -- slot: number - When (slot <= NUM_BANKGENERIC_SLOTS), slot is the index of the generic bank slot that changed. When (slot > NUM_BANKGENERIC_SLOTS), (slot - NUM_BANKGENERIC_SLOTS) is the index of the equipped bank bag that changed.
        E:print("PLAYERBANKSLOTS_CHANGED", slot, slot <= NUM_BANKGENERIC_SLOTS, slot > NUM_BANKGENERIC_SLOTS, slot - NUM_BANKGENERIC_SLOTS)
    end

    function element_proto:OnEvent(event, ...)
        if self[event] then
            self[event](self, ...)
        else
            E:print(event, ...)
        end
    end
end

function MODULE:CreateBankContainer()
    local element = self:CreateContainer("Bags", element_proto)
    -- element:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- element:RegisterEvent("BAG_CONTAINER_UPDATE")
    -- element:RegisterEvent("BAG_UPDATE")
    -- element:RegisterEvent("BAG_CLOSED")

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

    -- -- element:RegisterEvent("BAG_UPDATE")
	-- -- element:RegisterEvent("BAG_CLOSED")

	element:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	element:RegisterEvent("BANKFRAME_CLOSED")
	element:RegisterEvent("BANKFRAME_OPENED")
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
