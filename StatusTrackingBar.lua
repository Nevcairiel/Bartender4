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

local defaults = { profile = Bartender4.Util:Merge({
	enabled = false,
	width = 571,
	twentySections = true,
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
		self.bar = setmetatable(Bartender4.Bar:Create("Status", self.db.profile, L["Status Tracking Bar"], 1), {__index = StatusBar})
		self.bar.content = CreateFrame("Frame", nil, self.bar)
		self.bar.content:SetSize(self.db.profile.width, 14)
		self.bar.content:Show()
		self.bar.content.OnStatusBarsUpdated = function() end

		self.bar.manager = StatusTrackingBarManager
		self.bar.manager:SetParent(self.bar.content)
		self.bar.manager:ClearAllPoints()
		self.bar.manager:SetPoint("BOTTOMLEFT", self.bar.content, "BOTTOMLEFT")

		-- add additional anchors to the textures to allow re-sizing the bars
		if self.bar.manager.MainStatusTrackingBarContainer then
			self.bar.manager.MainStatusTrackingBarContainer:SetWidth(self.db.profile.width)
			self.bar.manager.SecondaryStatusTrackingBarContainer:SetWidth(self.db.profile.width)
		else
			self.bar.manager.BottomBarFrameTexture:SetPoint("BOTTOMRIGHT")
			self.bar.manager.TopBarFrameTexture:SetPoint("BOTTOMRIGHT", self.bar.manager.BottomBarFrameTexture, "TOPRIGHT", 0, -3)
		end
		self.bar.manager:Show()
		self.bar.manager:SetFrameLevel(2)
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

function StatusBarMod:ManagerTextLock(_, lock)
	self.bar.manager:SetTextLocked(lock)
end

function StatusBarMod:ManagerUpdateBars()
	self.bar.manager:UpdateBarsShown()
end

function StatusBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

StatusBar.width = 571 + 8
StatusBar.height = 34
StatusBar.offsetX = 7
StatusBar.offsetY = 2
function StatusBar:PerformLayout()
	self.manager:SetWidth(self.config.width)
	self.manager.MainStatusTrackingBarContainer:SetWidth(self.config.width)
	self.manager.SecondaryStatusTrackingBarContainer:SetWidth(self.config.width)

	self.manager:UpdateBarsShown()

	StatusBar.width = self.config.width + 8
	self:SetSize(self.width, self.height)

	local bar = self.content
	bar:SetSize(self.config.width, self.height)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", self.offsetX, self.offsetY)
end

StatusBar.ClickThroughSupport = false
function StatusBar:ControlClickThrough()
	--self.content:EnableMouse(not self.config.clickthrough)
end
