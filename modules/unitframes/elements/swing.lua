local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Swing (Forever, Era)
--------------------------------------------------
-- replaces the Blizzard swing timer skin (modules/blizzard/swing_timer.lua): same spot, size and font

-- Enum.PlayerSwingType is Forever only; this file loads on every client
local PlayerSwingType = Enum.PlayerSwingType or {}
local MAINHAND = PlayerSwingType.MainHand or 0
local OFFHAND = PlayerSwingType.OffHand or 1
local RANGED = PlayerSwingType.Ranged or 2

-- labels are Blizzard's swing timer strings (Forever), item slot names elsewhere
local SWING_TYPES = {
    { MAINHAND, _G.SWING_TIMER_MAIN_HAND or _G.INVTYPE_WEAPONMAINHAND },
    { OFFHAND, _G.SWING_TIMER_OFF_HAND or _G.INVTYPE_WEAPONOFFHAND },
    { RANGED, _G.SWING_TIMER_RANGED or _G.INVTYPE_RANGED }
}

local bars = {}
local isRanged = false -- the last swing was ranged: show the ranged bar, hide the melee ones

-- oUF shows each bar on its own; this keeps only the melee or the ranged group
local function PostUpdate(element, event, swingType)
    if event == "PLAYER_SWING" and (swingType == RANGED) ~= isRanged then
        isRanged = not isRanged
        for _, bar in ipairs(bars) do
            if bar.isRanged ~= isRanged then
                bar:Hide()
            end
        end
    end

    -- UnitAttackSpeed (Blizzard's off-hand check) is secret in combat
    if element.isRanged ~= isRanged or (swingType == OFFHAND and not IsDualWielding()) then
        element:Hide()
    end
end

function UnitFrames:CreateSwing(frame)
    -- oUF Swing only works on Forever and Era
    if not ((E.isCamelot or E.isVanilla) and C.unitframes.swingtimer.enabled) then return end

    local texture = C.unitframes.texture
    local font = A.fonts.normal

    local width = C.unitframes.classpower.width
    local height = C.unitframes.classpower.height
    local spacing = C.unitframes.classpower.spacing or 5
    local mu = C.general.background.multiplier or 0.15

    local previous
    for _, info in ipairs(SWING_TYPES) do
        local swingType, label = info[1], info[2]
        local element = frame:CreateSwingElement(swingType)
        element.isRanged = swingType == RANGED
        -- ranged takes the main-hand slot, they're never shown together
        if previous and not element.isRanged then
            element:SetPoint("TOP", previous, "BOTTOM", 0, -E.Scale(spacing))
        else
            element:SetPoint("TOP", frame.ClassPower, "BOTTOM", 0, -E.Scale(spacing))
        end
        element:SetSize(width, height)
        element:SetStatusBarTexture(texture)
        element:CreateBackdrop()

        local color = E.colors.swing[swingType]
        element:SetStatusBarColor(color.r, color.g, color.b)

        local bg = element:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(texture)
        bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
        element.bg = bg

        local name = element:CreateFontString(nil, "OVERLAY")
        name:SetPoint("LEFT", element, "LEFT", E.Scale(10), 0)
        name:SetFont(font, 10, nil)
        name:SetJustifyH("LEFT")
        name:SetText(label)

        local time = element:CreateFontString(nil, "OVERLAY")
        time:SetPoint("RIGHT", element, "RIGHT", -E.Scale(10), 0)
        time:SetFont(font, 10, nil)
        time:SetJustifyH("RIGHT")
        element.Time = time

        element.showCombat = true
        -- hidden while the target is out of swing range
        element.checkRange = true
        element.PostUpdate = PostUpdate

        bars[#bars + 1] = element
        previous = element
    end
end
