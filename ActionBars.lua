--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local ActionBar = Bartender4.ActionBar
local ActionBar_MT = {__index = ActionBar}

local stancedefaults = {
	DRUID = { bear = 9, cat = 7, prowl = 8 },
	WARRIOR = { battle = 7, def = 8, berserker = 9 },
	ROGUE = { stealth = 7 }
}

local defaults = Bartender4:Merge({
	['**'] = {
		Buttons = 12,
		Padding = 2,
		Rows = 1,
		HideMacrotext = false,
	},
	[1] = {
		Stances = stancedefaults,
	},
}, Bartender4.Bar.defaults)

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db
	Bartender4:RegisterDefaultsKey("ActionBars", defaults)
	
	self:SetupOptions()
end

-- setup the 10 actionbars
local first = true
function BT4ActionBars:OnEnable()
	if first then
		self.playerclass = select(2, UnitClass("player"))
		self.actionbars = {}
		for i=1,10 do
			local config = self.db.profile.ActionBars[i]
			if config.Enabled then
				self.actionbars[i] = self:Create(i, config)
			end
		end
		first = nil
	end
end

-- Applys the config in the current profile to all active Bars
function BT4ActionBars:ApplyConfig()
	for i,v in ipairs(self.actionbars) do
		v:ApplyConfig(self.db.profile.ActionBars[i])
	end
end

function BT4ActionBars:UpdateButtons()
	for i,v in ipairs(self.actionbars) do
		for j,button in ipairs(v.buttons) do
			button:UpdateAction(force)
		end
	end
end

function BT4ActionBars:GetAll()
	return pairs(self.actionbars)
end

function BT4ActionBars:ForAll(method, ...)
	for _, bar in self:GetAll() do
		local func = bar[method]
		if func then
			func(bar, ...)
		end
	end
end

function BT4ActionBars:ForAllButtons(...)
	self:ForAll("ForAll", ...)
end

local getFunc
do
	function getFunc(info)
		local key = info.arg or info[#info]
		return Bartender4.db.profile[key]
	end
end

function BT4ActionBars:SetupOptions()
	self.options = {
		order = 20,
		type = "group",
		-- cmdInline = true,
		name = "Action Bars",
		get = getFunc,
		args = {
			general = {
				order = 1,
				type = "group",
				guiInline = true,
				name = "General Options",
				args = {
					range = {
						order = 1,
						name = "Out of Range Indicator",
						desc = "Configure how the Out of Range Indicator should display on the buttons.",
						type = "select",
						style = "dropdown",
						arg = "OutOfRange",
						set = function(info, value) 
							Bartender4.db.profile.OutOfRange = value
							BT4ActionBars:ForAllButtons("UpdateUsable")
						end,
						values = { none = "No Display", button = "Full Button Mode", hotkey = "Hotkey Mode" },
					},
					colors = {
						order = 2,
						type = "group",
						guiInline = true,
						name = "Colors",
						get = function(info)
							local color = Bartender4.db.profile.Colors[info[#info]]
							return color.r, color.g, color.b
						end,
						set = function(info, r, g, b)
							local color = Bartender4.db.profile.Colors[info[#info]]
							color.r, color.g, color.b = r, g, b
							BT4ActionBars:ForAllButtons("UpdateUsable")
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
				},
			},
		},
	}
	Bartender4:RegisterModuleOptions("actionbars", self.options)
end

local getBar, optGetter, optSetter, optionMap, callFunc
do
	optionMap = {
		padding = "Padding",
	}
	
	function getBar(id)
		local bar = BT4ActionBars.actionbars[tonumber(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function."..func)
		return bar[func](bar, ...)
	end
	
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Get", option)
	end
	
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Set", option, ...)
	end
end

function BT4ActionBars:GetOptionsTable()
	if not self.baroptions then
		self.baroptions = Bartender4:Merge({
			general = {
				-- type = inherited
				-- name = inherited
				-- cmdInline = inherited
				order = 1,
				args = {
					style = {
						-- type = inherited
						-- name = inherited
						-- inline = inherited
						args = {
							padding = {
								type = "range",
								name = "Padding",
								desc = "Configure the padding of the buttons.",
								min = -10, max = 20, step = 1,
								set = optSetter,
								get = optGetter,
							},
						},
					},
				},
			},
			swap = {
				type = "group",
				name = "Page Swapping",
				cmdInline = true,
				order = 2,
				args = {},
			},
			align = {
				-- type = inherited
				-- name = inherited
				-- cmdInline = inherited
				order = 3,
				args = {},
			}
		}, Bartender4.Bar:GetOptionTable())
	end
	
	return self.baroptions
end

-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config)
	local id = tostring(id)
	local bar = setmetatable(Bartender4.Bar:Create(id, "SecureStateHeaderTemplate", config), ActionBar_MT)
	
	local options = self:GetOptionsTable()
	
	self.options.args[id] = {
		order = 10 + tonumber(id),
		type = "group",
		name = ("Bar %s"):format(id),
		desc = ("Configure Bar %s"):format(id),
		args = options,
		childGroups = "tab",
	}
	
	bar:ApplyConfig()
	-- debugging
	--bar:Unlock()
	
	return bar
end
