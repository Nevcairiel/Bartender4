--[[
	Copyright (c) 2009-2012, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
if WoWRetail or not HasMultiCastActionBar or not MultiCastActionBarFrame or select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- fetch upvalues
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
}, Bartender4.Bar.defaults) }

-- register module
local MultiCastMod = Bartender4:NewModule("MultiCast")

-- create prototype information
local MultiCastBar = setmetatable({}, {__index = Bar})

function MultiCastMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("MultiCast", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function MultiCastMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("MultiCast", self.db.profile, L["Totem Bar"]), {__index = MultiCastBar})
		self.bar.content = MultiCastActionBarFrame
		self.bar.content:SetScript("OnShow", nil)
		self.bar.content:SetScript("OnHide", nil)
		self.bar.content:SetScript("OnUpdate", nil)
		self.bar.content.ignoreFramePositionManager = true

		self.bar.content:SetParent(self.bar)
		self.bar.content:Show()
		self.bar.content:SetFrameLevel(self.bar:GetFrameLevel() + 1)
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function MultiCastMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

function MultiCastBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

function MultiCastBar:PerformLayout()
	self:SetSize(230, 40)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 1)
end
