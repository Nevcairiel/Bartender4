--[[
	Copyright (c) 2009-2026, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved, otherwise.
]]
local _, Bartender4 = ...
-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local PresetsMod = Bartender4:NewModule("Presets")
local ActionBarsMod = Bartender4:GetModule("ActionBars")

PresetsMod.showStatusBar = true

function PresetsMod:ToggleModule(info, val)
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

local function BuildSingleProfile()
	local dy, config
	dy = 0
	if not PresetsMod.showStatusBar then
		dy = dy - 8
	end

	local actionButtonScale = 0.8

	Bartender4.db.profile.blizzardVehicle = false
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 6 / actionButtonScale
	config.actionbars[1].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[1], "BOTTOM", -254, 41 )
	config.actionbars[2].position.scale = actionButtonScale
	config.actionbars[2].enabled = false
	config.actionbars[3].padding = 5 / actionButtonScale
	config.actionbars[3].rows = 12
	config.actionbars[3].flyoutDirection = "LEFT"
	config.actionbars[3].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[3], "BOTTOMRIGHT", -42, 610 )
	config.actionbars[4].padding = 5 / actionButtonScale
	config.actionbars[4].rows = 12
	config.actionbars[4].flyoutDirection = "LEFT"
	config.actionbars[4].position.scale = actionButtonScale
	config.actionbars[5].position.scale = actionButtonScale
	config.actionbars[6].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[4], "BOTTOMRIGHT", -82, 610 )
	SetBarLocation( config.actionbars[5], "BOTTOM", -232, 102 + dy )
	SetBarLocation( config.actionbars[6], "BOTTOM", -232, 140 + dy )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.enabled = false
	Bartender4:GetModule("BagBar"):Disable()
	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.enabled = false
	Bartender4:GetModule("MicroMenu"):Disable()
	config = Bartender4.db:GetNamespace("StanceBar").profile
	config.enabled = false
	Bartender4:GetModule("StanceBar"):Disable()

	config = Bartender4.db:GetNamespace("QueueStatus").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOM", 279, 108 )

	config = Bartender4.db:GetNamespace("Vehicle").profile
	SetBarLocation( config, "BOTTOM", -302, 125 )

	if PresetsMod.showStatusBar then
		config = Bartender4.db:GetNamespace("StatusTrackingBar").profile
		config.enabled = true
		config.scale = 1.0
		config.width = 516
		Bartender4:GetModule("StatusTrackingBar"):Enable()
		SetBarLocation( config, "BOTTOM", -262, 68)
	end

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	config.artLayout = "ONEBAR"
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -256, 47 )

	config = Bartender4.db:GetNamespace("PetBar").profile
	SetBarLocation( config, "BOTTOM", -164, 169 + dy )
end

local function BuildDoubleProfile()
	local dy, config
	dy = 0

	if not PresetsMod.showStatusBar then
		dy = dy - 20
	end

	local actionButtonScale = 0.8

	Bartender4.db.profile.blizzardVehicle = true
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 6 / actionButtonScale
	config.actionbars[1].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[1], "BOTTOM", -508, 41 )
	config.actionbars[2].padding = 6 / actionButtonScale
	config.actionbars[2].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[2], "BOTTOM", 4, 41 )
	config.actionbars[3].padding = 5 / actionButtonScale
	config.actionbars[3].rows = 12
	config.actionbars[3].flyoutDirection = "LEFT"
	config.actionbars[3].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[3], "BOTTOMRIGHT", -42, 610 )
	config.actionbars[4].padding = 5 / actionButtonScale
	config.actionbars[4].rows = 12
	config.actionbars[4].flyoutDirection = "LEFT"
	config.actionbars[4].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[4], "BOTTOMRIGHT", -82, 610 )
	config.actionbars[5].padding = 6 / actionButtonScale
	config.actionbars[5].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[5], "BOTTOM", 4, 106 + dy )
	config.actionbars[6].padding = 6 / actionButtonScale
	config.actionbars[6].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[6], "BOTTOM", -508, 106 + dy )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.enabled = false
	Bartender4:GetModule("BagBar"):Disable()

	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.enabled = false
	Bartender4:GetModule("MicroMenu"):Disable()

	config = Bartender4.db:GetNamespace("QueueStatus").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOM", 513, 105 )

	config = Bartender4.db:GetNamespace("Vehicle").profile
	SetBarLocation( config, "BOTTOMLEFT", 530, 163 )

	if PresetsMod.showStatusBar then
		config = Bartender4.db:GetNamespace("StatusTrackingBar").profile
		config.enabled = true
		config.scale = 1
		config.width = 1032
		Bartender4:GetModule("StatusTrackingBar"):Enable()
		SetBarLocation( config, "BOTTOM", -520, 68)
	end

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	config.artLayout = "TWOBAR"
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -512, 47 )

	config = Bartender4.db:GetNamespace("PetBar").profile
	if GetNumShapeshiftForms() > 0 then
		SetBarLocation( config, "BOTTOM", -120, 139 + dy )
		config = Bartender4.db:GetNamespace("StanceBar").profile
		config.position.scale = 1.0
		SetBarLocation( config, "BOTTOM", -460, 139 + dy )
	else
		SetBarLocation( config, "BOTTOM", -460, 139 + dy )
	end
