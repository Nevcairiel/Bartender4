--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local WoWClassic = select(4, GetBuildInfo()) < 20000

-- register module
local VehicleBarMod = Bartender4:NewModule("Vehicle", "AceHook-3.0")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

local table_insert, setmetatable, pairs = table.insert, setmetatable, pairs

-- GLOBALS: MainMenuBarVehicleLeaveButton, CanExitVehicle

-- create prototype information
local VehicleBar = setmetatable({}, {__index = Bar})

local defaults = { profile = Bartender4:Merge({
	enabled = true,
	visibility = {
		vehicleui = false,
		overridebar = false,
	},
}, Bartender4.Bar.defaults) }

function VehicleBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("Vehicle", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function VehicleBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("Vehicle", self.db.profile, L["Vehicle Bar"], true), {__index = VehicleBar})
		self.bar.content =  MainMenuBarVehicleLeaveButton
		self.bar.content:SetParent(self.bar)
		self.bar.content.ClearSetPoint = self.bar.ClearSetPoint
	end
	self:SecureHook("MainMenuBarVehicleLeaveButton_Update")
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function VehicleBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function VehicleBarMod:MainMenuBarVehicleLeaveButton_Update()
	if WoWClassic then
		if UnitOnTaxi("player") then
			MainMenuBarVehicleLeaveButton:Show()
		end
	else
		if CanExitVehicle() then
			MainMenuBarVehicleLeaveButton:Show()
		end
	end
	self.bar:PerformLayout()
end

function VehicleBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", 120, 27)
		self:PerformLayout()
		self:SavePosition()
	end

	self:PerformLayout()
end

function VehicleBar:PerformLayout()
	self:SetSize(32,32)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", 0, 0)
end
