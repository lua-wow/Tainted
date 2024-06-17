local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Portrait
--------------------------------------------------
local element_proto = {
    showClass = false
}

function UnitFrames:CreatePortrait(frame)
    if not C.unitframes.portrait.enabled then return end

    local model = C.unitframes.portrait.model or "3D"

    if (model == "3D") then
        local holder = frame.Health

        local element = Mixin(CreateFrame("PlayerModel", nil, holder), element_proto)
        element:SetAllPoints(holder)
        element:SetAlpha(C.unitframes.portrait.alpha or 0.30)
        return element
    else
        local height = frame.__config.height

        local holder = CreateFrame("Frame", nil, frame)
        holder:SetPoint("RIGHT", frame, "LEFT", -3, 0)
        holder:SetSize(height, height)
        holder:CreateBackdrop()

        local element = Mixin(holder:CreateTexture(nil, "OVERLAY"), element_proto)
        element:SetAllPoints()
        element:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        element.showClass = (model == "CLASS")
        element.Holder = holder 

        return element
    end
end
