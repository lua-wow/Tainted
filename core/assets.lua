local _, ns = ...
local E, A = ns.E, ns.A

--------------------------------------------------
-- Assets
--------------------------------------------------
A["fonts"] = {
    ["normal"]      = [[Interface\AddOns\Tainted\assets\fonts\roboto.ttf]],
    ["alternative"] = [[Interface\AddOns\Tainted\assets\fonts\pt_sans_narrow.ttf]],
    ["unitframes"]  = [[Interface\AddOns\Tainted\assets\fonts\big_noogle_titling.ttf]],
    ["arial"]       = [[Interface\AddOns\Tainted\assets\fonts\arial.ttf]],
    ["pixel"]       = [[Interface\AddOns\Tainted\assets\fonts\visitor.ttf]],
    ["pixel 2"]     = [[Interface\AddOns\Tainted\assets\fonts\homespun_tt_brk.ttf]],
    ["font"]        = [[Interface\AddOns\Tainted\assets\fonts\invisible.ttf]]
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
    -- icon
    ["raidtarget"]     = [[Interface\AddOns\Tainted\assets\icons\raidtarget]],
    ["resting"]     = [[Interface\AddOns\Tainted\assets\icons\resting]]
}

A["sounds"] = {}

--------------------------------------------------
-- Font Objects
--------------------------------------------------
local CreateFont = _G.CreateFont

local TAINTED_FONT = "TaintedFont"
local TAINTED_FONT_OUTLINED = "TaintedFontOutline"
local TAINTED_UNITFRAME_FONT = "TaintedUFFont"
local TAINTED_PIXEL_FONT = "TaintedPixelFont"

local tainted_font = CreateFont(TAINTED_FONT)
tainted_font:SetFont(A.fonts.normal, 12, "")

local tainted_font_outlined = CreateFont(TAINTED_FONT_OUTLINED)
tainted_font_outlined:SetFont(A.fonts.normal, 12, "THINOUTLINE")

local tainted_uf_font = CreateFont(TAINTED_UNITFRAME_FONT)
tainted_uf_font:SetFont(A.fonts.unitframes, 12, "")

local tainted_pixel_font = CreateFont(TAINTED_PIXEL_FONT)
tainted_pixel_font:SetFont(A.fonts.pixel, 12, "MONOCHROME, OUTLINE, THIN")

local fonts = {
    ["Tainted"] = TAINTED_FONT,
    ["Tainted Outlined"] = TAINTED_FONT_OUTLINED,
    ["Tainted UnitFrame"] = TAINTED_UNITFRAME_FONT,
    ["Tainted Pixel"] = TAINTED_PIXEL_FONT,
    ["Game Font"] = "GameFontWhite"
}

E.GetFont = function(value)
    if (value and fonts[value]) then
        return fonts[value]
    end
    return fonts["Tainted"]
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
