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
		bar:SetPoint("CENTER", 0, -250 + (bar.id-1) * 38)
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
	if not self.config.Position then initialPosition(self) end
end
