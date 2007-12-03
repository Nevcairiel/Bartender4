--[[ $Id: Bartender4.lua 56386 2007-12-01 14:21:40Z nevcairiel $ ]]

local Bar = Bartender4.Bar.prototype
local ActionBar = setmetatable({}, {__index = Bar})
Bartender4.ActionBar = ActionBar

local math_floor = math.floor

--[[
	Bar Prototype Functions
]]

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
	Bar.ApplyConfig(self, config)
	
	config = self.config
	if not config.Position then initialPosition(self) end
	
	self:UpdateButtons(config.Buttons)
end

-- Update the number of buttons in our bar, creating new ones if necessary
function ActionBar:UpdateButtons(numbuttons)
	if numbuttons then
		self.config.Buttons = numbuttons
	else
		numbuttons = self.config.Buttons
	end
	
	local buttons = self.buttons or {}
	
	-- create more buttons if needed
	for i = (#buttons+1), numbuttons do
		buttons[i] = Bartender4.Button:Create(i, self)
	end
	
	-- show active buttons
	for i = 1, numbuttons do
		buttons[i]:Show()
		buttons[i]:UpdateAction(true)
	end
	
	-- hide inactive buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
	end
	
	self.buttons = buttons
	
	self:UpdateButtonLayout()
end

-- align the buttons and correct the size of the bar overlay frame
function ActionBar:UpdateButtonLayout()
	local numbuttons = self.config.Buttons
	local buttons = self.buttons
	local pad = self.config.Padding
	
	local Rows = self.config.Rows
	local ButtonPerRow = math_floor(numbuttons / Rows + 0.5) -- just a precaution
	Rows = math_floor(numbuttons / ButtonPerRow + 0.5)
	
	self:SetSize((36 + pad) * ButtonPerRow - pad + 8, (36 + pad) * Rows - pad + 8)
	
	-- anchor button 1 to the topleft corner of the bar
	buttons[1]:ClearSetPoint("TOPLEFT", self, "TOPLEFT", 6, -3)
	-- and anchor all other buttons relative to our button 1
	for i = 2, numbuttons do
		-- jump into a new row
		if ((i-1) % ButtonPerRow) == 0 then
			buttons[i]:ClearSetPoint("TOPLEFT", buttons[i-ButtonPerRow], "BOTTOMLEFT", 0, -pad)
		-- align to the previous button
		else
			buttons[i]:ClearSetPoint("TOPLEFT", buttons[i-1], "TOPRIGHT", pad, 0)
		end
	end
end

function ActionBar:GetAll()
	return pairs(self.buttons)
end

function ActionBar:ForAll(method, ...)
	for _, button in self:GetAll() do
		local func = button[method]
		if func then
			func(button, ...)
		end
	end
end