end

local function BuildClassicBlizzardProfile()
	local dy, config
	dy = 0

	if not PresetsMod.showStatusBar then
		dy = dy - 16
	end

	local actionButtonScale = 0.8

	Bartender4.db.profile.blizzardVehicle = true
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 6 / actionButtonScale
	config.actionbars[1].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[1], "BOTTOM", -509, 41 )
	config.actionbars[2].enabled = false
	config.actionbars[2].position.scale = actionButtonScale
	config.actionbars[3].padding = 5 / actionButtonScale
	config.actionbars[3].rows = 12
	config.actionbars[3].flyoutDirection = "LEFT"
	config.actionbars[3].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[3], "BOTTOMRIGHT", -82, 610 )
	config.actionbars[4].padding = 5 / actionButtonScale
	config.actionbars[4].rows = 12
	config.actionbars[4].flyoutDirection = "LEFT"
	config.actionbars[4].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[4], "BOTTOMRIGHT", -42, 610 )
	config.actionbars[5].padding = 6 / actionButtonScale
	config.actionbars[5].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[5], "BOTTOM", 3, 106 + dy )
	config.actionbars[6].padding = 6 / actionButtonScale
	config.actionbars[6].position.scale = actionButtonScale
	SetBarLocation( config.actionbars[6], "BOTTOM", -510, 106 + dy )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.onebag = false
	config.keyring = false
	config.position.scale =  0.6
	config.padding = 0
	SetBarLocation( config, "BOTTOM", 344, 35 )

	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.position.scale =  1
	config.padding = 3
	SetBarLocation( config, "BOTTOM", 33, 42 )

	config = Bartender4.db:GetNamespace("QueueStatus").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOM", 513, 105 )

	config = Bartender4.db:GetNamespace("Vehicle").profile
	SetBarLocation( config, "BOTTOMLEFT", 530, 163 )

	if PresetsMod.showStatusBar then
		config = Bartender4.db:GetNamespace("StatusTrackingBar").profile
		config.enabled = true
		config.scale = 1
		config.width = 1032
		Bartender4:GetModule("StatusTrackingBar"):Enable()
		SetBarLocation( config, "BOTTOM", -520, 68)
	end

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -512, 47 )

	config = Bartender4.db:GetNamespace("PetBar").profile
	if GetNumShapeshiftForms() > 0 then
		SetBarLocation( config, "BOTTOM", -120, 139 + dy )
		if GetNumShapeshiftForms() > 0 then
			config = Bartender4.db:GetNamespace("StanceBar").profile
			config.position.scale = 1.0
			SetBarLocation( config, "BOTTOM", -460, 139 + dy )
		end
	else
		SetBarLocation( config, "BOTTOM", -460, 139 + dy )
	end
end

