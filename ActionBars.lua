--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local Bar = Bartender4.Bar.prototype
local ActionBar = setmetatable({}, {__index = Bar})

local ActionBar_MT = {__index = ActionBar}

local math_floor = math.floor

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
		Buttons = 1,
		Padding = 2,
		Rows = 12,
	},
	[1] = {
		Stances = stancedefaults,
	},
}

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db
	Bartender4:RegisterDefaultsKey("ActionBars", defaults)
end

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

function BT4ActionBars:ApplyConfig()
	for i,v in ipairs(self.actionbars) do
		v:ApplyConfig(self.db.profile.ActionBars[i])
		v:Unlock()
	end
end

local initialPosition
do
	function initialPosition(bar)
		bar:ClearSetPoint("CENTER", 0, -250 + (bar.id-1) * 38)
		bar:SavePosition()
	end
end

function BT4ActionBars:Create(id, config)
	local bar = setmetatable(Bartender4.Bar:Create(id, "SecureStateDriverTemplate", config), ActionBar_MT)
	-- TODO: Setup Buttons and set bar width before pulling initial position
	
	bar:ApplyConfig()
	-- debugging
	bar:Unlock()
	
	return bar
end

function ActionBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)
	
	config = self.config
	if not config.Position then initialPosition(self) end
	
	self:UpdateButtons(config.Buttons)
end

function ActionBar:UpdateButtons(numbuttons)
	local oldbuttons = self.config.Buttons
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
	end
	
	-- hide inactive buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
	end
	
	self.buttons = buttons
	
	self:UpdateButtonLayout()
end

function ActionBar:UpdateButtonLayout()
	local numbuttons = self.config.Buttons
	local buttons = self.buttons
	local pad = self.config.Padding
	
	local Rows = self.config.Rows
	local ButtonPerRow = math_floor(numbuttons / Rows + 0.5) -- just a precaution
	Rows = math_floor(numbuttons / ButtonPerRow + 0.5)
	
	self:SetSize((36 + pad) * ButtonPerRow - pad + 8, (36 + pad) * Rows - pad + 8)
	
	buttons[1]:ClearSetPoint("TOPLEFT", self, "TOPLEFT", 6, -3)
	for i = 2, numbuttons do
		if ((i-1) % ButtonPerRow) == 0 then
			buttons[i]:ClearSetPoint("TOPLEFT", buttons[i-ButtonPerRow], "BOTTOMLEFT", 0, -pad)
		else
			buttons[i]:ClearSetPoint("TOPLEFT", buttons[i-1], "TOPRIGHT", pad, 0)
		end
	end
end
