local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Ghost Frame
--------------------------------------------------
if (not C.blizzard.ghost) then return end

local Ghost = {}

function Ghost:Init()
    local GhostFrame = _G.GhostFrame
    if (not GhostFrame) then return end

    local Minimap = _G.Minimap
    local text = _G.GhostFrameContentsFrameText

    -- the taxi button's slot, over the minimap strip; Blizzard's own anchor runs on
    -- Blizzard_UIWidgets ADDON_LOADED, which loads before addons
    GhostFrame:ClearAllPoints()
    GhostFrame:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -3)
    GhostFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -3)
    GhostFrame:SetHeight(20)
    GhostFrame:SetFrameStrata("MEDIUM")
    GhostFrame:SetFrameLevel((_G.TaintedMinimapDataText or Minimap):GetFrameLevel() + 3)
    -- killed, not cleared: the template's OnMouseDown/Up set these textures again
    GhostFrame:StripTextures(true)
    GhostFrame:SkinButton()

    _G.GhostFrameContentsFrameIcon:Kill()

    text:ClearAllPoints()
    text:SetPoint("CENTER", GhostFrame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetFontObject(E.GetFont(C.maps.font))
end

MODULE.Ghost = Ghost
