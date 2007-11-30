--[[ $Id$ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local Bar = Bartender4.Bar.prototype
local ActionBar = setmetatable({}, {__index = Bar})

local ActionBar_MT = {__index = ActionBar}

local defaults = {
	profile = {
		Bars = {
			['**'] = {
				Scale = 1,
				Alpha = 1,
				Buttons = 12,
				Padding = 2,
			}
		}
	}
}

local actionbars = {}
function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ActionBars", defaults)
end

function BT4ActionBars:OnEnable()
	for i=1,10 do
		actionbars[i] = self:Create(i, self.db.profile.Bars[i])
	end
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplyConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplyConfig")
end

function BT4ActionBars:ApplyConfig()
	for i,v in ipairs(actionbars) do
		v:ApplyConfig(self.db.profile.Bars[i])
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
	if #buttons < numbuttons then
		for i = (#buttons+1), numbuttons do
			buttons[i] = Bartender4.Button:Create(i, self)
		end
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
	
	self:SetSize((36 + pad) * numbuttons + 8, 36 + 8)
	
	buttons[1]:ClearSetPoint("TOPLEFT", self, "TOPLEFT", 5, -3)
	for i = 2, numbuttons do
		buttons[i]:ClearSetPoint("TOPLEFT", buttons[i-1], "TOPRIGHT", pad, 0)
	end
end
