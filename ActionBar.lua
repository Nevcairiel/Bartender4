--[[
	Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local StateBar = Bartender4.StateBar.prototype
local ActionBar = setmetatable({}, {__index = StateBar})
Bartender4.ActionBar = ActionBar

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
	StateBar.ApplyConfig(self, config)

	if not self.config.position.x then initialPosition(self) end

	self:UpdateButtons()
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
		buttons[i]:SetParent(self)
		buttons[i]:Show()
		buttons[i]:SetAttribute("statehidden", nil)
		buttons[i]:Update()
	end

	-- hide inactive buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
		buttons[i]:SetAttribute("statehidden", true)
	end

	self.numbuttons = numbuttons
	self.buttons = buttons

	self:UpdateButtonLayout()
	self:SetGrid()
	if updateBindings and self.id == "1" then
		self.module:ReassignBindings()
	end

	-- need to re-set clickthrough after creating new buttons
	self:SetClickThrough()
	self:UpdateSelfCast() -- update selfcast and states
end

function ActionBar:SkinChanged(...)
	StateBar.SkinChanged(self, ...)
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
		self.module:DisableBar(self.id)
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
		self:ForAll("ShowGrid")
	else
		self:ForAll("HideGrid")
	end
	self:ForAll("UpdateGrid")
end
