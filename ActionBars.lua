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
	
	for i=1,10 do
		actionbars[i] = ActionBar:Create(i, self.db.profile.Bars[i])
	end
end

function ActionBar:Create(id, config)
	local bar = setmetatable(Bartender4.Bar:Create(id, "SecureStateDriverTemplate", config), ActionBar_MT)
	if not config.x or not config.y then
		bar:SetPoint("CENTER", 0, -250 + (id-1) * 38)
		bar:SavePosition()
	else
		bar:LoadPosition()
	end
	bar:Unlock()
	
	return bar
end
