local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Name
--------------------------------------------------
function UnitFrames:CreateName(frame, parent)
    local fontObject = E.GetFont(C.unitframes.font)

    local element = (parent or frame.Health):CreateFontString(nil, "OVERLAY")
    element:SetFontObject(fontObject)
    element:SetWordWrap(false)
    
    if (frame.unit == "player") then
        element:SetJustifyH("CENTER")
        element:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)
    elseif (frame.__unit == "raid") then
        element:SetJustifyH("CENTER")
        element:SetPoint("CENTER", frame.Health, "CENTER", 0, 3)
    elseif (frame.__unit == "nameplate") then
        element:SetJustifyH("LEFT")
        element:SetPoint("BOTTOMLEFT", (parent or frame.Health), "TOPLEFT", 0, 5)
    else
        element:SetJustifyH("LEFT")
        element:SetPoint("LEFT", frame.Health, "LEFT", 5, 0)
    end

    local tag = frame.__config.tags.name
    frame:Tag(element, tag)

    return element
end
