--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local WoW10 = select(4, GetBuildInfo()) >= 100000

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

-- only available on 8.0
if not StatusTrackingBarManager then return end

local defaults = { profile = Bartender4:Merge({
	enabled = false,
	width = WoW10 and 571 or 804,
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

		if WoW10 then
			self.bar.manager = StatusTrackingBarManager
			self.bar.manager:SetParent(self.bar.content)
			self.bar.manager:ClearAllPoints()
			self.bar.manager:SetPoint("BOTTOMLEFT", self.bar.content, "BOTTOMLEFT")

			-- add additional anchors to the textures to allow re-sizing the bars
			self.bar.manager.BottomBarFrameTexture:SetPoint("BOTTOMRIGHT")
			self.bar.manager.TopBarFrameTexture:SetPoint("BOTTOMRIGHT", self.bar.manager.BottomBarFrameTexture, "TOPRIGHT", 0, -3)
		else
			self.bar.manager = CreateFrame("Frame", "BT4StatusBarTrackingManager", self.bar.content, "StatusTrackingBarManagerTemplate")
			self.bar.manager:AddBarFromTemplate("FRAME", "ReputationStatusBarTemplate")
			self.bar.manager:AddBarFromTemplate("FRAME", "HonorStatusBarTemplate")
			self.bar.manager:AddBarFromTemplate("FRAME", "ArtifactStatusBarTemplate")
			self.bar.manager:AddBarFromTemplate("FRAME", "ExpStatusBarTemplate")
			self.bar.manager:AddBarFromTemplate("FRAME", "AzeriteBarTemplate")
			self.bar.manager:SetBarSize(self.db.profile.twentySections)
		end
		self.bar.manager:Show()
		self.bar.manager:SetFrameLevel(2)
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	if not WoW10 then
		self:SecureHook(StatusTrackingBarManager, "SetTextLocked", "ManagerTextLock")
		self:SecureHook(StatusTrackingBarManager, "UpdateBarsShown", "ManagerUpdateBars")
	end
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

if WoW10 then
	StatusBar.width = 571 + 8
	StatusBar.height = 34
	StatusBar.offsetX = 7
	StatusBar.offsetY = 2
else
	StatusBar.width = 540
	StatusBar.height = 14
	StatusBar.offsetX = 5
	StatusBar.offsetY = 10
end
function StatusBar:PerformLayout()
	self.manager:SetWidth(self.config.width)
	if WoW10 then
		self.manager:UpdateBarsShown()
	else
		self.manager:SetBarSize(self.config.twentySections)
	end

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
