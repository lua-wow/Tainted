local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- icon coordinates template
E.IconCoord = { 0.08, 0.92, 0.08, 0.92 }

--------------------------------------------------
-- Module
--------------------------------------------------
do
	local ModuleMixin = {
		indexes = {},
		modules = {}
	}

	function ModuleMixin:GetModule(name)
		return self.modules[name]
	end

	function ModuleMixin:SetModule(name, module)
		self.modules[name] = module
		return self.modules[name]
	end

	function ModuleMixin:CreateModule(name)
		assert(not self.modules[name], "Module " .. name .. " already exists.")
		self.indexes[#self.indexes + 1] = name
		return self:SetModule(name, {})
	end
	
	function ModuleMixin:InitModules()
		if not self.modules then return end
		for index, name in ipairs(self.indexes) do
			local module = self.modules[name]
			assert(module.Init, "Module " .. name .. " do not have 'Init' function.")
			module:Init()
		end
	end

	function ModuleMixin:UpdateModules()
		if not self.modules then return end
		for _, module in next, self.modules do
			if module.Update then
				module:Update()
			else
				E:error("Module " .. name .. " do not have Update")
			end
		end
	end

	E.ModuleMixin = ModuleMixin

	-- set engine as 'module'
	E = Mixin(E, ModuleMixin)
end

--------------------------------------------------
-- Functions
--------------------------------------------------
function E:print(...)
    print("|cffff8000Tainted|r", ...)
end

function E:error(...)
    print("|cffff0000Tainted|r", ...)
end

--------------------------------------------------
-- LOADING
--------------------------------------------------
E:RegisterEvent("ADDON_LOADED")
E:RegisterEvent("VARIABLES_LOADED")
E:RegisterEvent("PLAYER_LOGIN")
if (E.isRetail) then
	E:RegisterEvent("SETTINGS_LOADED")
end
E:RegisterEvent("PLAYER_ENTERING_WORLD")
E:SetScript("OnEvent", function (self, event, ...)
	assert(self[event], "Unable to locate " .. event .." event handler")
	self[event](self, ...)
end)

function E:ADDON_LOADED(name, containsBindings)
    if (name == "Tainted") then
		self:InitDatabase()
	end
end

function E:VARIABLES_LOADED(...)
	self.locale = GetLocale()
	self:UpdateFonts()
end

function E:PLAYER_LOGIN()
	if (not self.db.installed) then
		-- setup cvars
		self:SetupUiScale()

		-- fix bag sorting order
		if E.isRetail then
			C_Container.SetSortBagsRightToLeft(true)
			C_Container.SetInsertItemsLeftToRight(true)
		end
		
		self.db.installed = true
	end

	-- load modules
	self:InitModules()
end

function E:SETTINGS_LOADED(...)
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true)
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_3", true)
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_4", true)
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_5", true)
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", false)
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_7", false)
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_8", false)
end

function E:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    self:SetupDefaultsCVars()

	if not self.db.chat then
		local Chat = self:GetModule("Chat")
		Chat:Reset()
		self.db.chat = true
	end
end
