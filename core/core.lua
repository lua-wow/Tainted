local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- icon coordinates template
E.IconCoord = { 0.08, 0.92, 0.08, 0.92 }

--------------------------------------------------
-- Module
--------------------------------------------------
do
	-- registry lives in the closure, so it is never shared through Mixin
	local indexes, modules = {}, {}

	local ModuleMixin = {}

	-- one failing call reports through the error handler instead of aborting the caller
	function ModuleMixin:Call(func, ...)
		return xpcall(func, geterrorhandler(), ...)
	end

	function ModuleMixin:GetModule(name)
		return modules[name]
	end

	function ModuleMixin:SetModule(name, module)
		modules[name] = module
		return modules[name]
	end

	function ModuleMixin:CreateModule(name, proto)
		assert(not modules[name], "Module " .. name .. " already exists.")
		indexes[#indexes + 1] = name
		return self:SetModule(name, proto or {})
	end
	
	function ModuleMixin:InitModules()
		for _, name in ipairs(indexes) do
			local module = modules[name]
			if module.Init then
				-- the error handler's stack does not always reach the module, so name it
				if not self:Call(module.Init, module) then
					self:error("Module " .. name .. " failed to initialize.")
				end
			else
				self:error("Module " .. name .. " do not have 'Init' function.")
			end
		end
	end

	function ModuleMixin:UpdateModules()
		for _, module in next, modules do
			if module.Update then
				self:Call(module.Update, module)
			end
		end
	end

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
if (E.isStandard) then
	E:RegisterEvent("SETTINGS_LOADED")
end
E:RegisterEvent("PLAYER_ENTERING_WORLD")
E:SetScript("OnEvent", function (self, event, ...)
	assert(self[event], "Unable to locate " .. event .." event handler")
	self[event](self, ...)
end)

function E:ADDON_LOADED(name, containsBindings)
    if (name == self.addon) then
		self:InitDatabase()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function E:VARIABLES_LOADED(...)
	self.locale = GetLocale()
	self:UpdateFonts()
end

function E:PLAYER_LOGIN()
	if (not self.db.installed) then
		-- setup cvars
		self:SetupDefaultsCVars()
		self:SetupUiScale()

		-- fix bag sorting order
		if E.isStandard then
			C_Container.SetSortBagsRightToLeft(true)
			C_Container.SetInsertItemsLeftToRight(true)
		end
		
		self.db.installed = true
	else
		self:ApplyUiScale()
	end

	-- load modules
	self:InitModules()
end

function E:SETTINGS_LOADED(...)
	-- only write when needed, to avoid redundant addon-side writes on the multi-bar path
	for i = 2, 5 do
		local variable = "PROXY_SHOW_ACTIONBAR_" .. i
		if Settings.GetValue(variable) ~= true then
			Settings.SetValue(variable, true)
		end
	end
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", false)
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_7", false)
	-- Settings.SetValue("PROXY_SHOW_ACTIONBAR_8", false)
end

function E:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	if not self.db.chat then
		-- chat module is not loaded on every TOC
		local Chat = self:GetModule("Chat")
		if Chat then
			Chat:Reset()
			self.db.chat = true
		end
	end
end
