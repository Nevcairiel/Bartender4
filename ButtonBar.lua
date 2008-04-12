--[[ $Id$ ]]

--[[ Generic Template for a Bar which contains Buttons ]]

local Bar = Bartender4.Bar.prototype
local ButtonBar = setmetatable({}, {__index = Bar})
local ButtonBar_MT = {__index = ButtonBar}

local defaults = Bartender4:Merge({
	padding = 2,
	rows = 1,
	skin = {
		ID = "DreamLayout",
		Backdrop = true,
		Gloss = false,
	},
}, Bartender4.Bar.defaults)

Bartender4.ButtonBar = {}
Bartender4.ButtonBar.prototype = ButtonBar
Bartender4.ButtonBar.defaults = defaults

local LBF = LibStub("LibButtonFacade", true)

function Bartender4.ButtonBar:Create(id, template, config)
	local bar = setmetatable(Bartender4.Bar:Create(id, template, config), ButtonBar_MT)
	
	if LBF then
		bar.LBFGroup = LBF:Group("Bartender4", tostring(id))
		bar.LBFGroup.SkinID = config.skin.ID or "Blizzard"
		bar.LBFGroup.Backdrop = config.skin.Backdrop
		bar.LBFGroup.Gloss = config.skin.Gloss
		
		LBF:RegisterSkinCallback("Bartender4", self.SkinChanged, self)
	end
	
	return bar
end

local barregistry = Bartender4.Bar.barregistry
function Bartender4.ButtonBar:SkinChanged(SkinID, Gloss, Backdrop, Group, Button)
	local bar = barregistry[tostring(Group)]
	if not bar then return end
	
	bar:SkinChanged(SkinID, Gloss, Backdrop, Button)
end

--[[===================================================================================
	Bar Options
===================================================================================]]--

-- option utilty functions
local optGetter, optSetter
do
	local getBar, optionMap, callFunc
	local barregistry = Bartender4.Bar.barregistry
	-- maps option keys to function names
	optionMap = {
		rows = "Rows",
		padding = "Padding",
	}
	
	-- retrieves a valid bar object from the barregistry table
	function getBar(id)
		local bar = barregistry[tostring(id)]
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

local options
function ButtonBar:GetOptionObject()
	local obj = Bar.GetOptionObject()
	local otbl_general = {
		padding = {
			order = 40,
			type = "range",
			name = "Padding",
			desc = "Configure the padding of the buttons.",
			min = -10, max = 20, step = 1,
			set = optSetter,
			get = optGetter,
		},
		rows = {
			order = 70,
			name = "Rows",
			desc = "Number of rows.",
			type = "range",
			min = 1, max = 12, step = 1,
			set = optSetter,
			get = optGetter,
		},
	}
	obj:AddElementGroup("general", otbl_general)
	return obj
end


function ButtonBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)
	-- any module inherting this template should call UpdateButtonLayout after setting up its buttons, we cannot call it here
	--self:UpdateButtonLayout()
end

-- get the current padding
function ButtonBar:GetPadding()
	return self.config.padding
end

-- set the padding and refresh layout
function ButtonBar:SetPadding(pad)
	if pad ~= nil then
		self.config.padding = pad
	end
	self:UpdateButtonLayout()
end


-- get the current number of rows
function ButtonBar:GetRows()
	return self.config.rows
end

-- set the number of rows and refresh layout
function ButtonBar:SetRows(rows)
	if rows ~= nil then
		self.config.rows = rows
	end
	self:UpdateButtonLayout()
end

local math_floor = math.floor
-- align the buttons and correct the size of the bar overlay frame
ButtonBar.button_width = 36
ButtonBar.button_height = 36
function ButtonBar:UpdateButtonLayout()
	local buttons = self.buttons
	local pad = self:GetPadding()
	
	local numbuttons = self.numbuttons or #buttons
	
	-- bail out if the bar has no buttons, for whatever reason
	-- (eg. stanceless class, or no stances learned yet, etc.)
	if numbuttons == 0 then return end
	
	local Rows = self:GetRows()
	local ButtonPerRow = math_floor(numbuttons / Rows + 0.5) -- just a precaution
	Rows = math_floor(numbuttons / ButtonPerRow + 0.5)
	
	self:SetSize((self.button_width + pad) * ButtonPerRow - pad + 8, (self.button_height + pad) * Rows - pad + 8)
	
	-- anchor button 1 to the topleft corner of the bar
	buttons[1]:ClearSetPoint("TOPLEFT", self, "TOPLEFT", 5, -3)
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

function ButtonBar:SkinChanged(SkinID, Gloss, Backdrop, Button)
	self.config.skin.ID = SkinID
	self.config.skin.Gloss = Gloss
	self.config.skin.Backdrop = Backdrop
end

--[[===================================================================================
	Utility function
===================================================================================]]--

-- get a iterator over all buttons
function ButtonBar:GetAll()
	return pairs(self.buttons)
end

-- execute a member function on all buttons
function ButtonBar:ForAll(method, ...)
	if not self.buttons then return end
	for _, button in self:GetAll() do
		local func = button[method]
		if func then
			func(button, ...)
		end
	end
end
