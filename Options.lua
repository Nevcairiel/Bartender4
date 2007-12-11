--[[ $Id$ ]]

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
			gui = {
				type = "execute",
				name = "gui",
				order = 1,
				desc = "Open GUI",
				func = function() LibStub("AceConfigDialog-3.0"):Open("Bartender4") end,
				guiHidden = true,
			},
			general = {
				order = 10,
				type = "group",
				--cmdInline = true,
				name = "General Settings",
				get = getFunc,
				set = setFunc,
				args = {},
			},
			lock = {
				dialogHidden = true,
				type = "toggle",
				name = "Lock/Unlock the bars.",
				get = function() return Bartender4.Locked end,
				set = function(info, value) Bartender4:ToggleLock(value) end,
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Bartender4", self.options, {"bar", "bt", "bt4"})
end

function Bartender4:RegisterModuleOptions(key, table)
	self.options.plugins[key] = { [key] = table }
end
