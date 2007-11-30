--[[ $Id: Bartender3.lua 49922 2007-09-26 20:15:15Z nevcairiel $ ]]

local BT4ActionBars = Bartender4:NewModule("ActionBars")

local Bar = Bartender4.Bar
local ActionBar = setmetatable({}, {__index = Bar})

local ActionBar_MT = {__index = ActionBar}

local actionbars = {}
function BT4ActionBars:OnInitialize()
	for i=1,10 do
		actionbars[i] = ActionBar:Create(i)
	end
end

function ActionBar:Create(id)
	local bar = setmetatable(Bar:Create(id, "SecureStateDriverTemplate"), ActionBar_MT)
end
