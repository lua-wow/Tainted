local _, ns = ...
local E, A = ns.E, ns.A

--------------------------------------------------
-- Assets
--------------------------------------------------
local NotoSans_Condensed_Bold = [[Interface\AddOns\Tainted\assets\fonts\NotoSans_Condensed-Bold.ttf]]
local NotoSans_Condensed_SemiBold = [[Interface\AddOns\Tainted\assets\fonts\NotoSans_Condensed-SemiBold.ttf]]
local NotoSans_SemiCondensed_Bold = [[Interface\AddOns\Tainted\assets\fonts\NotoSans_SemiCondensed-Bold.ttf]]
local NotoSans_SemiCondensed_SemiBold = [[Interface\AddOns\Tainted\assets\fonts\NotoSans_SemiCondensed-SemiBold.ttf]]

A["fonts"] = {
    ["normal"]             = NotoSans_Condensed_SemiBold,
    -- alternatives
    ["big_noogle_titling"] = [[Interface\AddOns\Tainted\assets\fonts\BigNoogleTitling.ttf]],
    ["expressway"]         = [[Interface\AddOns\Tainted\assets\fonts\Expressway.ttf]],
    ["invisible"]          = [[Interface\AddOns\Tainted\assets\fonts\invisible.ttf]],
    ["pt_sans_narrow"]     = [[Interface\AddOns\Tainted\assets\fonts\PT_Sans_Narrow.ttf]],
    ["roboto"]             = [[Interface\AddOns\Tainted\assets\fonts\RobotoCondensed-Bold.ttf]],
}

A["textures"] = {
    ["glow"]        = [[Interface\AddOns\Tainted\assets\textures\glow]],
    ["blank"]       = [[Interface\AddOns\Tainted\assets\textures\blank]],
    ["normal"]      = [[Interface\AddOns\Tainted\assets\textures\normal]],
    ["alternative"] = [[Interface\AddOns\Tainted\assets\textures\elvui]],
    ["buggle"]      = [[Interface\AddOns\Tainted\assets\textures\bubble]],
    ["simpy 1"]     = [[Interface\AddOns\Tainted\assets\textures\simpy_1]],
    ["simpy 2"]     = [[Interface\AddOns\Tainted\assets\textures\simpy_2]],
    ["simpy 3"]     = [[Interface\AddOns\Tainted\assets\textures\simpy_3]],
    ["reduction"]   = [[Interface\AddOns\Tainted\assets\textures\reduction]],
    ["close"]       = [[Interface\AddOns\Tainted\assets\textures\close]]
}

A["icons"] = {
    ["copy"]        = [[Interface\AddOns\Tainted\assets\icons\copy]],
    ["raidtarget"]  = [[Interface\AddOns\Tainted\assets\icons\raidtarget]],
    ["resting"]     = [[Interface\AddOns\Tainted\assets\icons\resting]]
}

A["sounds"] = {}

--------------------------------------------------
-- Font Objects
--------------------------------------------------
local CreateFont = _G.CreateFont

local TAINTED_FONT = CreateFont("TaintedFont")
TAINTED_FONT:SetFont(A.fonts.normal, 12, "")

local TAINTED_FONT_OUTLINED = CreateFont("TaintedFontOutline")
TAINTED_FONT_OUTLINED:SetFont(A.fonts.normal, 12, "OUTLINE")

local TAINTED_UNITFRAME_FONT = CreateFont("TaintedUFFont")
TAINTED_UNITFRAME_FONT:SetFont(A.fonts.big_noogle_titling, 12, "")

-- local TAINTED_PIXEL_FONT = CreateFont("TaintedPixelFont")
-- TAINTED_PIXEL_FONT:SetFont(A.fonts.pixel, 12, "OUTLINE, MONOCHROME")

local FONTS = {
    ["Tainted"] = TAINTED_FONT,
    ["Tainted Outlined"] = TAINTED_FONT_OUTLINED,
    ["Tainted UnitFrame"] = TAINTED_UNITFRAME_FONT,
    -- ["Tainted Pixel"] = TAINTED_PIXEL_FONT,
    ["Game Font White"] = _G.GameFontWhite,
    ["Game Font Normal"] = _G.GameFontNormal
}

E.GetFont = function(value)
    if (value and FONTS[value]) then
        return FONTS[value]
    end
    return FONTS["Tainted"]
end

--------------------------------------------------
-- Textures
--------------------------------------------------
E.GetTexture = function(value)
    if (value and A.textures[value]) then
        return A.textures[value]
    end
    return A.textures["blank"]
end
