--[[ $Id: StanceBar.lua 61678 2008-02-17 01:37:33Z nevcairiel $ ]]

-- register module
local PetBarMod = Bartender4:NewModule("PetBar")

-- fetch upvalues
local ActionBars = Bartender4:GetModule("ActionBars")
local ButtonBar = Bartender4.ButtonBar.prototype

-- create prototype information
local PetBar = setmetatable({}, {__index = ButtonBar})
local PetButtonPrototype = CreateFrame("CheckButton")
local PetButton_MT = {__index = PetButtonPrototype}

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	scale = 1.5,
}, Bartender4.ButtonBar.defaults) }

function PetBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("PetBar", defaults)
	
	self:SetupOptions()
end

function PetBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Pet", nil, self.db.profile), {__index = PetBar})
		
		self.bar:ClearSetPoint("CENTER")
		self.bar:ApplyConfig()
		self.bar:SetScript("OnEvent", PetBar.OnEvent)
	end
end

function PetBarMod:OnDisable()
	if not self.bar then return end
	self.bar:UnregisterAllEvents()
	self.bar:Hide()
end

function PetBarMod:SetupOptions()
	self.options = Bartender4.ButtonBar.prototype:GetOptionObject()
	
	ActionBars.options.args["pet"] = {
			order = 30,
			type = "group",
			name = "Pet Bar",
			desc = "Configure  the Pet Bar",
			childGroups = "tab",
		}
	ActionBars.options.args["stance"].args = self.options.table
end

function PetBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end
