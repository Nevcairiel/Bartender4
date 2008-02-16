--[[ $Id$ ]]

local StanceBar = Bartender4:NewModule("StanceBar")
local ActionBars = Bartender4:GetModule("ActionBars")

local defaults = { profile = Bartender4:Merge({ enabled = true }, Bartender4.ButtonBar.defaults) }

function StanceBar:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StanceBar", defaults)
	
	self:SetupOptions()
end

function StanceBar:OnEnable()
	self.bar = Bartender4.ButtonBar:Create("stance", nil, self.db.profile)
	self.buttons = {}
	self.bar:ApplyConfig()
end

function StanceBar:SetupOptions()
	self.options = Bartender4.ButtonBar.prototype:GetOptionObject()
	ActionBars.options.args["stance"] = {
			order = 30,
			type = "group",
			name = "Stance Bar",
			desc = "Configure  the Stance Bar",
			childGroups = "tab",
		}
	ActionBars.options.args["stance"].args = self.options.table
end
