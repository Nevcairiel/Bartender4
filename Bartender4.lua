--[[ $Id$ ]]
local AceAddon = LibStub("AceAddon-3.0")
Bartender4 = AceAddon:NewAddon("Bartender4", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

local defaults = {
	profile = {
		tooltip = "enabled",
		buttonlock = false,
		outofrange = "button",
		colors = { range = { r = 0.8, g = 0.1, b = 0.1 }, mana = { r = 0.5, g = 0.5, b = 1.0 } },
		selfcastmodifier = true,
		selfcastrightclick = false,
	}
}

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
	
	self:SetupOptions()
	
	self.Locked = true
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatLockdown")
	MainMenuBarArtFrame:Hide()
	MainMenuBar:Hide()
	MainMenuBarArtFrame:UnregisterAllEvents()
end

--[[ function Bartender4:OnEnable()
	--
end
--]]

function Bartender4:RegisterDefaultsKey(key, subdefaults)
	defaults.profile[key] = subdefaults
	
	self.db:RegisterDefaults(defaults)
end

function Bartender4:UpdateModuleConfigs()
	for k,v in AceAddon:IterateModulesOfAddon(self) do
		v:ToggleModule()
		if v:IsEnabled() and type(v.ApplyConfig) == "function" then
			v:ApplyConfig()
		end
	end
end

function Bartender4:CombatLockdown()
	self:Lock()
	LibStub("AceConfigDialog-3.0"):Close("Bartender4") 
end

function Bartender4:ToggleLock()
	if self.Locked then
		self:Unlock()
	else
		self:Lock()
	end
end

function Bartender4:Unlock()
	if self.Locked then
		self.Locked = false
		Bartender4.Bar:ForAll("Unlock")
	end
end

function Bartender4:Lock()
	if not self.Locked then
		self.Locked = true
		Bartender4.Bar:ForAll("Lock")
	end
end

function Bartender4:Merge(target, source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:Merge(target[k], v)
		elseif not target[k] then
			target[k] = v
		end
	end
	return target
end

Bartender4.modulePrototype = {}
function Bartender4.modulePrototype:ToggleModule(info, value)
	if value ~= nil then
		self.db.profile.enabled = value
	else
		value = self.db.profile.enabled
	end
	if value and not self:IsEnabled() then
		self:Enable()
	elseif not value and self:IsEnabled() then
		self:Disable()
	end
end

function Bartender4.modulePrototype:ToggleOptions()
	if self.options then
		self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
	end
end
Bartender4:SetDefaultModulePrototype(Bartender4.modulePrototype)
