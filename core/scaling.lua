local _, ns = ...
local E, C = ns.E, ns.C

-- Blizzard
local GetCVar = C_CVar and C_CVar.GetCVar or _G.GetCVar
local SetCVar = C_CVar and C_CVar.SetCVar or _G.SetCVar

--------------------------------------------------
-- UIScaling
--------------------------------------------------
-- reference: https://wowpedia.fandom.com/wiki/UI_scaling
function E:SetupUiScale()
    local uiScale = C.general.uiScale
    local currentUIScale = math.floor((uiScale * 100) + 0.5)
    local savedUIScale = math.floor(((tonumber(GetCVar("uiScale")) or 0) * 100) + 0.5)

    -- enable ui scaling
    SetCVar("useUiScale", 1)

    -- change ui scale only if cvar was changed
    if (currentUIScale ~= savedUIScale) then
        SetCVar("uiScale", uiScale)
    end

    -- allow ui to be set under 0.64
    if (uiScale <= 0.64) then
        UIParent:SetScale(uiScale)
    end
end
