local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Blizzard
local BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER or 0
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local NUM_TOTAL_EQUIPPED_BAG_SLOTS = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4

local IsShiftKeyDown =_G.IsShiftKeyDown

-- Mine
local BAG = L.BAG or "Bag"
local BAGS = L.BAGS or "Bags"
local FREE = L.FREE or "Free"
local REAGENTS = L.REAGENTS or "Reagents"
local USED = L.USED or "Used"
local TOGGLE_BAGS_TEXT = L.TOGGLE_BAGS_TEXT
local TOGGLE_BAGS_BAR_TEXT = L.TOGGLE_BAGS_BAR_TEXT

local SLOTS_STRING = "%d / %d"
local DATATEXT_STRING = "%s %s"

local bags_proto = {
    numSlots = 0,
    freeSlots = 0
}

function bags_proto:ToggleBagsBar()
    if BagsBar:IsShown() then
        BagsBar:Hide()
    else
        BagsBar:Show()
    end
    BagsBar:ClearAllPoints()
    BagsBar:SetPoint("BOTTOMRIGHT", UIParent, -10, 260)
end

function bags_proto:OnMouseDown()
    if IsShiftKeyDown() then
        self:ToggleBagsBar()
    else
        ToggleAllBags()
    end
end

function bags_proto:CreateTooltip(tooltip)
    tooltip:AddDoubleLine(BAGS, SLOTS_STRING:format(self.numSlots - self.freeSlots, self.numSlots or 0), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    tooltip:AddLine(" ")

    for _, row in next, self.bags do
        local left = (row.containerIndex > NUM_BAG_SLOTS) and REAGENTS or (BAG .. " " .. row.containerIndex)
        local right = SLOTS_STRING:format(row.numSlots - row.freeSlots, row.numSlots)
        tooltip:AddDoubleLine(left, right, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOGGLE_BAGS_TEXT)
    tooltip:AddLine(TOGGLE_BAGS_BAR_TEXT)
end

function bags_proto:OnEvent(event, ...)
    self.numSlots = 0
    self.freeSlots = 0
    self.bags = table.wipe(self.bags or {})

    for containerIndex = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(containerIndex)
        local freeSlots = C_Container.GetContainerNumFreeSlots(containerIndex)
        
        self.numSlots = self.numSlots + numSlots
        self.freeSlots = self.freeSlots + freeSlots

        table.insert(self.bags, {
            containerIndex = containerIndex,
            numSlots = numSlots,
            freeSlots = freeSlots
        })
    end

    if self.Text then
        local numText = self.color:WrapTextInColorCode(SLOTS_STRING:format(self.freeSlots, self.numSlots))
	    self.Text:SetFormattedText(DATATEXT_STRING, BAGS, numText)
    end
end

function bags_proto:Update()
    self:OnEvent("ForceUpdate")
end

function bags_proto:Enable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("BAG_UPDATE")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Update()
    self:Show()
end

function bags_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("Bags", bags_proto)
