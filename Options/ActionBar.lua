--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local StateBar = Bartender4.StateBar.prototype
local ActionBar = Bartender4.ActionBar

local lsmlist = AceGUIWidgetLSMlists

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

local optStyleSetter, optStyleGetter
do
	local optionMap, getBar, callStyleFunc
	-- maps option keys to function names
	optionMap = {
		font = "Font",
		size = "FontSize",
		flags = "FontFlags",
		color = "FontColor",
		anchor = "TextAnchor",
		offsetX = "TextOffsetX",
		offsetY = "TextOffsetY",
		justify = "TextJustifyH",
	}

	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		local bar = module.actionbars[tonumber(id)]
		assert(bar, ("Invalid bar id in options table. (%s)"):format(id))
		return bar
	end

	-- calls a style function on the bar
	function callStyleFunc(bar, element, type, option, ...)
		local func = type .. "Style" .. (optionMap[option] or option)
		assert(bar[func], ("Invalid get/set function %s in bar %s."):format(func, bar.id))
		return bar[func](bar, element, ...)
	end

	-- universal function to get a style option
	function optStyleGetter(info)
		local bar = getBar(info[2])
		local option = info[#info]
		local element = info[#info - 1]
		return callStyleFunc(bar, element, "Get", option)
	end

	-- universal function to set a style option
	function optStyleSetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		local element = info[#info - 1]
		return callStyleFunc(bar, element, "Set", option, ...)
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
		}

		local text_style = {
			font = {
				order = 11,
				type = "select",
				name = L["Font"],
				desc = L["Select the font for this text element"],
				dialogControl = "LSM30_Font",
				values = lsmlist.font,
				set = optStyleSetter,
				get = optStyleGetter,
			},
			flags = {
				order = 12,
				type = "select",
				name = L["Outline"],
				desc = L["Select the type of outline"],
				values = {["OUTLINE"] = L["Thin outline"], ["THICKOUTLINE"] = L["Thick outline"], [""] = L["None"]},
				set = optStyleSetter,
				get = optStyleGetter,
			},
			size = {
				order = 13,
				name = L["Font Size"],
				desc = L["Set the font size of this element"],
				type = "range",
				min = 8, max = 28, step = 1,
				set = optStyleSetter,
				get = optStyleGetter,
			},
			color = {
				order = 14,
				type = "color",
				name = L["Text Color"],
				desc = L["Select the color of this element"],
				set = optStyleSetter,
				get = optStyleGetter,
			},
			nl1 = {
				order = 20,
				type = "description",
				name = "",
			},
			anchor = {
				order = 21,
				type = "select",
				name = L["Anchor point"],
				desc = L["Anchor point for this text element"],
				values = {
					["TOP"] = L["Top"],
					["RIGHT"] = L["Right"],
					["BOTTOM"] = L["Bottom"],
					["LEFT"] = L["Left"],
					["TOPRIGHT"] = L["Top Right"],
					["TOPLEFT"] = L["Top Left"],
					["BOTTOMLEFT"] = L["Bottom Left"],
					["BOTTOMRIGHT"] = L["Bottom Right"],
					["CENTER"] = L["Center"]
				},
				set = optStyleSetter,
				get = optStyleGetter,
			},
			justify = {
				order = 22,
				type = "select",
				name = L["Text Alignment"],
				desc = L["Alignment of the text"],
				values = {
					["RIGHT"] = L["Right"],
					["LEFT"] = L["Left"],
					["CENTER"] = L["Center"],
				},
				set = optStyleSetter,
				get = optStyleGetter,
			},
			nl2 = {
				order = 23,
				type = "description",
				name = "",
			},
			offsetX = {
				order = 25,
				name = L["Anchor X Offset"],
				desc = L["Set X offset from the anchor point"],
				type = "range",
				min = -10, max = 10, bigStep = 1, step = 0.1,
				set = optStyleSetter,
				get = optStyleGetter,
			},
			offsetY = {
				order = 26,
				name = L["Anchor Y Offset"],
				desc = L["Set Y offset from the anchor point"],
				type = "range",
				min = -10, max = 10, bigStep = 1, step = 0.1,
				set = optStyleSetter,
				get = optStyleGetter,
			},
		}

		local style_cat = {
			type = "group",
			name = L["Text Style"],
			order = 29,
			args = {
				buttonstyleheader = {
					order = 1,
					type = "description",
					width = "full",
					name = L["These options allow you to configure the font style and size used for all textual elements of the buttons on this bar."],
				},
				hotkey = {
					order = 10,
					type = "group",
					name = L["Hotkey"],
					guiInline = true,
					args = {},
				},
				count = {
					order = 20,
					type = "group",
					name = L["Count"],
					guiInline = true,
					args = {},
				},
				macro = {
					order = 30,
					type = "group",
					name = L["Macro Text"],
					guiInline = true,
					args = {},
				},
			},
		}

		obj:AddElementGroup("general", cat_general)

		obj:NewCategory("style", style_cat)
		obj:AddElementGroup("style", text_style, "hotkey")
		obj:AddElementGroup("style", text_style, "count")
		obj:AddElementGroup("style", text_style, "macro")
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
