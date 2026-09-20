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

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

local defaults = { profile = Bartender4.Util:Merge({
	enabled = false,
	width = WoWClassic and 1024 or 571,
	twentySections = true,
}, Bartender4.Bar.defaults) }

-- register module
local StatusBarMod = Bartender4:NewModule("StatusTrackingBar", "AceHook-3.0")

-- create prototype information
local StatusBar = setmetatable({}, {__index = Bar})

-- Forever anchors the containers itself, to UIParent and to the chat frame, so they stay
-- behind when the manager moves onto our bar
local function AnchorContainers(manager)
	local main = manager.MainStatusTrackingBarContainer
	local secondary = manager.SecondaryStatusTrackingBarContainer
	if main then
		main:ClearAllPoints()
		main:SetPoint("BOTTOMLEFT", manager, "BOTTOMLEFT")
	end
	if secondary then
		secondary:ClearAllPoints()
		secondary:SetPoint("BOTTOMLEFT", main or manager, main and "TOPLEFT" or "BOTTOMLEFT")
	end
end

-- the bars inside the container keep the width the client built them with, whatever the
-- container does, so a narrower bar only makes them stick out
local function NativeBarWidth(manager)
	local container = manager and manager.MainStatusTrackingBarContainer
	if not container then return nil end

	local width = 0
	for _, child in ipairs({ container:GetChildren() }) do
		width = math.max(width, child:GetWidth() or 0)
	end
	return (width > 8) and math.floor(width + 0.5) or nil
end

function StatusBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StatusTrackingBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	if WoWClassic then
		self.db.profile.width = 1024
	end
end

function StatusBarMod:OnEnable()
	if Bartender4.IsForever then
		local native = NativeBarWidth(StatusTrackingBarManager)
		if native then
			self.db.profile.width = native
		end
	end

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
		end
		self.bar.manager:Show()
		self.bar.manager:SetFrameLevel(2)

		if Bartender4.IsForever then
			local manager = self.bar.manager
			AnchorContainers(manager)
			if manager.UpdateBarsShown then
				hooksecurefunc(manager, "UpdateBarsShown", AnchorContainers)
			end
			-- Edit Mode re-applies its own anchors on the way in and on the way out
			if EditModeManagerFrame then
				local function RestoreAnchors()
					AnchorContainers(manager)
					C_Timer.After(0, function() AnchorContainers(manager) end)
				end
				EditModeManagerFrame:HookScript("OnShow", RestoreAnchors)
				EditModeManagerFrame:HookScript("OnHide", RestoreAnchors)
			end
		end
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

	if Bartender4.IsForever then
		AnchorContainers(self.manager)
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
