--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars", "AceEvent-3.0")

local ActionBar, ActionBar_MT

local abdefaults = {
	['**'] = Bartender4:Merge({
		enabled = true,
		buttons = 12,
		hidemacrotext = false,
		hidehotkey = false,
		showgrid = false,
		autoassist = false,
		states = { 
			enabled = false, 
			possess = false,
			actionbar = false,
			default = 0, 
			ctrl = 0,
			alt = 0,
			shift = 0,
			stance = { 
				['*'] = {
					['*'] = 0,
				},
			},
		},
	}, Bartender4.ButtonBar.defaults),
	[1] = {
		states = {
			enabled = true,
			possess = true,
			actionbar = true,
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
		actionbars = abdefaults,
	} 
}

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ActionBars", defaults)
	
	-- fetch the prototype information
	ActionBar = Bartender4.ActionBar
	ActionBar_MT = {__index = ActionBar}
end


local LBF = LibStub("LibButtonFacade", true)

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
	
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
end

function BT4ActionBars:SetupOptions()
	if not self.options then
		-- empty table to hold the bar options
		self.options = {}
		
		-- template for disabled bars
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
		
		-- iterate over bars and create their option tables
		for i=1,10 do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self:CreateBarOption(i)
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end
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

-- we do not allow to disable the actionbars module
function BT4ActionBars:ToggleModule()
	return
end

function BT4ActionBars:UpdateButtons(force)
	for i,v in ipairs(self.actionbars) do
		for j,button in ipairs(v.buttons) do
			button:UpdateAction(force)
		end
	end
end

function BT4ActionBars:CreateBarOption(id, options)
	if not self.options then return end
	
	if not options then 
		options = self:GetOptionsTable() 
	end
	
	id = tostring(id)
	if not self.options[id] then
		self.options[id] = {
			order = 10 + tonumber(id),
			type = "group",
			name = ("Bar %s"):format(id),
			desc = ("Configure Bar %s"):format(id),
			childGroups = "tab",
		}
	end
	self.options[id].args = options
	
	-- register options in the BT GUI
	Bartender4:RegisterBarOptions(id, self.options[id])
end

function BT4ActionBars:ReassignBindings()
	if not self.actionbars or not self.actionbars[1] then return end
	local frame = self.actionbars[1]
	ClearOverrideBindings(frame)
	for i = 1,min(#frame.buttons, 12) do
		local button, real_button = ("ACTIONBUTTON%d"):format(i), ("BT4Button%dSecure"):format(i)
		for k=1, select('#', GetBindingKey(button)) do
			local key = select(k, GetBindingKey(button))
			SetOverrideBindingClick(frame, false, key, real_button)
		end
	end
end

-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config)
	local id = tostring(id)
	local bar = setmetatable(Bartender4.ButtonBar:Create(id, config), ActionBar_MT)
	bar.module = self
	
	self:CreateBarOption(id)
	
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
		self:CreateBarOption(id)
		bar:ApplyConfig(config)
	end
	if not Bartender4.Locked then
		bar:Unlock()
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