local function BuildBlizzardProfile()
	local config

	local dy = 0
	if PresetsMod.showStatusBar then
		dy = dy + 20
	end

	Bartender4.db.profile.blizzardVehicle = true
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 2
	config.actionbars[1].showgrid = true
	SetBarLocation( config.actionbars[1], "BOTTOM", -285, 61 + dy )
	config.actionbars[2].enabled = false
	config.actionbars[3].padding = 2
	config.actionbars[3].rows = 12
	config.actionbars[3].flyoutDirection = "LEFT"
	SetBarLocation( config.actionbars[3], "RIGHT", -54, 193 )
	config.actionbars[4].padding = 2
	config.actionbars[4].rows = 12
	config.actionbars[4].flyoutDirection = "LEFT"
	SetBarLocation( config.actionbars[4], "RIGHT", -104, 193 )
	config.actionbars[5].enabled = PresetsMod.threeStackedBars
	config.actionbars[5].padding = 2
	SetBarLocation( config.actionbars[5], "BOTTOM", -285, 164 + dy )
	config.actionbars[6].padding = 2
	SetBarLocation( config.actionbars[6], "BOTTOM", -285, 113 + dy )

	if PresetsMod.showStatusBar then
		config = Bartender4.db:GetNamespace("StatusTrackingBar").profile
		config.enabled = true
		config.position.scale = 0.9
		config.width = 800
		Bartender4:GetModule("StatusTrackingBar"):Enable()
		SetBarLocation( config, "BOTTOM", -386, 29)
	end

	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.position.scale = 1.1
	config.padding = 2
	SetBarLocation( config, "BOTTOMRIGHT", -325, 47 )

	config = Bartender4.db:GetNamespace("QueueStatus").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOMRIGHT", -365, 42 )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.onebag = false
	SetBarLocation( config, "BOTTOMRIGHT", -321, 93 )

	config = Bartender4.db:GetNamespace("Vehicle").profile
	SetBarLocation( config, "BOTTOM", -337, 153 )

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	config.artLayout = "MODERN"
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -288.5, 67 + dy )

	if PresetsMod.threeStackedBars then
		dy = dy + 51
	end

	config = Bartender4.db:GetNamespace("PetBar").profile
	if GetNumShapeshiftForms() > 0 then
		config.padding = 2
		SetBarLocation( config, "BOTTOM", -41, 148 + dy )
		if GetNumShapeshiftForms() > 0 then
			config = Bartender4.db:GetNamespace("StanceBar").profile
			config.position.scale = 1.0
			config.padding = 2
			SetBarLocation( config, "BOTTOM", -285, 148 + dy )
		end
	else
		SetBarLocation( config, "BOTTOM", -285, 148 + dy )
	end
end

local function BuildModernArtClassicProfile()
	local config
	local dy = 0

	if not PresetsMod.showStatusBar then
		dy = dy - 16
	end

	Bartender4.db.profile.blizzardVehicle = true
	Bartender4.db.profile.outofrange = "hotkey"
	Bartender4.db.profile.focuscastmodifier = false

	config = Bartender4.db:GetNamespace("ActionBars").profile
	config.actionbars[1].padding = 1.9
	config.actionbars[1].position.scale = 1
	SetBarLocation( config.actionbars[1], "BOTTOM", -595.5, 51 )
	config.actionbars[2].enabled = false
	config.actionbars[2].position.scale = 1
	config.actionbars[3].padding = 2
	config.actionbars[3].rows = 12
	config.actionbars[3].position.scale = 1
	config.actionbars[3].flyoutDirection = "LEFT"
	SetBarLocation( config.actionbars[3], "RIGHT", -96, 200 )
	config.actionbars[4].padding = 2
	config.actionbars[4].rows = 12
	config.actionbars[4].position.scale = 1
	config.actionbars[4].flyoutDirection = "LEFT"
	SetBarLocation( config.actionbars[4], "RIGHT", -49, 200 )
	config.actionbars[5].padding = 2
	config.actionbars[5].position.scale = 1
	SetBarLocation( config.actionbars[5], "BOTTOM", 4, 118 + dy )
	config.actionbars[6].padding = 2
	config.actionbars[6].position.scale = 1
	SetBarLocation( config.actionbars[6], "BOTTOM", -570, 118 + dy )

	config = Bartender4.db:GetNamespace("BagBar").profile
	config.position.scale = 1
	config.padding = 0
	config.onebag = false
	SetBarLocation( config, "BOTTOM", 285, 50 )

	config = Bartender4.db:GetNamespace("MicroMenu").profile
	config.position.scale = 1
	config.padding = 3
	SetBarLocation( config, "BOTTOM", -24, 48 )

	config = Bartender4.db:GetNamespace("QueueStatus").profile
	config.position.scale = 1.0
	SetBarLocation( config, "BOTTOM", 640, 100 )

	config = Bartender4.db:GetNamespace("Vehicle").profile
	SetBarLocation( config, "BOTTOM", -676, 158 )

	if PresetsMod.showStatusBar then
		config = Bartender4.db:GetNamespace("StatusTrackingBar").profile
		config.enabled = true
		config.scale = 1
		config.width = 1192
		Bartender4:GetModule("StatusTrackingBar"):Enable()
		SetBarLocation( config, "BOTTOM", -601, 82)
	end

	config = Bartender4.db:GetNamespace("BlizzardArt").profile
	config.enabled = true
	config.artLayout = "MODERNARTCLASSIC"
	config.position.scale = 1
	Bartender4:GetModule("BlizzardArt"):Enable()
	SetBarLocation( config, "BOTTOM", -600, 57 )

	config = Bartender4.db:GetNamespace("PetBar").profile
	if GetNumShapeshiftForms() > 0 then
		SetBarLocation( config, "BOTTOM", -251, 150 + dy )
		if GetNumShapeshiftForms() > 0 then
			config = Bartender4.db:GetNamespace("StanceBar").profile
			config.position.scale = 1
			SetBarLocation( config, "BOTTOM", -529, 150 + dy )
		end
	else
		SetBarLocation( config, "BOTTOM", -529, 150 + dy )
	end
