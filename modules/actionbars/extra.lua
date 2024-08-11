local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

function MODULE:CreateExtraActionButton(holder)
    local frame = _G.ExtraActionBarFrame
    if not frame then return end

    local size = C.actionbars.extra.size or 52
    local spacing = C.actionbars.extra.spacing or 5

    frame:SetParent(holder)
    frame:ClearAllPoints()
    frame:SetAllPoints()
    frame:EnableMouse(false)
    frame.ignoreFramePositionManager = true
    frame.ignoreInLayout = true
    -- frame:CreateBackdrop()
    -- frame.Backdrop:SetBackdropBorderColor(0, 1, 0)

    local container = _G.ExtraAbilityContainer
    container:EnableMouse(false)
    container:SetFixedSize(size, size)
    container.spacing = spacing
    container.ignoreFramePositionManager = true
    container.ignoreInLayout = true

    local button = frame.button or _G.ExtraActionButton1
    if button then
        button:SetSize(size, size)
        MODULE:StyleActionButton(button)
    end

    hooksecurefunc(frame, "SetParent", function(self, parent)
        if parent ~= holder then
            self:SetParent(holder)
        end
    end)

    hooksecurefunc("ExtraActionBar_Update", function()
        if HasExtraActionBar() then
            if button.style then
                button.style:SetTexture(nil)
            end
        end
    end)
end
