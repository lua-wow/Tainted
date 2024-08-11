local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- icon coordinates template
E.IconCoord = { 0.08, 0.92, 0.08, 0.92 }

--------------------------------------------------
-- Module
--------------------------------------------------
do
	local ModuleMixin = {}

	function ModuleMixin:GetModule(name)
		return self.modules[name]
	end

	function ModuleMixin:SetModule(name, module)
		if not self.modules then
			self.modules = {}
		end
		self.modules[name] = module
		return self.modules[name]
	end

	function ModuleMixin:CreateModule(name)
		return self:SetModule(name, {})
	end

	function ModuleMixin:InitModules()
		if not self.modules then return end
		for name, module in next, self.modules do
			if (module.Init) then
				module:Init()
			else
				E.debug("Module " .. name .. " do not have Init")
			end
		end
	end

	function ModuleMixin:UpdateModules()
		if not self.modules then return end
		for _, module in next, self.modules do
			if module.Update then
				module:Update()
			else
				E.debug("Module " .. name .. " do not have Update")
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
E.print = function(...)
    print(E.name, ...)
end

E.debug = function(...)
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
end

function E:PLAYER_LOGIN()
	local isInstalled = self:IsInstalled()
	if (not isInstalled) then
		self:SetupUiScale()
		self:MarkAsInstalled()
	end

	-- load modules
	self:InitModules()
end

function E:SETTINGS_LOADED(...)
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true);
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_3", true);
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_4", true);
	Settings.SetValue("PROXY_SHOW_ACTIONBAR_5", true);
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", false);
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_7", false);
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_8", false);
end

function E:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    self:SetupDefaultsCVars()
end
