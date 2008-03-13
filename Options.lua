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
			bars = {
				order = 20,
				type = "group",
				name = "Bars",
				args = {
					range = {
						order = 1,
						name = "Out of Range Indicator",
						desc = "Configure how the Out of Range Indicator should display on the buttons.",
						type = "select",
						style = "dropdown",
						get = function()
							return Bartender4.db.profile.outofrange
						end,
						set = function(info, value) 
							Bartender4.db.profile.outofrange = value
							Bartender4.Bar:ForAll("ApplyConfig")
						end,
						values = { none = "No Display", button = "Full Button Mode", hotkey = "Hotkey Mode" },
					},
					colors = {
						order = 3,
						type = "group",
						guiInline = true,
						name = "Colors",
						get = function(info)
							local color = Bartender4.db.profile.colors[info[#info]]
							return color.r, color.g, color.b
						end,
						set = function(info, r, g, b)
							local color = Bartender4.db.profile.colors[info[#info]]
							color.r, color.g, color.b = r, g, b
							Bartender4.Bar:ForAll("ApplyConfig")
						end,
						args = {
							range = {
								order = 1,
								type = "color",
								name = "Out of Range Indicator",
								desc = "Specify the Color of the Out of Range Indicator",
							},
							mana = {
								order = 2,
								type = "color",
								name = "Out of Mana Indicator",
								desc = "Specify the Color of the Out of Mana Indicator",
							},
						},
					},
					tooltip = {
						order = 2,
						name = "Button Tooltip",
						type = "select",
						desc = "Configure the Button Tooltip.",
						values = { ["disabled"] = "Disabled", ["nocombat"] = "Disabled in Combat", ["enabled"] = "Enabled" },
						get = function() return Bartender4.db.profile.tooltip end,
						set = function(info, value) Bartender4.db.profile.tooltip = value end,
					},
				},
			}
		},
	}
	
	self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
	
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Bartender4", self.options, "bttest")
	local optFunc = function() 
		if InCombatLockdown() then return end
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

function Bartender4:RegisterBarOptions(id, table)
	self.options.args.bars.args[id] = table
end

local optionParent = {}
function optionParent:NewCategory(category, data)
	self.table[category] = data
end

local ov = nil
function optionParent:AddElement(category, element, data, ...)
	local lvl = self.table[category]
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if not (lvl.args[key] and lvl.args[key].args) then
			error(("Sub-Level Key %s does not exist in options group or is no sub-group."):format(key), ov and 3 or 2)
		end
		lvl = lvl.args[key]
	end
	
	lvl.args[element] = data
end

function optionParent:AddElementGroup(category, data, ...)
	ov = true
	for k,v in pairs(data) do
		self:AddElement(category, k, v, ...)
	end
	ov = nil
end

function Bartender4:NewOptionObject(otbl)
	if not otbl then otbl = {} end
	local tbl = { table = otbl }
	for k, v in pairs(optionParent) do
		tbl[k] = v
	end
	
	return tbl
end
