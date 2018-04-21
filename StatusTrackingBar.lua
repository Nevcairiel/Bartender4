--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

-- only available on 8.0
if not StatusTrackingBarManager then return end

local defaults = { profile = Bartender4:Merge({
	enabled = false,
}, Bartender4.Bar.defaults) }

-- register module
local StatusBarMod = Bartender4:NewModule("StatusTrackingBar", "AceHook-3.0")

-- create prototype information
local StatusBar = setmetatable({}, {__index = Bar})

function StatusBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StatusTrackingBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function StatusBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("Status", self.db.profile, L["Status Tracking Bar"]), {__index = StatusBar})
		self.bar.content = CreateFrame("Frame", nil, self.bar)
		self.bar.content:SetSize(804, 14)
		self.bar.content:Show()
		self.bar.content.OnStatusBarsUpdated = function() end

		self.bar.content:SetParent(self.bar)
		self.bar.content:SetFrameLevel(self.bar:GetFrameLevel() + 1)
		
		StatusTrackingBarManager:SetParent(self.bar.content)
		StatusTrackingBarManager:SetPoint("TOPLEFT", self.bar.content, "TOPLEFT", 0, 0)
		StatusTrackingBarManager:Show()
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function StatusBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function StatusBarMod:UpdateLayout()
	self.bar:PerformLayout()
end

function StatusBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

StatusBar.width = 812
StatusBar.height = 22
StatusBar.offsetX = 5
StatusBar.offsetY = 10
function StatusBar:PerformLayout()
	self:SetSize(self.width, self.height)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", self.offsetX, self.offsetY)

	StatusTrackingBarManager:SetBarSize(true)
end

StatusBar.ClickThroughSupport = false
function StatusBar:ControlClickThrough()
	--self.content:EnableMouse(not self.config.clickthrough)
end
