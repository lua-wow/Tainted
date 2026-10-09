local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

function MODULE:CreateExtraActionButton(holder)
    local frame = _G.ExtraActionBarFrame
    if not frame then return end

    local size = C.actionbars.extra.size or 52

    frame:SetParent(holder)
    frame:ClearAllPoints()
    frame:SetAllPoints()
    frame:EnableMouse(false)
    -- frame:CreateBackdrop()
    -- frame.Backdrop:SetBackdropBorderColor(0, 1, 0)

    local container = _G.ExtraAbilityContainer
    if container then
        container:EnableMouse(false)
    end

    -- the style texture is parented to E.Hider by StyleActionButton, so Blizzard's later SetTexture calls stay hidden
    local button = frame.button or _G.ExtraActionButton1
    if button then
        button:SetSize(size, size)
        MODULE.StyleActionButton(button)
    end

    -- ExtraAbilityContainer:AddFrame parents the frame back to the container
    hooksecurefunc(frame, "SetParent", function(self, parent)
        if parent ~= holder then
            self:SetParent(holder)
        end
    end)
end
