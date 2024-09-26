local _, ns = ...
local E, A = ns.E, ns.A

--------------------------------------------------
-- Fonts
--------------------------------------------------
local DEFAULT_FONT = A.fonts.normal

function E:UpdateFonts()
    local frames = {
        -- Base fonts
        ["FriendsFont_Large"] = { DEFAULT_FONT, 14 },
        ["FriendsFont_Normal"] = { DEFAULT_FONT, 12 },
        ["FriendsFont_Small"] = { DEFAULT_FONT, 11 },
        ["FriendsFont_UserText"] = { DEFAULT_FONT, 11 },
        ["GameTooltipHeader"] = { DEFAULT_FONT, 12 },
        ["NumberFont_Outline_Huge"] = { DEFAULT_FONT, 28, "THICKOUTLINE" },
        ["NumberFont_Outline_Large"] = { DEFAULT_FONT, 15, "OUTLINE" },
        ["NumberFont_Outline_Med"] = { DEFAULT_FONT, 13, "OUTLINE" },
        ["NumberFont_OutlineThick_Mono_Small"] = { DEFAULT_FONT, 12, "OUTLINE" },
        ["NumberFont_Shadow_Med"] = { DEFAULT_FONT, 12 },
        ["NumberFont_Shadow_Small"] = { DEFAULT_FONT, 12 },
        ["PVPArenaTextString"] = { DEFAULT_FONT, 22, "THINOUTLINE" },
        ["PVPInfoTextString"] = { DEFAULT_FONT, 22, "THINOUTLINE" },
        ["QuestFont_Large"] = { DEFAULT_FONT, 14 },
        ["QuestFont"] = { DEFAULT_FONT, 14 },
        ["SubZoneTextString"] = { DEFAULT_FONT, 25, "OUTLINE" },
        ["SystemFont_Large"] = { DEFAULT_FONT, 15 },
        ["SystemFont_Med1"] = { DEFAULT_FONT, 12 },
        ["SystemFont_Med3"] = { DEFAULT_FONT, 13 },
        ["SystemFont_Outline_Small"] = { DEFAULT_FONT, 12, "OUTLINE" },
        ["SystemFont_OutlineThick_Huge2"] = { DEFAULT_FONT, 20, "THICKOUTLINE" },
        ["SystemFont_Shadow_Huge1"] = { DEFAULT_FONT, 20, "THINOUTLINE" },
        ["SystemFont_Shadow_Large"] = { DEFAULT_FONT, 15 },
        ["SystemFont_Shadow_Med1"] = { DEFAULT_FONT, 12 },
        ["SystemFont_Shadow_Med3"] = { DEFAULT_FONT, 13 },
        ["SystemFont_Shadow_Small"] = { DEFAULT_FONT, 11 },
        ["SystemFont_Small"] = { DEFAULT_FONT, 12 },
        ["SystemFont_Tiny"] = { DEFAULT_FONT, 12 },
        ["Tooltip_Med"] = { DEFAULT_FONT, 12 },
        ["Tooltip_Small"] = { DEFAULT_FONT, 12 },
        ["ZoneTextString"] = { DEFAULT_FONT, 32, "OUTLINE" },
        -- Combat Text
        ["CombatTextFont"] = { DEFAULT_FONT, 25, "OUTLINE" },
    }

    for name, row in next, frames do
        local frame = _G[name]
        if frame then
            local font, size, flags = unpack(row)
            frame:SetFont(font, size or 12, flags or "")
        else
            E:error("Frame " .. name .. " do not exists")
        end
    end
end
