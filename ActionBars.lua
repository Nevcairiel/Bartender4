--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local ActionBar, ActionBar_MT

local abdefaults = {
	['**'] = Bartender4:Merge({
		enabled = true,
		buttons = 12,
		hidemacrotext = false,
		showgrid = false,
		style = "dream",
		states = { 
			enabled = false, 
			stance = { 
				default = 0, 
				['**'] = {
					['*'] = 0,
				},
			},
		},
	}, Bartender4.ButtonBar.defaults),
	[1] = {
		states = {
			enabled = true,
			stance = {
				DRUID = { bear = 9, cat = 7, prowl = 8 },
				WARRIOR = { battle = 7, def = 8, berserker = 9 },
				ROGUE = { stealth = 7 }
			},
		},
	},
	[7] = {
		enabled = false,
	},
	[8] = {
		enabled = false,
	},
	[9] = {
		enabled = false,
	},
	[10] = {
		enabled = false,
	},
}

local defaults = { 
	profile = { 
		outofrange = "button",
		colors = { range = { r = 0.8, g = 0.1, b = 0.1 }, mana = { r = 0.5, g = 0.5, b = 1.0 } },
		actionbars = abdefaults,
	} 
}

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ActionBars", defaults)
	
	
	self:SetupOptions()
	
	-- fetch the prototype information
	ActionBar = Bartender4.ActionBar
	ActionBar_MT = {__index = ActionBar}
end

-- setup the 10 actionbars
local first = true
function BT4ActionBars:OnEnable()
	if first then
		self.playerclass = select(2, UnitClass("player"))
		self.actionbars = {}
		for i=1,10 do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self.actionbars[i] = self:Create(i, config)
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end
		first = nil
	end
end

-- Applys the config in the current profile to all active Bars
function BT4ActionBars:ApplyConfig()
	for i=1,10 do
		local config = self.db.profile.actionbars[i]
		if config.enabled then
			self:EnableBar(i)
		else
			self:DisableBar(i)
		end
	end
end

function BT4ActionBars:UpdateButtons(force)
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

function BT4ActionBars:SetupOptions()
	self.options = {
		order = 20,
		type = "group",
		-- cmdInline = true,
		name = "Action Bars",
		get = getFunc,
		args = {
			range = {
				order = 1,
				name = "Out of Range Indicator",
				desc = "Configure how the Out of Range Indicator should display on the buttons.",
				type = "select",
				style = "dropdown",
				get = function()
					return BT4ActionBars.db.profile.outofrange
				end,
				set = function(info, value) 
					BT4ActionBars.db.profile.outofrange = value
					BT4ActionBars:ForAllButtons("UpdateUsable")
				end,
				values = { none = "No Display", button = "Full Button Mode", hotkey = "Hotkey Mode" },
			},
			colors = {
				order = 3,
				type = "group",
				guiInline = true,
				name = "Colors",
				get = function(info)
					local color = BT4ActionBars.db.profile.colors[info[#info]]
					return color.r, color.g, color.b
				end,
				set = function(info, r, g, b)
					local color = BT4ActionBars.db.profile.colors[info[#info]]
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
	Bartender4:RegisterModuleOptions("actionbars", self.options)
	
	
	self.disabledoptions = {
		general = {
			type = "group",
			name = "General Settings",
			cmdInline = true,
			order = 1,
			args = {
				enabled = {
					type = "toggle",
					name = "Enabled",
					desc = "Enable/Disable the bar.",
					set = function(info, v) if v then BT4ActionBars:EnableBar(info[2]) end end,
					get = function() return false end,
				}
			}
		}
	}
end

function BT4ActionBars:CreateBarOption(id, options)
	id = tostring(id)
	if not self.options.args[id] then
		self.options.args[id] = {
			order = 10 + tonumber(id),
			type = "group",
			name = ("Bar %s"):format(id),
			desc = ("Configure Bar %s"):format(id),
			childGroups = "tab",
		}
	end
	self.options.args[id].args = options
end

-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config)
	local id = tostring(id)
	local bar = setmetatable(Bartender4.ButtonBar:Create(id, "SecureStateHeaderTemplate", config), ActionBar_MT)
	bar.module = self
	
	self:CreateBarOption(id, self:GetOptionsTable())
	
	bar:ApplyConfig()
	
	return bar
end

function BT4ActionBars:DisableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	if not bar then return end
	
	bar.config.enabled = false
	bar.disabled = true
	bar:Hide()
	self:CreateBarOption(id, self.disabledoptions)
end

function BT4ActionBars:EnableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	local config = self.db.profile.actionbars[id]
	config.enabled = true
	if not bar then
		bar = self:Create(id, config)
		self.actionbars[id] = bar
	else
		bar.disabled = nil
		self:CreateBarOption(id, self:GetOptionsTable())
		bar:ApplyConfig(config)
	end
	if not Bartender4.Locked then
		bar:Unlock()
	end
end
