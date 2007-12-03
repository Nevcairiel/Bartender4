--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local ActionBar = Bartender4.ActionBar
local ActionBar_MT = {__index = ActionBar}

local stancedefaults = {
	DRUID = { bear = 9, cat = 7, prowl = 8 },
	WARRIOR = { battle = 7, def = 8, berserker = 9 },
	ROGUE = { stealth = 7 }
}

local defaults = {
	['**'] = {
		Enabled = true,
		Scale = 1,
		Alpha = 1,
		Buttons = 12,
		Padding = 2,
		Rows = 1,
		HideMacrotext = false,
	},
	[1] = {
		Stances = stancedefaults,
	},
}

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
		--cmdInline = true,
		name = "Action Bars",
		get = getFunc,
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
	}
	Bartender4:RegisterModuleOptions("actionbars", self.options)
end


-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config)
	local bar = setmetatable(Bartender4.Bar:Create(id, "SecureStateHeaderTemplate", config), ActionBar_MT)

	bar:ApplyConfig()
	-- debugging
	--bar:Unlock()
	
	return bar
end
