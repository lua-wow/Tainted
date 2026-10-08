local addon, ns = ...
local E, C = ns.E, ns.C

--------------------------------------------------
-- Auras
-- Mainline has no SecureAuraHeaderTemplate (Classic only since 12.1), so player auras use
-- Blizzard's AuraContainer. Blizzard fills the buttons, so secret aura values never reach us.
--------------------------------------------------
if not C.auras.enabled then return end

local SORT_METHODS = {
    ["INDEX"] = AuraContainerSortMethod.Default,
    ["NAME"] = AuraContainerSortMethod.NameOnly,
    ["TIME"] = AuraContainerSortMethod.ExpirationOnly
}

local size, spacing = C.auras.size or 30, C.auras.spacing or 3
local rows, cols = C.auras.rows or 3, C.auras.columns or 12

-- same steps as the classic header: xOffset = size + spacing + 2, yOffset = size + 12 + spacing + 2
local layout = {
    elementSpacing = spacing + 2,
    lineSpacing = 12 + spacing + 2,
    elementWidth = size,
    elementHeight = size
}

local function InitButton(button)
    local fontObject = E.GetFont(C.auras.font)
    local inset = E.Scale(C.general.border.size or 1)

    button:SetSize(size, size)
    button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", -5, -5)
    button:SetCancelAuraButtons("RightButtonUp")
    button:CreateBackdrop()

    local color = C.general.backdrop.color
    button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)

    local icon = button:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()
    icon:SetTexCoord(unpack(E.IconCoord))
    button:SetIcon(icon)

    local count = button:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", -1, 1)
    count:SetFontObject(fontObject)
    button:SetApplicationCount(count)

    local duration = button:CreateFontString(nil, "OVERLAY")
    duration:SetPoint("TOP", button, "BOTTOM", 0, -3)
    duration:SetFontObject(fontObject)
    button:SetDurationText(duration, {
        textColor = { curve = E.curves.auras.timer, property = Enum.DurationTextBindingProperty.RemainingDuration }
    })

    -- debuff border: colored square behind the icon, visible as the backdrop's border
    local dispel = button:CreateTexture(nil, "BACKGROUND")
    dispel:SetPoint("TOPLEFT", -inset, inset)
    dispel:SetPoint("BOTTOMRIGHT", inset, -inset)
    dispel:SetColorTexture(1, 1, 1)
    button:AddDispelTypeTexture(dispel, {
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        showWhenHarmful = true,
        showWithoutDispelType = true,
        customDispelColorMap = E.colors.dispel
    })
end

local function InitEnchant(button)
    InitButton(button)

    local color = E.colors.dispel.Curse
    button.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
end

local function CreateContainer(name, filter)
    local container = CreateFrame("AuraContainer", name, UIParent, "CustomAuraContainerTemplate")
    container:SetClampedToScreen(true)
    container:SetFlowLayoutAnchorPoint("TOPRIGHT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(cols * size + (cols - 1) * layout.elementSpacing)

    container:AddAuraGroup(filter, filter, {
        maxFrameCount = rows * cols,
        initializeFrame = InitButton,
        sortMethod = SORT_METHODS[C.auras.sort.method] or AuraContainerSortMethod.Default,
        sortDirection = (C.auras.sort.direction == "-") and AuraContainerSortDirection.Reverse or AuraContainerSortDirection.Normal,
        layout = layout
    })

    RegisterStateDriver(container, "visibility", "[petbattle] hide; show")

    container:SetUnit("player")
    container:SetEnabled(true)

    return container
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function frame:PLAYER_LOGIN()
    self.BuffHeader = CreateContainer("TaintedBuffHeader", "HELPFUL")
    self.BuffHeader:SetPoint("TOPRIGHT", _G.Minimap, "TOPLEFT", -5, 0)
    self.BuffHeader:SetItemEnchantmentLayout(layout)
    for _, slot in next, AuraContainerItemEnchantmentSlot do
        self.BuffHeader:AddItemEnchantment(slot, { initializeFrame = InitEnchant })
    end

    self.DebuffHeader = CreateContainer("TaintedDebuffHeader", "HARMFUL")
    self.DebuffHeader:SetPoint("TOPRIGHT", _G.Minimap, "BOTTOMLEFT", -5, 30)
end

local function ForceHide(frame)
    if frame then
        frame:Kill()
    end
end

function frame:PLAYER_ENTERING_WORLD(isLogin, isReload)
    if isLogin or isReload then
        ForceHide(_G.BuffFrame)
        ForceHide(_G.DebuffFrame)
        ForceHide(_G.DeadlyDebuffFrame)
    end
end
