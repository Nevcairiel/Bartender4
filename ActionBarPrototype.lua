--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local ButtonBar = Bartender4.ButtonBar.prototype
local ActionBar = setmetatable({}, {__index = ButtonBar})
Bartender4.ActionBar = ActionBar

--[[===================================================================================
	ActionBar Options
===================================================================================]]--

local module = Bartender4:GetModule("ActionBars")

-- option utilty functions
local optGetter, optSetter
do
	local optionMap, getBar, callFunc
	-- maps option keys to function names
	optionMap = {
		buttons = "Buttons",
		enabled = "Enabled",
		grid = "Grid",
		macrotext = "HideMacroText",
		hotkey = "HideHotkey",
	}
	
	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		local bar = module.actionbars[tonumber(id)]
		assert(bar, ("Invalid bar id in options table. (%s)"):format(id))
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], ("Invalid get/set function %s in bar %s."):format(func, bar.id))
		return bar[func](bar, ...)
	end
	
	-- universal function to get a option
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Get", option)
	end
	
	-- universal function to set a option
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Set", option, ...)
	end
end

-- returns the option table used for all action bars
-- creates it, if the first time called
-- the Universal Bar option table is merged into this, alot of stuff gets inherited.
function module:GetOptionsTable()
	return self:GetOptionsObject().table
end

function module:GetOptionsObject()
	if not self.baroptions then
		local obj = ButtonBar.GetOptionObject(self)
		
		local cat_general = {
			enabled ={
				order = 4,
				name = L["Enabled"],
				desc = L["Enable/Disable the bar."],
				type = "toggle",
				set = optSetter,
				get = optGetter,
			},
			grid = {
				order = 60,
				type = "toggle",
				name = L["Button Grid"],
				desc = L["Toggle the button grid."],
				set = optSetter,
				get = optGetter,
			},
			buttons = {
				order = 50,
				name = L["Buttons"],
				desc = L["Number of buttons."],
				type = "range",
				min = 1, max = 12, step = 1,
				set = optSetter,
				get = optGetter,
			},
			hidedesc = {
				order = 80,
				name = L["Button Look"],
				type = "header",
			},
			macrotext = {
				order = 81,
				type = "toggle",
				name = L["Hide Macro Text"],
				desc = L["Hide the Macro Text on the buttons of this bar."],
				set = optSetter,
				get = optGetter,
			},
			hotkey = {
				order = 82,
				type = "toggle",
				name = L["Hide Hotkey"],
				desc = L["Hide the Hotkey on the buttons of this bar."],
				set = optSetter,
				get = optGetter,
			},
		}
		obj:AddElementGroup("general", cat_general)
		
		local states = {
			type = "group",
			name = L["State Configuration"],
			cmdInline = true,
			order = 2,
			args = self:GetStateOptionsTable(),
		}
		obj:NewCategory("state", states)
		
		self.baroptions = obj
	end
	
	return self.baroptions
end

--[[===================================================================================
	ActionBar Prototype
===================================================================================]]--

local initialPosition
do 
	-- Sets the Bar to its initial Position in the Center of the Screen
	function initialPosition(bar)
		bar:ClearSetPoint("CENTER", 0, -250 + (bar.id-1) * 38)
		bar:SavePosition()
	end
end

-- Apply the specified config to the bar and refresh all settings
function ActionBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)
	
	config = self.config
	if not config.position then initialPosition(self) end
	
	self:UpdateButtons()
	self:UpdateSelfCast(true)
	self:UpdateStates()
end

-- Update the number of buttons in our bar, creating new ones if necessary
function ActionBar:UpdateButtons(numbuttons)
	if numbuttons then
		self.config.buttons = min(numbuttons, 12)
	else
		numbuttons = min(self.config.buttons, 12)
	end
	
	local buttons = self.buttons or {}
	
	local updateBindings = (numbuttons > #buttons)
	-- create more buttons if needed
	for i = (#buttons+1), numbuttons do
		buttons[i] = Bartender4.Button:Create(i, self)
	end
	
	-- show active buttons
	for i = 1, numbuttons do
		self:SetAttribute("addchild", buttons[i])
		buttons[i]:Show()
		buttons[i]:Update()
	end
	
	-- hide inactive buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
	end
	
	self.numbuttons = numbuttons
	self.buttons = buttons
	
	self:UpdateButtonLayout()
	self:SetGrid()
	if updateBindings and self.id == "1" then
		module:ReassignBindings()
	end
end

function ActionBar:SkinChanged(...)
	ButtonBar.SkinChanged(self, ...)
	self:ForAll("Update")
end


--[[===================================================================================
	ActionBar Config Interface
===================================================================================]]--


-- get the current number of buttons
function ActionBar:GetButtons()
	return self.config.buttons
end

-- set the number of buttons and refresh layout
ActionBar.SetButtons = ActionBar.UpdateButtons

function ActionBar:GetEnabled()
	return true
end

function ActionBar:SetEnabled(state)
	if not state then
		module:DisableBar(self.id)
	end
end

function ActionBar:GetGrid()
	return self.config.showgrid
end

function ActionBar:SetGrid(state)
	if state ~= nil then
		self.config.showgrid = state
	end
	if self.config.showgrid then
		self:ForAll("ShowGrid", true)
	else
		self:ForAll("HideGrid", true)
	end
end

function ActionBar:SetHideMacroText(state)
	if state ~= nil then
		self.config.hidemacrotext = state
	end
	self:ForAll("Update")
end

function ActionBar:GetHideMacroText()
	return self.config.hidemacrotext
end

function ActionBar:SetHideHotkey(state)
	if state ~= nil then
		self.config.hidehotkey = state
	end
	self:ForAll("UpdateHotkey")
end

function ActionBar:GetHideHotkey()
	return self.config.hidehotkey
end

function ActionBar:UpdateSelfCast(nostates)
	self:ForAll("SetAttribute", "checkselfcast", Bartender4.db.profile.selfcastmodifier and true or nil)
	if not nostates then
		self:UpdateStates()
	end
end
