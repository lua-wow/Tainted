local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local NUM_SPECIAL_BUTTONS = _G.NUM_SPECIAL_BUTTONS or 10
local InCombatLockdown = _G.InCombatLockdown
local GetShapeshiftFormInfo = _G.GetShapeshiftFormInfo

local stancebar_proto = {
    _num = NUM_SPECIAL_BUTTONS,
    _size = C.actionbars.stance.size,
    _spacing = C.actionbars.stance.spacing,
    _horizontal = C.actionbars.stance.horizontal
}

function stancebar_proto:Update()
    self:UpdateAnchor()
    self:CreateBackground(self._num, self._size, self._spacing, self._horizontal)
    self:UpdateVisibility()
    self:UpdateButtonsPosition()
    self:UpdateForms()
end

function stancebar_proto:UpdateAnchor()
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
end

function stancebar_proto:UpdateVisibility()
	UnregisterStateDriver(self, "visibility")
end

function stancebar_proto:UpdateButtonsPosition()
    local element = self

    local num = GetNumShapeshiftForms();
    local size = element._size
    local spacing = element._spacing

    element:CreateBackground(num, size, spacing, element._horizontal)

    for i, button in next, element._buttons do
        button:SetParent(button._parent or element)
        button:ClearAllPoints()
        button:SetSize(size, size)

        if i == 1 then
            button:SetPoint("TOPLEFT", element, "TOPLEFT", spacing, -spacing)
        else
            local anchor = element._buttons[i - 1]
            if element._horizontal then
                button:SetPoint("LEFT", anchor, "RIGHT", spacing, 0)
            else
                button:SetPoint("TOP", anchor, "BOTTOM", 0, -spacing)
            end
        end
    end
end

function stancebar_proto:UpdateForms()
    if InCombatLockdown() then return end

    local numForms = GetNumShapeshiftForms();
    if numForms == 0 then
        if self:IsShown() then
            self:Hide()
        end
    else
        if not self:IsShown() then
            self:Show()
        end
        self:UpdateButtonsPosition(numForms)
    end
end

function stancebar_proto:OnEvent()
    self:UpdateForms()
end

function MODULE:CreateStanceBar()
    local element = self:CreateActionBar("StanceBar", stancebar_proto)

    local frame = _G.StanceBar or _G.StanceBarFrame
    frame:SetParent(element)
    frame:ClearAllPoints()
    frame:SetAllPoints(E.Hider)
    frame:EnableMouse(false)
    frame.ignoreFramePositionManager = true
    -- frame.ignoreInLayout = true

    for i = 1, element._num do
        local button = element:StyleActionButton(_G["StanceButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element._buttons[i] = button
    end

    element:Update()

    if _G.StanceBar then
        hooksecurefunc(StanceBar, "UpdateGridLayout", function(self)
            element:UpdateForms()
        end)
    end

    if _G.StanceBarFrame then
        element:RegisterEvent("PLAYER_ENTERING_WORLD")
        element:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        element:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        element:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
        element:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
        element:SetScript("OnEvent", element.OnEvent)
    end

    self.StanceBar = element
end
