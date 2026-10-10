local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

local UpdateDisplayedZoneAbilities = function(self)
    local container = self.SpellButtonContainer

    local size, spacing = C.actionbars.extra.size or 52, C.actionbars.extra.spacing or 5
    
    local index = 1
    for button in container:EnumerateActive() do
        local xOffset = (index - 1) * (size + spacing)

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", container, "TOPLEFT", xOffset, 0)
        button:SetSize(size, size)
        MODULE.StyleActionButton(button)

        index = index + 1
    end

    local num = math.max(container.contentFramePool:GetNumActive(), 1)
    if not InCombatLockdown() then
        container:SetWidth((num * size) + ((num - 1) * spacing))
        container:SetHeight(size)
    end
end

function MODULE:CreateZoneAbilityButton(holder)
    local frame = _G.ZoneAbilityFrame
    if not frame then return end

    local size = C.actionbars.extra.size or 52
    local spacing = C.actionbars.extra.spacing or 5
    
    frame:SetParent(holder)
    frame:ClearAllPoints()
    frame:SetAllPoints()
    frame:EnableMouse(false)

    -- remove artwork
    local style = frame.Style
    if style then
        style:Hide()
        style:SetParent(E.Hider)
    end

    local container = frame.SpellButtonContainer
    container:SetFixedSize(size, size)
    container.spacing = spacing
    
    -- ExtraAbilityContainer:AddFrame parents the frame back to the container;
    -- SetParent is blocked in combat, so that one waits for combat to end
    holder:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent(event)
        frame:SetParent(self)
    end)

    hooksecurefunc(frame, "SetParent", function(self, parent)
        if parent == holder then return end
        if InCombatLockdown() then
            holder:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
            self:SetParent(holder)
        end
    end)

    hooksecurefunc(frame, "UpdateDisplayedZoneAbilities", UpdateDisplayedZoneAbilities)

    hooksecurefunc(container, "SetSize", function(self)
        if not InCombatLockdown() then
            local width, height = self:GetSize()
            holder:SetSize(width + 4, height + 4)
        end
    end)
end
