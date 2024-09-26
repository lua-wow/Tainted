local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Name
--------------------------------------------------
function UnitFrames:CreateName(frame, parent)
    local ref = parent or frame.Health
    local fontObject = E.GetFont(C.unitframes.font)

    local element = ref:CreateFontString(nil, "OVERLAY")
    element:SetFontObject(fontObject)
    element:SetWordWrap(false)
    
    if (frame.unit == "player") then
        element:SetJustifyH("CENTER")
        element:SetPoint("CENTER", ref, "CENTER", 0, 0)
    elseif (frame.__unit == "raid") then
        element:SetJustifyH("CENTER")
        element:SetPoint("CENTER", ref, "CENTER", 0, 3)
    else
        element:SetJustifyH("LEFT")
        element:SetPoint("LEFT", ref, "LEFT", 5, 0)
    end

    local tag = frame.__config.tags.name
    frame:Tag(element, tag)

    return element
end
