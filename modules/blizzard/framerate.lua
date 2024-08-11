local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Frame Rate
--------------------------------------------------
function MODULE:UpdateFramerateFrame()
    local fontObject = E.GetFont("Tainted")

    local element = _G.FramerateFrame
    if element then
        hooksecurefunc(element, "UpdatePosition", function(self, microMenuPosition, isMenuHorizontal)
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
        end)

        if element.Label then
            element.Label:SetFontObject(fontObject)
        end

        if element.FramerateText then
            element.FramerateText:SetFontObject(fontObject)
        end
    else
        local label = _G.FramerateLabel
        label:SetFontObject(fontObject)

        local text = _G.FramerateText
        text:SetFontObject(fontObject)
    end
end
