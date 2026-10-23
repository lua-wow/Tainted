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

    button:CreateTextureBackdrop()
    button.Icon:SetTexCoord(unpack(E.IconCoord))

    button.Cooldown:SetReverse(true)
    button.Cooldown:SetHideCountdownNumbers(true)

    if (button.Time) then
        button.Time:ClearAllPoints()
        button.Time:SetPoint("CENTER", 0, 0)
        button.Time:SetFont(font, 12, "THINOUTLINE")
    end

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

--------------------------------------------------
-- Raid
-- Replaces oUF_AuraTrack and oUF_RaidDebuffs (classic only) with Blizzard filter groups.
-- Groups aren't exclusive (each checks every aura), so later groups negate earlier ones;
-- the flow layout draws them in the order added.
--------------------------------------------------
-- RAID_PLAYER_DISPELLABLE: only debuffs someone in the group can dispel (NPC companions like
-- Brann don't count), so a Magic debuff on a warrior without a Magic dispeller is skipped.
-- DISPELLABLE would show any dispellable debuff regardless of who can remove it.
local raidDebuffFilters = {
    "HARMFUL|RAID_PLAYER_DISPELLABLE",
    "HARMFUL|!RAID_PLAYER_DISPELLABLE",
    "HARMFUL|CROWD_CONTROL|!RAID_PLAYER_DISPELLABLE",
    "HARMFUL|IMPORTANT|!RAID_PLAYER_DISPELLABLE|!CROWD_CONTROL"
}

-- new table per group: oUF's AddGroup stores a closure bound to its element in the options
local function GetRaidDebuffOptions(index)
    if (index == 1) then
        return { maxFrameCount = 1, sortMethod = AuraContainerSortMethod.UnitFrameDebuff }
    end
    return { maxFrameCount = 1, candidateFilters = { isBossAura = (index == 2) } }
end

-- top row of small icons, placed and sized as oUF_AuraTrack (4 per row)
local function CreateRaidBuffs(frame)
    local width = frame.__config.width or 90
    local spacing = 6
    local size = (width / 4) - spacing - (spacing / 4)

    local element = frame:CreateAuras({
        initialAnchor = "TOPLEFT",
        growthX = "RIGHT",
        growthY = "DOWN",
        layoutLimit = width - spacing
    })
    element:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", spacing, size / 3)
    element:SetSize(width - spacing, size)
    element:SetFrameLevel(frame.Health:GetFrameLevel() + 10)

    element.size = size
    element.elementSpacing = spacing
    element.lineSpacing = spacing
    element.showCount = true
    element.PostCreateButton = PostCreateButton

    element:AddGroup("HELPFUL|BIG_DEFENSIVE", { maxFrameCount = 1 })
    element:AddGroup("HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE", { maxFrameCount = 1 })
    element:AddGroup("HELPFUL|PLAYER|RAID_IN_COMBAT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", { maxFrameCount = 4 })

    return element
end

-- centred row, one debuff for each of the first `num` priority groups
local function CreateRaidDebuffs(frame, config)
    local num = math.min(config.num or 3, #raidDebuffFilters)
    local size = config.size or 24
    local spacing = C.unitframes.auras.spacing or 3
    local width = num * size + (num - 1) * spacing

    local element = frame:CreateAuras({
        initialAnchor = "TOPLEFT",
        growthX = "RIGHT",
        layoutLimit = width,
        policy = {} -- ProcessAura sets the debuffType the UnitFrameDebuff sort reads
    })
    element:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)
    element:SetSize(width, size)
    element:SetFrameLevel(frame.Health:GetFrameLevel() + 10)

    element.size = size
    element.elementSpacing = spacing
    element.showCount = true
    element.showDuration = true
    element.durationColors = { curve = E.curves.auras.duration, property = Enum.DurationTextBindingProperty.RemainingDuration }
    element.showDebuffType = true
    element.PostCreateButton = PostCreateButton

    for i = 1, num do
        element:AddGroup(raidDebuffFilters[i], GetRaidDebuffOptions(i))
    end

    return element
end

function UnitFrames:CreateRaidAuras(frame)
    local buffs, debuffs
    if (frame.__config.auratrack.enabled) then
        buffs = CreateRaidBuffs(frame)
    end
    if (C.unitframes.raid.debuffs.enabled) then
        debuffs = CreateRaidDebuffs(frame, C.unitframes.raid.debuffs)
    end
    return buffs, debuffs
end

--------------------------------------------------
-- Private Auras
-- Blizzard draws these into our anchors; only size and layout are ours.
--------------------------------------------------
function UnitFrames:CreatePrivateAuras(frame, config)
    local num = config.num or 2
    local size = config.size or 16
    local spacing = C.unitframes.auras.spacing or 3

    local element = CreateFrame("Frame", frame:GetName() .. "PrivateAuras", frame)
    element:SetSize(num * size + (num - 1) * spacing, size)
    element:SetFrameLevel(frame.Health:GetFrameLevel() + 10)

    element.num = num
    element.size = size
    element.spacing = spacing
    element.initialAnchor = "TOPLEFT"
    element.growthX = "RIGHT"
    -- Blizzard sizes the debuff border to iconWidth + 5 * borderScale; unset it stays 40x40
    element.borderScale = 0.4

    return element
end
