--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local StateBar = Bartender4.StateBar.prototype
local ActionBar = Bartender4.ActionBar

local WoW10 = select(4, GetBuildInfo()) >= 100000

local tonumber, tostring, assert = tonumber, tostring, assert

--[[===================================================================================
	ActionBar Options
===================================================================================]]--

local module = Bartender4:GetModule("ActionBars")

-- option utilty functions
local optGetter, optSetter
do
	local optionMap, getBar, callFunc
	-- maps option keys to function names
	optionMap = {
		buttons = "Buttons",
		enabled = "Enabled",
		grid = "Grid",
		flyoutDirection = "FlyoutDirection",
		buttonOffset = "ButtonOffset",
		border = "HideBorder",
		fontsize = "FontSize",
		HotkeyXAnchor = "HotkeyXAnchor",
		HotkeyYAnchor = "HotkeyYAnchor",
		Chargefontsize = "ChargeFontSize",
		ChargeXAnchor = "ChargeXAnchor",
		ChargeYAnchor = "ChargeYAnchor",
	}

	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		local bar = module.actionbars[tonumber(id)]
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

-- returns the option table used for all action bars
-- creates it, if the first time called
-- the Universal Bar option table is merged into this, alot of stuff gets inherited.
function module:GetOptionsTable()
	return self:GetOptionsObject().table
end

function module:GetOptionsObject()
	if not self.baroptions then
		local obj = StateBar.GetOptionObject(self)

		local cat_general = {
			enabled ={
				order = 4,
				name = L["Enabled"],
				desc = L["Enable/Disable the bar."],
				type = "toggle",
				width = "full",
				set = optSetter,
				get = optGetter,
			},
			grid = {
				order = 60,
				type = "toggle",
				name = L["Button Grid"],
				desc = L["Toggle the button grid."],
				set = optSetter,
				get = optGetter,
			},
			buttons = {
				order = 50,
				name = L["Buttons"],
				desc = L["Number of buttons."],
				type = "range",
				min = 1, max = 12, step = 1,
				set = optSetter,
				get = optGetter,
			},
			flyoutDirection = {
				order = 79,
				name = L["Flyout Direction"],
				desc = L["Direction of the button flyouts on this bar (eg. summon demon/pet)"],
				type = "select",
				values = {LEFT = L["Left"], RIGHT = L["Right"], UP = L["Up"], DOWN = L["Down"]},
				set = optSetter,
				get = optGetter,
			},
			buttonOffset = {
				order = 202,
				name = L["Button Offset"],
				desc = L["How many buttons to offset the action to the left. This can be used, for example, to use the same actions on two individual shorter bars (front and back)."],
				type = "range",
				min = 0, max = 11, step = 1,
				set = optSetter,
				get = optGetter,
			},
			border = {
				order = 84,
				type = "toggle",
				name = L["Hide Border"],
				desc = L["Hide the border around the action button."],
				set = optSetter,
				get = optGetter,
				hidden = not WoW10,
			},
			HotkeyFontSize = {
				order = 301,
				name = L["Font Size"],
				desc = L["Configure the shortcut font size"],
				type = "range",
				min = 4,  max = 40, step = 2,
				get = optGetter,
				set = optSetter,
			},
			HotkeyXAnchor = {
				order = 303,
				name = L["Hotkey X Anchor"],
				desc = L["Set the X offset of the hotkey anchor"],
				type = "range",
				min = -20,  max = 20, step = 0.5,
				get = optGetter,
				set = optSetter,
			},
			HotkeyYAnchor = {
				order = 304,
				name = L["Hotkey Y Anchor"],
				desc = L["Set the X offset of the hotkey anchor"],
				type = "range",
				min = -20,  max = 20, step = 0.5,
				get = optGetter,
				set = optSetter,
			},
			ChargeFontSize = {
				order = 301,
				name = L["Charge Font Size"],
				desc = L["Configure the charge font size"],
				type = "range",
				min = 4,  max = 40, step = 2,
				get = optGetter,
				set = optSetter,
			},
			ChargeXAnchor = {
				order = 303,
				name = L["Charge X Anchor"],
				desc = L["Set the X offset of the charge anchor"],
				type = "range",
				min = -20,  max = 20, step = 0.5,
				get = optGetter,
				set = optSetter,
			},
			ChargeYAnchor = {
				order = 304,
				name = L["Charge Y Anchor"],
				desc = L["Set the X offset of the charge anchor"],
				type = "range",
				min = -20,  max = 20, step = 0.5,
				get = optGetter,
				set = optSetter,
			},
		}
		obj:AddElementGroup("general", cat_general)
		self.baroptions = obj
	end

	return self.baroptions
end

function module:CreateBarOption(id, options)
	if not self.options then return end

	if not options then
		options = self:GetOptionsTable()
	end

	id = tostring(id)
	if not self.options[id] then
		local barID = tonumber(id)
		local order = 10 + barID
		local name = self:GetBarName(id)
		local desc = (L["Configure Bar %s"]):format(id)
		-- remap WoW10 bars
		if WoW10 then
			if barID == 7 or barID == 8 or barID == 9 or barID == 10 then
				order = 13 + barID
				desc = (L["Configure Class Bar %d"]):format(barID - 6) .. "\n\n" .. L["Usually used for druid shapeshift forms, but can be re-used for additional bars on other classes"]
			elseif self.BLIZZARD_BAR_MAP[barID] then
				barID = self.BLIZZARD_BAR_MAP[barID]
				order = 10 + barID
				desc = (L["Configure Bar %s"]):format(tostring(barID))
			elseif barID == 2 then
				order = 19
				desc = L["Configure the Bonus Action Bar"] .. "\n\n" .. L["By default this bar is used as the second page of the primary action bar."]
			end
		end
		self.options[id] = {
			order = order,
			type = "group",
			name = name,
			desc = desc,
			childGroups = "tab",
		}
	end
	self.options[id].args = options

	-- register options in the BT GUI
	Bartender4:RegisterActionBarOptions(id, self.options[id])
end
