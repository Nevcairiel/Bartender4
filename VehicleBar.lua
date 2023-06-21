--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- register module
local VehicleBarMod = Bartender4:NewModule("Vehicle", "AceHook-3.0")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

local table_insert, setmetatable, pairs = table.insert, setmetatable, pairs

-- GLOBALS: MainMenuBarVehicleLeaveButton, CanExitVehicle

-- create prototype information
local VehicleBar = setmetatable({}, {__index = Bar})

local defaults = { profile = Bartender4.Util:Merge({
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
		self.bar = setmetatable(Bartender4.Bar:Create("Vehicle", self.db.profile, L["Vehicle Bar"]), {__index = VehicleBar})
		self.bar.content = MainMenuBarVehicleLeaveButton

		-- remove EditMode hooks
		self.bar.content.ClearAllPoints = nil
		self.bar.content.SetPoint = nil
		self.bar.content.SetScale = nil

		self.bar.content:SetParent(self.bar)
		self.bar.content:SetScript("OnShow", nil)
		self.bar.content:SetScript("OnHide", nil)
	end
	if MainMenuBarVehicleLeaveButton_Update then
		self:RawHook("MainMenuBarVehicleLeaveButton_Update", true)
	else
		self:SecureHook(MainMenuBarVehicleLeaveButton, "Update", "MainMenuBarVehicleLeaveButton_Update")
	end

	if MainMenuBarVehicleLeaveButton.ApplySystemAnchor then
		self:SecureHook(MainMenuBarVehicleLeaveButton, "ApplySystemAnchor")
		self:SecureHook(MainMenuBarVehicleLeaveButton, "HighlightSystem")
	end

	if EditModeManagerFrame and EditModeManagerFrame.UpdateBottomActionBarPositions then
		self:SecureHook(EditModeManagerFrame, "UpdateBottomActionBarPositions", "ApplySystemAnchor")
	end

	if UIParentBottomManagedFrameContainer then
		UIParentBottomManagedFrameContainer.showingFrames[MainMenuBarVehicleLeaveButton] = nil
	end

	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function VehicleBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

local function ShouldVehicleButtonBeShown()
	if not CanExitVehicle then
		return UnitOnTaxi("player")
	else
		return CanExitVehicle()
	end
end

function VehicleBarMod:MainMenuBarVehicleLeaveButton_Update()
	if ShouldVehicleButtonBeShown() then
		self.bar:PerformLayout()
		MainMenuBarVehicleLeaveButton:Show()
		MainMenuBarVehicleLeaveButton:Enable()
	else
		MainMenuBarVehicleLeaveButton:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
		MainMenuBarVehicleLeaveButton:UnlockHighlight()
		MainMenuBarVehicleLeaveButton:Hide()
	end
end

function VehicleBarMod:ApplySystemAnchor()
	self.bar:PerformLayout()
end

function VehicleBarMod:HighlightSystem()
	MainMenuBarVehicleLeaveButton.Selection:Hide()
	EditModeMagnetismManager:UnregisterFrame(MainMenuBarVehicleLeaveButton)
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
