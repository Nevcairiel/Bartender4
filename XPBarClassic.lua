--[[
	Copyright (c) 2009-2019, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

-- only available on Classic
if not MainMenuExpBar then return end

local defaults = { profile = Bartender4:Merge({
	enabled = false,
}, Bartender4.Bar.defaults) }

-- register module
local XPBarMod = Bartender4:NewModule("XPBar", "AceHook-3.0")

-- create prototype information
local XPBar = setmetatable({}, {__index = Bar})

function XPBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("XPBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function XPBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("XP", self.db.profile, L["XP Bar"], 1), {__index = XPBar})
		self.bar.content = MainMenuExpBar
		self.bar.content:SetParent(self.bar)
		self.bar.content:SetFrameLevel(self.bar:GetFrameLevel() + 1)
	end
	self:SecureHook("MainMenuBar_UpdateExperienceBars", "UpdateLayout")
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function XPBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function XPBarMod:UpdateLayout()
	self.bar:PerformLayout()
end

function XPBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

XPBar.width = 1024
XPBar.height = 13
XPBar.offsetX = 0
XPBar.offsetY = 0
function XPBar:PerformLayout()
	self:SetSize(self.width, self.height)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", self.offsetX, self.offsetY)
end

XPBar.ClickThroughSupport = true
function XPBar:ControlClickThrough()
	self.content:EnableMouse(not self.config.clickthrough)
end

-- register module
local RepBarMod = Bartender4:NewModule("RepBar", "AceHook-3.0")

-- create prototype information
local RepBar = setmetatable({}, {__index = Bar})

function RepBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("RepBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function RepBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("Rep", self.db.profile, L["Reputation Bar"], 1), {__index = RepBar})
		self.bar.content = ReputationWatchBar
		self.bar.content:SetParent(self.bar)
		self.bar.content:SetFrameLevel(self.bar:GetFrameLevel() + 1)
	end
	self:SecureHook("MainMenuBar_UpdateExperienceBars", "UpdateLayout")
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function RepBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function RepBarMod:UpdateLayout()
	self.bar:PerformLayout()
end

function RepBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

RepBar.width = 1024
RepBar.height = 11
RepBar.offsetX = 0
RepBar.offsetY = 0
function RepBar:PerformLayout()
	self:SetSize(self.width, self.height)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", self.offsetX, self.offsetY)
end

RepBar.ClickThroughSupport = true
function RepBar:ControlClickThrough()
	self.content:EnableMouse(not self.config.clickthrough)
end
