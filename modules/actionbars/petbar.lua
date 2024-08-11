local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local NUM_PET_ACTION_SLOTS = _G.NUM_PET_ACTION_SLOTS or 10

local petbar_proto = {
    _num = NUM_PET_ACTION_SLOTS,
    _size = C.actionbars.pet.size,
    _spacing = C.actionbars.pet.spacing,
    _horizontal = false,
    _visibility = "[@pet,exists,nopossessbar] show; hide"
}

function petbar_proto:Update()
    self:UpdateAnchor()
    self:CreateBackground(self._num, self._size, self._spacing, self._horizontal)
    self:UpdateVisibility()
    self:UpdateButtonsPosition()
end

function petbar_proto:UpdateAnchor()
    local anchor = UIParent
    if MODULE.ActionBar8 and MODULE.ActionBar8:IsShown() then
        anchor = MODULE.ActionBar8
    elseif MODULE.ActionBar7 and MODULE.ActionBar7:IsShown() then
        anchor = MODULE.ActionBar7
    elseif MODULE.ActionBar6 and MODULE.ActionBar6:IsShown() then
        anchor = MODULE.ActionBar6
    elseif MODULE.ActionBar5 and MODULE.ActionBar5:IsShown() then
        anchor = MODULE.ActionBar5
    elseif MODULE.ActionBar4 and MODULE.ActionBar4:IsShown() then
        anchor = MODULE.ActionBar4
    end

    if anchor ~= UIParent then
        self:SetPoint("RIGHT", anchor, "LEFT", -self._spacing, 0)
    else
        self:SetPoint("RIGHT", UIParent, "RIGHT", 10, -10)
    end
end

function MODULE:CreatePetBar()
    local element = self:CreateActionBar("PetBar", petbar_proto)

    local frame = _G.PetActionBar or _G.PetActionBarFrame
    frame:SetParent(element)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["PetActionButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetAttribute("addchild", button)

        element._buttons[i] = button
    end

    element:Update()

    self.PetBar = element
end
