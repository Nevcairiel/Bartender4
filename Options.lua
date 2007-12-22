--[[ $Id$ ]]

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local getFunc, setFunc
do
	function getFunc(info)
		return (info.arg and Bartender4.db.profile[info.arg] or Bartender4.db.profile[info[#info]])
	end
	
	function setFunc(info, value)
		local key = info.arg or info[#info]
		Bartender4.db.profile[key] = value
	end
end

function Bartender4:SetupOptions()
	self.options = {
		type = "group",
		name = "Bartender4",
		icon = "Interface\\Icons\\INV_Drink_05",
		childGroups = "tree",
		plugins = {},
		args = {
			lock = {
				order = 1,
				type = "toggle",
				name = "Lock",
				desc = "Lock all bars.",
				get = function() return Bartender4.Locked end,
				set = function(info, value) Bartender4[value and "Lock" or "Unlock"](Bartender4) end,
			},
			buttonlock = {
				order = 2,
				type = "toggle",
				name = "Button Lock",
				desc = "Lock the buttons.",
				get = getFunc,
				set = setFunc,
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Bartender4", self.options, "bttest")
	local optFunc = function() 
		AceConfigDialog:Open("Bartender4") 
	--[[ 
		local status = AceConfigDialog:GetStatusTable("Bartender4")
		if not status.groups then status.groups = {} end 
		if not status.groups.groups then status.groups.groups = {} end 
		status.groups.groups["actionbars"] = true 
	]]
	end
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bar", optFunc)
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bt", optFunc)
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bt4", optFunc)
end

function Bartender4:RegisterModuleOptions(key, table)
	self.options.plugins[key] = { [key] = table }
end