end

local function UpdateGlobalProfileSettings()
	-- flag ActionBars as WoW10 Layout
	local config = Bartender4.db:GetNamespace("ActionBars").profile
	for _, i in ipairs(ActionBarsMod.LIST_ACTIONBARS) do
		config.actionbars[i].WoW10Layout = true
	end
end

function PresetsMod:ResetProfile(type)
	if not type then type = PresetsMod.defaultType end
	Bartender4.db:ResetProfile()

	-- some global settings
	UpdateGlobalProfileSettings()

	-- load the preset
	if type == "BLIZZARD" then
		BuildBlizzardProfile()
	elseif type == "MODERN_ART_CLASSIC" or type == "DEFAULT" then
		BuildModernArtClassicProfile()
	elseif type == "CLASSIC" then
		BuildClassicBlizzardProfile()
	elseif type == "DOUBLE_CLASSIC" then
		BuildDoubleProfile()
	elseif type == "SINGLE_CLASSIC" then
		BuildSingleProfile()
	end

	-- Update everything
	Bartender4:UpdateModuleConfigs()
end

function PresetsMod:OnEnable()
	Bartender4.finishedLoading = true
	if self.applyBlizzardOnEnable then
		self:ResetProfile("DEFAULT")
		self.applyBlizzardOnEnable = nil
	end
end

function PresetsMod:SetupOptions()
	if not self.options then
		PresetsMod.defaultType = "MODERN_ART_CLASSIC"
		self.showStatusBar = true
		self.threeStackedBars = false
		local otbl = {
			message1 = {
				order = 1,
				type = "description",
				name = L["You can use the preset defaults as a starting point for setting up your interface. Just choose your preferences here and click the button below to reset your profile to the preset default. Note that not all defaults show all bars."]
			},
			message2 = {
				order = 2,
				type = "description",
				name = L["|cffff0000WARNING|cffffffff: Pressing the button will reset your complete profile! If you're not sure about this, create a new profile and use that to experiment."],
			},
			preset = {
				order = 10,
				type = "select",
				width = "double",
				name = L["Presets"],
				values = { BLIZZARD = L["Modern Blizzard interface"], MODERN_ART_CLASSIC = L["Modern Art, Classic interface"], CLASSIC = L["Classic interface"], DOUBLE_CLASSIC = L["Two bars wide (Classic)"], SINGLE_CLASSIC = L["Three bars stacked (Classic)"], ZRESET = L["Full reset"] },
				sorting = { "MODERN_ART_CLASSIC", "BLIZZARD", "CLASSIC", "DOUBLE_CLASSIC", "SINGLE_CLASSIC", "ZRESET" },
				get = function() return PresetsMod.defaultType end,
				set = function(info, val) PresetsMod.defaultType = val end
			},
			nl1 = {
				order = 11,
				type = "description",
				name = ""
			},
			thirdbar = {
				order = 15,
				type = "toggle",
				width = "full",
				name = L["Use three stacked action bars"],
				get = function() return PresetsMod.threeStackedBars end,
				set = function(info, val) PresetsMod.threeStackedBars = val end,
				hidden = function() return PresetsMod.defaultType ~= "BLIZZARD" end,
			},
			nl12 = {
				order = 16,
				type = "description",
				name = ""
			},
			statusbar = {
				order = 20,
				type = "toggle",
				width = "full",
				name = L["Status Tracking Bar (XP/Rep/...)"],
				get = function() return PresetsMod.showStatusBar end,
				set = function(info, val) PresetsMod.showStatusBar = val end,
				disabled = function() return PresetsMod.defaultType == "ZRESET" end,
			},
			nl2 = {
				order = 36,
				type = "description",
				name = ""
			},
			button = {
				order = 40,
				type = "execute",
				name = L["Apply Preset"],
				func = function() PresetsMod:ResetProfile() end,
			}
		}
		self.optionobject = Bartender4:NewOptionObject( otbl )
		self.options = {
			order = 99,
			type = "group",
			name = L["Presets"],
			desc = L["Configure all of Bartender to preset defaults"],
			childGroups = "tab",
		}
		Bartender4:RegisterModuleOptions("Presets", self.options)
	end
	self.options.args = self.optionobject.table
end
