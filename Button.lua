--[[
	Action Button Template
]]

--[[ $Id: Bar.lua 56326 2007-11-30 15:11:00Z nevcairiel $ ]]

local Button = CreateFrame("CheckButton")
local Button_MT = {__index = Button}

Bartender4.Button = {}
Bartender4.Button.prototype = Button
function Bartender4.Button:Create(id, parent)
	local absid = (parent.id - 1) * 12 + id
	local name =  ("BT4Button%d"):format(absid)
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate"), Button_MT)
	
	button:SetAttribute("type", "action")
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-statebutton", true)
	button:SetAttribute("useparent-actionpage", nil)
	
	button:SetAttribute("action", absid)
	
	this = button
	ActionButton_UpdateAction()
	
	_G[("%sNormalTexture"):format(name)]:Hide()
	
	button:Show()
	
	return button
end

function Button:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
