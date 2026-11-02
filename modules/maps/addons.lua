local addon, ns = ...
local E, C, A = ns.E, ns.C, ns.A

--------------------------------------------------
-- Minimap: addon buttons
--------------------------------------------------
if not C.maps.enabled then return end

local MODULE = E:GetModule("Minimap")

-- LibDBIcon buttons are reparented to the hider and listed below the minimap,
-- opened by a "+" shown while hovering the minimap
do
    local ROW_HEIGHT = 20
    local ROW_SPACING = 3

    local row_proto = {}

    function row_proto:OnClick(mouseButton)
        local OnClick = self.dataObject.OnClick
        if OnClick then
            OnClick(self, mouseButton)
        end
    end

    function row_proto:OnEnter()
        local dataObject = self.dataObject
        if dataObject.OnTooltipShow then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            dataObject.OnTooltipShow(GameTooltip)
            GameTooltip:Show()
        elseif dataObject.OnEnter then
            dataObject.OnEnter(self)
        end
    end

    function row_proto:OnLeave()
        GameTooltip:Hide()
        local OnLeave = self.dataObject.OnLeave
        if OnLeave then
            OnLeave(self)
        end
    end

    local function CreateRow(list)
        local row = Mixin(CreateFrame("Button", nil, list), row_proto)
        row:SetHeight(ROW_HEIGHT)
        row:SkinButton()
        row:RegisterForClicks("AnyUp")
        row:SetScript("OnClick", row.OnClick)
        row:SetScript("OnEnter", row.OnEnter)
        row:SetScript("OnLeave", row.OnLeave)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", 3, 0)
        icon:SetSize(ROW_HEIGHT - 6, ROW_HEIGHT - 6)
        row.Icon = icon

        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -3, 0)
        text:SetFontObject(E.GetFont(C.maps.font))
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        row.Text = text

        return row
    end

    local toggle_proto = {}

    -- visible while the mouse is over the minimap or the list is open
    function toggle_proto:UpdateShown()
        local visible = self.count > 0 and (self.List:IsShown() or _G.Minimap:IsMouseOver())
        self:SetShown(visible)
    end

    function toggle_proto:OnClick()
        local list = self.List
        if list:IsShown() then
            list:Hide()
        else
            if self.dirty then
                self:UpdateList()
            end
            list:Show()
        end
    end

    function toggle_proto:UpdateList()
        local list = self.List
        local names = {}
        for name in next, self.buttons do
            names[#names + 1] = name
        end
        table.sort(names)

        for index, name in ipairs(names) do
            local row = list[index] or CreateRow(list)
            list[index] = row

            local dataObject = self.buttons[name].dataObject
            local coords = dataObject.iconCoords
            row.dataObject = dataObject
            row.Icon:SetTexture(dataObject.icon)
            if coords then
                row.Icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            else
                row.Icon:SetTexCoord(0, 1, 0, 1)
            end
            row.Text:SetText(name)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(index - 1) * (ROW_HEIGHT + ROW_SPACING))
            row:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -(index - 1) * (ROW_HEIGHT + ROW_SPACING))
        end

        list:SetHeight(#names * (ROW_HEIGHT + ROW_SPACING) - ROW_SPACING)
        self.dirty = false
    end

    function toggle_proto:Collect(button, name)
        if self.buttons[name] then return end
        button:SetParent(E.Hider)
        self.buttons[name] = button
        self.count = self.count + 1
        self.dirty = true
    end

    function MODULE:CreateAddonButtons()
        local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if not LibDBIcon then return end

        local Minimap = _G.Minimap
        local anchor = self.DataText or Minimap

        local toggle = Mixin(CreateFrame("Button", addon .. "MinimapAddonsButton", Minimap), toggle_proto)
        toggle:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -3, 3)
        toggle:SetSize(14, 14)
        toggle:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        toggle:SkinButton()
        toggle:RegisterForClicks("AnyUp")
        toggle:SetScript("OnClick", toggle.OnClick)
        toggle:HookScript("OnLeave", toggle.UpdateShown)
        toggle:Hide()
        toggle.buttons = {}
        toggle.count = 0

        -- 8px keeps the texture's 8px bars on whole pixels (32 / 4)
        local icon = toggle:CreateTexture(nil, "OVERLAY")
        icon:SetPoint("CENTER")
        icon:SetSize(8, 8)
        icon:SetTexture(A.textures.plus)
        toggle.Icon = icon

        local list = CreateFrame("Frame", addon .. "MinimapAddons", Minimap)
        list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -ROW_SPACING)
        list:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -ROW_SPACING)
        list:SetFrameStrata("HIGH")
        list:SetScript("OnHide", function() toggle:UpdateShown() end)
        list:Hide()
        toggle.List = list

        for name, button in next, LibDBIcon.objects do
            toggle:Collect(button, name)
        end

        -- addons registering their icon after Tainted loads
        LibDBIcon.RegisterCallback(toggle, "LibDBIcon_IconCreated", function(_, button, name)
            toggle:Collect(button, name)
        end)

        local function UpdateShown()
            toggle:UpdateShown()
        end
        
        Minimap:HookScript("OnEnter", UpdateShown)
        Minimap:HookScript("OnLeave", UpdateShown)

        return toggle
    end
end
