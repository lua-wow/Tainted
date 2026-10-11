local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Auras
-- Retail oUF has no Buffs/Debuffs elements: auras are Blizzard AuraContainers built through
-- frame:CreateAuras. Blizzard fills the buttons, so secret aura values never reach us.
--------------------------------------------------
-- stealable buffs are Magic; None covers a secret or missing dispel type
local stealableColors = { Magic = E.colors.stealable, None = E.colors.stealable }

-- colored square behind the icon, visible as the backdrop's border (as modules/auras/mainline)
local function AddBorderTexture(button, options)
    local inset = E.Scale(C.general.border.size or 1)

    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetPoint("TOPLEFT", -inset, inset)
    texture:SetPoint("BOTTOMRIGHT", inset, -inset)
    texture:SetColorTexture(1, 1, 1)

    options.style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset
    options.showWithoutDispelType = true
    button:AddDispelTypeTexture(texture, options)
end

local function PostCreateButton(element, button)
    local font = A.fonts.normal

    button:CreateBackdrop()
    button.Icon:SetTexCoord(unpack(E.IconCoord))

    button.Cooldown:SetReverse(true)
    button.Cooldown:SetHideCountdownNumbers(true)

    button.Time:ClearAllPoints()
    button.Time:SetPoint("CENTER", 0, 0)
    button.Time:SetFont(font, 12, "THINOUTLINE")

    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", -1, 1)
    button.Count:SetFont(font, 9, "THINOUTLINE")

    if element.showDebuffType then
        AddBorderTexture(button, { showWhenHarmful = true, customDispelColorMap = E.colors.dispel })
    end

    if element.showStealableBuffs then
        AddBorderTexture(button, {
            showWhenHelpful = true,
            stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
            customDispelColorMap = stealableColors
        })
    end
end

local function IsCompact(frame)
    return (frame.__key ~= "player" and frame.__key ~= "target" and frame.__key ~= "nameplate")
end

local function CreateAuraElement(frame, isCompact, initialAnchor, growthX)
    local width = frame.__config.width or 252
    local size = C.unitframes.auras.size or 27
    local spacing = C.unitframes.auras.spacing or 3

    if isCompact then
        size = math.max(size - 4, 20)
        width = math.floor(width / 2)
    end

    local element = frame:CreateAuras({
        initialAnchor = initialAnchor,
        growthX = growthX,
        growthY = "UP",
        layoutLimit = width
    })
    element:SetSize(width, size)

    element.size = size
    element.elementSpacing = spacing
    element.lineSpacing = spacing
    element.maxFrameCount = E.CalcSegmentsNumber(width, size, spacing)
    element.showCount = true
    element.showDuration = true
    element.durationColors = { curve = E.curves.auras.duration, property = Enum.DurationTextBindingProperty.RemainingDuration }
    element.PostCreateButton = PostCreateButton

    return element
end

--------------------------------------------------
-- Buffs
--------------------------------------------------
function UnitFrames:CreateBuffs(frame)
    local isCompact = IsCompact(frame)

    local element = CreateAuraElement(frame, isCompact, "BOTTOMLEFT", "RIGHT")
    element:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, isCompact and 3 or 8)
    element.showStealableBuffs = (frame.__key ~= "player")

    local selfBuffs = frame.__config.buffs and frame.__config.buffs.selfBuffs
    element:AddGroup(selfBuffs and "HELPFUL|PLAYER" or "HELPFUL")

    return element
end

--------------------------------------------------
-- Debuffs
--------------------------------------------------
function UnitFrames:CreateDebuffs(frame)
    local isCompact = IsCompact(frame)

    local element = CreateAuraElement(frame, isCompact, "TOPRIGHT", "LEFT")
    if isCompact then
        element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 3)
    elseif (frame.__key == "nameplate") then
        element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 5)
    elseif (frame.Buffs) then
        -- nothing may anchor to an AuraContainer (UntrustedLayoutScriptExecution), so sit one
        -- buff row (same size, 8 above the frame) higher instead of anchoring to frame.Buffs
        element:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 8 + element.size + 3)
    else
        element:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 3)
    end
    element.showDebuffType = true

    element:AddGroup((frame.__key == "nameplate") and "HARMFUL|PLAYER" or "HARMFUL")

    return element
end
