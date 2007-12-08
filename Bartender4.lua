--[[ $Id$ ]]
local AceAddon = LibStub("AceAddon-3.0")
Bartender4 = AceAddon:NewAddon("Bartender4", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
	profile = {
		OutOfRange = "button",
		Colors = { range = { r = 0.8, g = 0.1, b = 0.1 }, mana = { r = 0.5, g = 0.5, b = 1.0 } },
	}
}

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB")
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
	
	self:SetupOptions()
end

function Bartender4:RegisterDefaultsKey(key, subdefaults)
	defaults.profile[key] = subdefaults
	
	self.db:RegisterDefaults(defaults)
end

function Bartender4:UpdateModuleConfigs()
	for k,v in AceAddon:IterateModulesOfAddon("Bartender4") do
		if type(v.ApplyConfig) == "function" then
			v:ApplyConfig()
		end
	end
end

function Bartender4:Update()
	for k,v in AceAddon:IterateModulesOfAddon("Bartender4") do
		if type(v.Update) == "function" then
			v:Update()
		end
	end
end

function Bartender4:Merge(target, source)
	if not target then target = {} end
		for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:Merge(target[k], v)
		elseif not target[k] then
			target[k] = v
		end
	end
	return target
end
