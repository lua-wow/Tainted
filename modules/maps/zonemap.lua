local _, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- BattlefieldMap (Shift + M)
--------------------------------------------------
if (not C.maps.enabled) then return end

local frame = CreateFrame("Frame", "ZoneMap")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
    if (name == "Blizzard_BattlefieldMap") then
        self:Skin()
    end
end

function frame:Skin()
    local element = _G.BattlefieldMapFrame
    if (element and not element.isSkinned) then
        if (element.BorderFrame) then
            element.BorderFrame:DisableDrawLayer("BORDER")
            element.BorderFrame:DisableDrawLayer("ARTWORK")
            
            if (element.BorderFrame.CloseButton) then
                element.BorderFrame.CloseButton:Hide()
            end
        end

        if (element.ScrollContainer) then
            element.ScrollContainer:CreateBackdrop()
        end

        local tab = _G.BattlefieldMapTab
        if (tab) then
            tab:StripTextures()
        end

        hooksecurefunc(element, "RefreshAlpha", self.RefreshAlpha)

        element.isSkinned = true
    end
end

function frame:RefreshAlpha()
    local alpha = 1.0 - _G.BattlefieldMapOptions.opacity;
    local Backdrop = self.ScrollContainer.Backdrop
    if (Backdrop) then
        Backdrop:SetAlpha(alpha)
    end
end
