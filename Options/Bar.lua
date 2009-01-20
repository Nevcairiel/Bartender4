local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

--[[===================================================================================
	Bar Options
===================================================================================]]--

local barregistry = Bartender4.Bar.barregistry

-- option utilty functions
local optGetter, optSetter, visibilityGetter, visibilitySetter, customEnabled, customDisabled, customCopy, clickThroughVis
do
	local getBar, optionMap, callFunc
	-- maps option keys to function names
	optionMap = {
		alpha = "ConfigAlpha",
		scale = "ConfigScale",
		fadeout = "FadeOut",
		fadeoutalpha = "FadeOutAlpha",
		fadeoutdelay = "FadeOutDelay",
		clickthrough = "ClickThrough",
	}
	
	-- retrieves a valid bar object from the barregistry table
	function getBar(id)
		local bar = barregistry[tostring(id)]
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
	
	function visibilityGetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		return bar:GetVisibilityOption(option, ...)
	end
	
	function visibilitySetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		bar:SetVisibilityOption(option, ...)
	end
	
	function customEnabled(info)
		local bar = getBar(info[2])
		return bar:GetVisibilityOption("custom")
	end
	
	function customDisabled(info)
		local bar = getBar(info[2])
		return not bar:GetVisibilityOption("custom")
	end
	
	function customCopy(info)
		local bar = getBar(info[2])
		bar:CopyCustomConditionals()
	end
	
	function clickThroughVis(info)
		local bar = getBar(info[2])
		return (not bar.ClickThroughSupport)
	end
end

local _, class = UnitClass("player")

local function getStanceTable()
	local num = GetNumShapeshiftForms()
	
	local tbl = {}
	for i = 1, num do
		tbl[i] = select(2, GetShapeshiftFormInfo(i))
	end
	-- HACK: Metamorphosis work around, it is on slot 1 in GetShapeshiftFormInfo() but stance:2 is active..
	if class == "WARLOCK" and tbl[1] == GetSpellInfo(59672) then
		tbl[2], tbl[1] = tbl[1], nil
	end
	return tbl
end

local options
function Bar:GetOptionObject()
	local otbl = {
		general = {
			type = "group",
			cmdInline = true,
			name = L["General Settings"],
			order = 1,
			args = {
				styleheader = {
					order = 10,
					type = "header",
					name = L["Bar Style & Layout"],
				},
				alpha = {
					order = 20,
					name = L["Alpha"],
					desc = L["Configure the alpha of the bar."],
					type = "range",
					min = .1, max = 1, bigStep = 0.1,
					get = optGetter,
					set = optSetter,
				},
				scale = {
					order = 30,
					name = L["Scale"],
					desc = L["Configure the scale of the bar."],
					type = "range",
					min = .1, max = 2, step = 0.05,
					get = optGetter,
					set = optSetter,
				},
				clickthrough = {
					order = 200,
					name = L["Click-Through"],
					desc = L["Disable any reaction to mouse events on this bar, making the bar click-through."],
					type = "toggle",
					get = optGetter,
					set = optSetter,
					hidden = clickThroughVis,
					width = "full",
				},
			},
		},
		visibility = {
			type = "group",
			name = L["Visibility"],
			order = 2,
			get = visibilityGetter,
			set = visibilitySetter,
			args = {
				info = {
					order = 1,
					type = "description",
					name = L["The bar default is to be visible all the time, you can configure conditions here to control when the bar should be hidden."] .. "\n",
				},
				fadeout = {
					order = 5,
					name = L["Fade Out"],
					desc = L["Enable the FadeOut mode"],
					type = "toggle",
					get = optGetter,
					set = optSetter,
					width = "full",
				},
				fadeoutalpha = {
					order = 6,
					name = L["Fade Out Alpha"],
--					desc = L["Enable the FadeOut mode"],
					desc = L["Configure the Fade Out Alpha"],
					type = "range",
					min = 0, max = 1, step = 0.05,
					get = optGetter,
					set = optSetter,
				},
				fadeoutdelay = {
					order = 7,
					name = L["Fade Out Delay"],
--					desc = L["Enable the FadeOut mode"],
					desc = L["Configure the Fade Out Delay"],
					type = "range",
					min = 0, max = 1, step = 0.01,
					get = optGetter,
					set = optSetter,
				},
				fadeNl = {
					order = 8,
					type = "description",
					name = "",
				},
				always = {
					order = 10,
					type = "toggle",
					name = L["Always Hide"],
					desc = L["You can set the bar to be always hidden, if you only wish to access it using key-bindings."],
					width = "full",
					disabled = customEnabled,
				},
				possess = {
					order = 15,
					type = "toggle",
					name = L["Hide when Possessing"],
					desc = L["Hide this bar when you are possessing a NPC."],
					disabled = customEnabled,
				},
				vehicle = {
					order = 16,
					type = "toggle",
					name = L["Hide on Vehicle"],
					desc = L["Hide this bar when you are riding on a vehicle."],
					disabled = customEnabled,
				},
				combat = {
					order = 20,
					type = "toggle",
					name = L["Hide in Combat"],
					desc = L["This bar will be hidden once you enter combat."],
					disabled = customEnabled,
				},
				nocombat = {
					order = 21,
					type = "toggle",
					name = L["Hide out of Combat"],
					desc = L["This bar will be hidden whenever you are not in combat."],
					disabled = customEnabled,
				},
				pet = {
					order = 30,
					type = "toggle",
					name = L["Hide with pet"],
					desc = L["Hide this bar when you have a pet."],
					disabled = customEnabled,
				},
				nopet = {
					order = 31,
					type = "toggle",
					name = L["Hide without pet"],
					desc = L["Hide this bar when you have no pet."],
					disabled = customEnabled,
				},
				stance = {
					order = 50,
					type = "multiselect",
					name = L["Hide in Stance/Form"],
					desc = L["Hide this bar in a specific Stance or Form."],
					values = getStanceTable,
					hidden = function() return (GetNumShapeshiftForms() < 1) end,
					disabled = customEnabled,
				},
				customNl = {
					order = 98,
					type = "description",
					name = "\n",
				},
				customHeader = {
					order = 99,
					type = "header",
					name = L["Custom Conditionals"],
				},
				custom = {
					order = 100,
					type = "toggle",
					name = L["Use Custom Condition"],
					desc = L["Enable the use of a custom condition, disabling all of the above."],
				},
				customCopy = {
					order = 101,
					type = "execute",
					name = L["Copy Conditionals"],
					desc = L["Create a copy of the auto-generated conditionals in the custom configuration as a base template."],
					func = customCopy,
				},
				customDesc = {
					order = 102,
					type = "description",
					name = L["Note: Enabling Custom Conditionals will disable all of the above settings!"],
				},
				customdata = {
					order = 103,
					type = "input",
					name = L["Custom Conditionals"],
					desc = L["You can use any macro conditionals in the custom string, using \"show\" and \"hide\" as values.\n\nExample: [combat]hide;show"],
					width = "full",
					multiline = true,
					disabled = customDisabled,
				},
			},
		},
		align = {
			type = "group",
			cmdInline = true,
			name = L["Alignment"],
			order = 20,
			args = {
				info = {
					order = 1,
					type = "description",
					name = L["The Alignment menu is still on the TODO.\n\nAs a quick preview of whats planned:\n\n\t- Absolute and relative Bar Positioning\n\t- Bars \"snapping\" together and building clusters"],
				},
			},
		}
	}
	return Bartender4:NewOptionObject(otbl)
end
