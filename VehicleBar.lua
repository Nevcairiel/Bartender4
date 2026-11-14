--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- register module
local VehicleBarMod = Bartender4:NewModule("Vehicle")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

local table_insert, setmetatable, pairs = table.insert, setmetatable, pairs

-- GLOBALS: CanExitVehicle, UnitOnTaxi, VehicleExit, TaxiRequestEarlyLanding, GameTooltip

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

local function ShouldVehicleButtonBeShown()
	if not CanExitVehicle then
		return UnitOnTaxi("player")
	else
		return CanExitVehicle()
	end
end

local function VehicleButton_Update(self)
	if ShouldVehicleButtonBeShown() then
		self:Show()
		self:Enable()
	else
		self:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
		self:UnlockHighlight()
		self:Hide()
	end
end

local function VehicleButton_OnClick(self)
	if UnitOnTaxi("player") then
		TaxiRequestEarlyLanding()

		-- Show that the request for landing has been received.
		self:Disable()
		self:SetHighlightTexture([[Interface\Buttons\CheckButtonHilight]], "ADD")
		self:LockHighlight()
	else
		VehicleExit()
	end
end

local function VehicleButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if UnitOnTaxi("player") then
		GameTooltip_SetTitle(GameTooltip, TAXI_CANCEL)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	else
		GameTooltip_SetTitle(GameTooltip, LEAVE_VEHICLE)
	end
	GameTooltip:Show()
end

-- We use our own button instead of MainMenuBarVehicleLeaveButton. The Blizzard button is positioned
-- by EditMode, potentially in combat, at which point we would be unable to move it back onto our bar.
-- The Blizzard button is left untouched, and remains hidden as a child of the hidden main action bar.
local function CreateVehicleButton(parent)
	local button = CreateFrame("Button", "BT4VehicleLeaveButton", parent)
	button:SetSize(32, 32)
	button:SetMotionScriptsWhileDisabled(true)
	button:Hide()

	button:SetNormalTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
	button:GetNormalTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
	button:SetPushedTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]])
	button:GetPushedTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

	button:SetScript("OnEvent", VehicleButton_Update)
	button:SetScript("OnClick", VehicleButton_OnClick)
	button:SetScript("OnEnter", VehicleButton_OnEnter)
	button:SetScript("OnLeave", GameTooltip_Hide)

	button:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	button:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
	button:RegisterEvent("UNIT_ENTERED_VEHICLE")
	button:RegisterEvent("UNIT_EXITED_VEHICLE")
	button:RegisterEvent("VEHICLE_UPDATE")

	return button
end

function VehicleBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("Vehicle", self.db.profile, L["Vehicle Bar"]), {__index = VehicleBar})
		self.bar.content = CreateVehicleButton(self.bar)
	end

	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	VehicleButton_Update(self.bar.content)
end

function VehicleBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
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
