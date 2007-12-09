--[[ $Id$ ]]

local Bar = Bartender4.Bar.prototype
local ActionBar = setmetatable({}, {__index = Bar})
Bartender4.ActionBar = ActionBar

local math_floor = math.floor

--[[===================================================================================
	ActionBar Options
===================================================================================]]--

local module

-- option utilty functions
local getBar, optGetter, optSetter, optionMap, callFunc
do
	-- maps option keys to function names
	optionMap = {
		padding = "Padding",
		buttons = "Buttons",
		rows = "Rows",
	}
	
	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		if not module then
			module = Bartender4:GetModule("ActionBars")
		end
		local bar = module.actionbars[tonumber(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function."..func)
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

local baroptions

-- returns the option table used for all action bars
-- creates it, if the first time called
-- the Universal Bar option table is merged into this, alot of stuff gets inherited.
function ActionBar:GetOptionsTable()
	if not baroptions then
		baroptions = Bartender4:Merge({
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
					layout = {
						type = "group",
						name = "Layout",
						inline = true,
						order = 10,
						set = optSetter,
						get = optGetter,
						args = {
							buttons = {
								name = "Buttons",
								desc = "Number of buttons.",
								type = "range",
								min = 1, max = 12, step = 1,
							},
							rows = {
								name = "Rows",
								desc = "Number of rows.",
								type = "range",
								min = 1, max = 12, step = 1,
							},
						},
					}
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
		}, Bar.GetOptionTable(self))
	end
	
	return baroptions
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
	Bar.ApplyConfig(self, config)
	
	config = self.config
	if not config.Position then initialPosition(self) end
	
	self:UpdateButtons()
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
	local numbuttons = self:GetButtons()
	local buttons = self.buttons
	local pad = self:GetPadding()
	
	local Rows = self:GetRows()
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

--[[===================================================================================
	ActionBar Config Interface
===================================================================================]]--

-- get the current padding
function ActionBar:GetPadding()
	return self.config.Padding
end

-- set the padding and refresh layout
function ActionBar:SetPadding(pad)
	if pad then
		self.config.Padding = pad
	end
	self:UpdateButtonLayout()
end

-- get the current number of buttons
function ActionBar:GetButtons()
	return self.config.Buttons
end

-- set the number of buttons and refresh layout
ActionBar.SetButtons = ActionBar.UpdateButtons

-- get the current number of rows
function ActionBar:GetRows()
	return self.config.Rows
end

-- set the number of rows and refresh layout
function ActionBar:SetRows(rows)
	if rows then
		self.config.Rows = rows
	end
	self:UpdateButtonLayout()
end

--[[===================================================================================
	Utility function
===================================================================================]]--

-- get a iterator over all buttons
function ActionBar:GetAll()
	return pairs(self.buttons)
end

-- execute a member function on all buttons
function ActionBar:ForAll(method, ...)
	for _, button in self:GetAll() do
		local func = button[method]
		if func then
			func(button, ...)
		end
	end
end
