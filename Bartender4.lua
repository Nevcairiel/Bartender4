--[[ $Id$ ]]
Bartender4 = LibStub("AceAddon-3.0"):NewAddon("Bartender4", "AceConsole-3.0", "AceEvent-3.0")

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB")
end
