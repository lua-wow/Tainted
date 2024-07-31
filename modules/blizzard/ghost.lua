local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

-- Blizzard
local GhostFrame = _G.GhostFrame
local GhostFrameMiddle = _G.GhostFrameMiddle
local GhostFrameContentsFrame = _G.GhostFrameContentsFrame
local GhostFrameContentsFrameIcon = _G.GhostFrameContentsFrameIcon
local GhostFrameContentsFrameText = _G.GhostFrameContentsFrameText

--------------------------------------------------
-- Ghost Frame
--------------------------------------------------
if not C.blizzard.ghost then return end

local Ghost = CreateFrame("Frame", "TaintedGhost")

function Ghost:HideTextures(button)
    -- local name = button:GetName()
    -- _G[name.."Left"]:SetTexture(nil)
    -- _G[name.."Middle"]:SetTexture(nil)
    -- _G[name.."Right"]:SetTexture(nil)
    button:StripTextures(false)
end

function Ghost:Init()
    local size = 20
    
    GhostFrame:ClearAllPoints()
    GhostFrame:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -3)
    GhostFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -3)
    GhostFrame:SetHeight(size)
    GhostFrame:CreateBackdrop()
    
    GhostFrameContentsFrame:SetAllPoints(GhostFrame)
    
    GhostFrameContentsFrameIcon:Kill()
    -- GhostFrameContentsFrameIcon:ClearAllPoints()
    -- GhostFrameContentsFrameIcon:SetPoint("TOPLEFT", 0, 0)
    -- GhostFrameContentsFrameIcon:SetSize(size, size)
    -- GhostFrameContentsFrameIcon:SetTexCoord(unpack(E.IconCoord))

    GhostFrameContentsFrameText:SetWordWrap(false)
    GhostFrameContentsFrameText:SetNonSpaceWrap(true)
    GhostFrameContentsFrameText:SetTextToFit(_G.RETURN_TO_GRAVEYARD)

    local color = E:CreateColor(GhostFrameContentsFrameText:GetTextColor())
    
    Ghost:HideTextures(GhostFrame)

    GhostFrame:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            local name = self:GetName()
            Ghost:HideTextures(self)
            local contentsFrame = _G[name.."ContentsFrame"]
            if contentsFrame then
                contentsFrame:SetPoint("TOPLEFT", -2, -1)
            end
        end
    end)

    GhostFrame:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            local name = self:GetName()
            Ghost:HideTextures(self)
            local contentsFrame = _G[name.."ContentsFrame"]
            if contentsFrame then
                contentsFrame:SetPoint("TOPLEFT", 0, 0)
            end
        end
    end)

    GhostFrame:SetScript("OnEnter", function(self)
        if self.Backdrop then
            self.Backdrop:SetBackdropBorderColor(color:GetRGB())
        end
    end)

    GhostFrame:SetScript("OnLeave", function(self)
        if self.Backdrop then
            self.Backdrop:SetBackdropBorderColor(C.general.border.color:GetRGB())
        end
    end)
end

MODULE.Ghost = Ghost
