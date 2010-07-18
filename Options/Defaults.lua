--[[
Copyright (c) 2009, CMTitan
All rights to be transferred to Nevcairiel upon inclusion into Bartender4.
All rights reserved, otherwise.
]]
-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

local DefaultsMod = Bartender4:NewModule("Defaults")

function DefaultsMod:ToggleModule(info, val)
	-- We are always enabled. Period.
	if not self:IsEnabled() then
		self:Enabled()
	end
end

local function SetBarLocation(config, point, x, y)
	config.position.point = point
	config.position.x = x
	config.position.y = y
end

local function BuildBlizzardProfile()
	local dy, config
	dy = 0
	if not DefaultsMod.showRepBar then
		dy = dy - 8
	end
	if not DefaultsMod.showXPBar then
		dy = dy - 11
	end

	Bartender4.db.profile.blizzardVehicle = true
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 6
	SetBarLocation( config.actionbars[1], "BOTTOM", -510, 41.75 )
	config.actionbars[2].enabled = false
	config.actionbars[3].padding = 5
	config.actionbars[3].rows = 12
	SetBarLocation( config.actionbars[3], "BOTTOMRIGHT", -82, 610 )
	config.actionbars[4].padding = 5
	config.actionbars[4].rows = 12
	SetBarLocation( config.actionbars[4], "BOTTOMRIGHT", -42, 610 )
	config.actionbars[5].padding = 6
	SetBarLocation( config.actionbars[5], "BOTTOM", 3, 102 + dy )
	config.actionbars[6].padding = 6
	SetBarLocation( config.actionbars[6], "BOTTOM", -510, 102 + dy )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.onebag = true
	SetBarLocation( config, "BOTTOM", 463.5, 41.75 )

	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOM", 37.5, 41.75 )

	if DefaultsMod.showRepBar then
		config = Bartender4.db:GetNamespace("RepBar").profile
		config.enabled = true
		Bartender4:GetModule("RepBar"):Enable()
		SetBarLocation( config, "BOTTOM", -516, 65 + dy ) -- Note that dy is actually correct since it's only incorrect for the RepBar if the RepBar itself does not exist
	end

	if DefaultsMod.showXPBar then
		config = Bartender4.db:GetNamespace("XPBar").profile
		config.enabled = true
		Bartender4:GetModule("XPBar"):Enable()
		SetBarLocation( config, "BOTTOM", -516, 57 )
	end

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -512, 47 )

	config = Bartender4.db:GetNamespace("PetBar").profile
	if GetNumShapeshiftForms() > 0 then
		SetBarLocation( config, "BOTTOM", -120, 135 + dy )
		config = Bartender4.db:GetNamespace("StanceBar").profile
		config.position.scale = 1.0
		SetBarLocation( config, "BOTTOM", -460, 135 + dy )
	else
		SetBarLocation( config, "BOTTOM", -460, 135 + dy )
	end
end

local function ResetProfile()
	if DefaultsMod.defaultType == "BLIZZARD" then
		Bartender4.db:ResetProfile()
		BuildBlizzardProfile()
	else
		Bartender4.db:ResetProfile()
	end
	Bartender4:UpdateModuleConfigs()
end

function DefaultsMod:SetupOptions()
	if not self.options then
		DefaultsMod.defaultType = "BLIZZARD"
		self.showXPBar = true
		self.showRepBar = true
		local otbl = {
			message1 = {
				order = 1,
				type = "description",
				name = L["You can use the preset defaults as a starting point for setting up your interface. Just choose your preferences here and click the button below to reset your profile to the preset default."]
			},
			message2 = {
				order = 2,
				type = "description",
				name = L["WARNING: Pressing the button will reset your complete profile! If you're not sure about this create a new profile and use that to experiment."],
			},
			preset = {
				order = 10,
				type = "select",
				name = L["Defaults"],
				values = { BLIZZARD = L["Blizzard interface"], RESET = L["Full reset"] },
				get = function() return DefaultsMod.defaultType end,
				set = function(info, val) DefaultsMod.defaultType = val end
			},
			nl1 = {
				order = 11,
				type = "description",
				name = ""
			},
			xpbar = {
				order = 20,
				type = "toggle",
				name = L["Show XP Bar"],
				get = function() return DefaultsMod.showXPBar end,
				set = function(info, val) DefaultsMod.showXPBar = val end,
				disabled = function() return DefaultsMod.defaultType == "RESET" end
			},
			nl2  = {
					order = 21,
					type = "description",
					name = ""
			},
			repbar = {
				order = 30,
				type = "toggle",
				name = L["Show Reputation Bar"],
				get = function() return DefaultsMod.showRepBar end,
				set = function(info, val) DefaultsMod.showRepBar = val end,
				disabled = function() return DefaultsMod.defaultType == "RESET" end
			},
			nl3 = {
				order = 31,
				type = "description",
				name = ""
			},
			button = {
				order = 40,
				type = "execute",
				name = L["Reset profile"],
				func = ResetProfile
			}
		}
		self.optionobject = Bartender4:NewOptionObject( otbl )
		self.options = {
			order = 200,
			type = "group",
			name = L["Defaults"],
			desc = L["Configure all of Bartender to preset defaults"],
			childGroups = "tab",
		}
		Bartender4:RegisterModuleOptions("Defaults", self.options)
	end
	self.options.args = self.optionobject.table
end
