--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

if not ExtraAbilityContainer then return end

-- register module
local ExtraActionBarMod = Bartender4:NewModule("ExtraActionBar", "AceHook-3.0")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

local setmetatable, table_insert = setmetatable, table.insert

-- create prototype information
local ExtraActionBar = setmetatable({}, {__index = Bar})

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
	hideArtwork = false,
	visibility = {
		vehicleui = false,
		overridebar = false,
	},
}, Bartender4.Bar.defaults) }

function ExtraActionBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ExtraActionBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function ExtraActionBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("ExtraActionBar", self.db.profile, L["Extra Action Bar"], 2), {__index = ExtraActionBar})
		self.bar.content = ExtraAbilityContainer

		-- remove EditMode hooks
		self.bar.content.ClearAllPoints = nil
		self.bar.content.SetPoint = nil
		self.bar.content.SetScale = nil

		self.bar.content:SetToplevel(false)
		self.bar.content:SetParent(self.bar)
		self.bar.content:SetScript("OnShow", nil)
		self.bar.content:SetScript("OnHide", nil)
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	self:SecureHook("ExtraActionBar_Update")
	self:SecureHook(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities")
	if ExtraAbilityContainer.ApplySystemAnchor then
		self:SecureHook(ExtraAbilityContainer, "ApplySystemAnchor")
		self:SecureHook(ExtraAbilityContainer, "HighlightSystem")
	end

	if UIParentBottomManagedFrameContainer then
		UIParentBottomManagedFrameContainer.showingFrames[ExtraAbilityContainer] = nil
	end
end

function ExtraActionBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
	self:UpdateArtwork()
end

function ExtraActionBarMod:UpdateArtwork()
	self:ExtraActionBar_Update()
	self:UpdateDisplayedZoneAbilities()
end

function ExtraActionBarMod:ExtraActionBar_Update()
	if HasExtraActionBar() then
		ExtraActionBarFrame.button.style:SetShown(not self.db.profile.hideArtwork)
	end
end

function ExtraActionBarMod:UpdateDisplayedZoneAbilities()
	ZoneAbilityFrame.Style:SetShown(not self.db.profile.hideArtwork)
end

function ExtraActionBarMod:HighlightSystem()
	ExtraAbilityContainer.Selection:Hide()
	EditModeMagnetismManager:UnregisterFrame(ExtraAbilityContainer)
end

function ExtraActionBarMod:ApplySystemAnchor()
	if UIParentBottomManagedFrameContainer then
		UIParentBottomManagedFrameContainer.showingFrames[ExtraAbilityContainer] = nil
	end

	self.bar:PerformLayout()
end

ExtraActionBar.width = 128
ExtraActionBar.height = 128

function ExtraActionBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("BOTTOM", 0, 160)
		self:SavePosition()
	end

	self:PerformLayout()
end

function ExtraActionBar:PerformLayout()
	self:SetSize(128, 128)
	local bar = self.content
	bar:SetParent(self)
	bar:ClearAllPoints()
	bar:SetPoint("CENTER", self, "TOPLEFT", 64, -64)
end
