--[[
	Copyright (c) 2009-2022, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- WoW Classic (and 9.x) uses the old code
if select(4, GetBuildInfo()) < 100000 then
	return
end

function Bartender4:HideBlizzard()
	-- Hidden parent frame
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	self.UIHider = UIHider

end
