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
	width = Bartender4.GameType.Classic and 1024 or STATUS_BAR_CONTAINER_WIDTH or 571,
	barPadding = Bartender4.GameType.Mainline and 3 or 0,
}, Bartender4.Bar.defaults) }

-- register module
local StatusBarMod = Bartender4:NewModule("StatusTrackingBar", "AceHook-3.0")

-- create prototype information
local StatusBar = setmetatable({}, {__index = Bar})

function StatusBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StatusTrackingBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	if Bartender4.GameType.Classic then
		self.db.profile.width = 1024
	end
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


		if self.bar.manager.MainStatusTrackingBarContainer then
			-- disable clamped to screen
			self.bar.manager.MainStatusTrackingBarContainer:SetClampedToScreen(false)
			self.bar.manager.SecondaryStatusTrackingBarContainer:SetClampedToScreen(false)

			-- disable edit mode hooks
			self.bar.manager.MainStatusTrackingBarContainer.OnEditModeEnter = function() end
			self.bar.manager.SecondaryStatusTrackingBarContainer.OnEditModeEnter = function() end
			self.bar.manager.MainStatusTrackingBarContainer.UpdateSystem = function() end
			self.bar.manager.SecondaryStatusTrackingBarContainer.UpdateSystem = function() end

			-- disable edit mode overrides
			self.bar.manager.MainStatusTrackingBarContainer.ClearAllPoints = nil
			self.bar.manager.MainStatusTrackingBarContainer.SetPoint = nil
			self.bar.manager.MainStatusTrackingBarContainer.SetScale = nil
			self.bar.manager.SecondaryStatusTrackingBarContainer.ClearAllPoints = nil
			self.bar.manager.SecondaryStatusTrackingBarContainer.SetPoint = nil
			self.bar.manager.SecondaryStatusTrackingBarContainer.SetScale = nil

			-- add additional anchors to the bars to allow re-sizing
			self:AnchorTrackingContainers()
		end
		self.bar.manager:Show()
		self.bar.manager:SetFrameLevel(2)
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	if EditModeManagerFrame and EditModeManagerFrame.UpdateBottomActionBarPositions then
		self:SecureHook(EditModeManagerFrame, "UpdateBottomActionBarPositions", "AnchorTrackingContainers")
	end
end

function StatusBarMod:AnchorTrackingContainers()
	if self.bar.manager.MainStatusTrackingBarContainer then
		self.bar.manager.MainStatusTrackingBarContainer:ClearAllPoints()
		self.bar.manager.MainStatusTrackingBarContainer:SetPoint("BOTTOMLEFT", self.bar.manager, "BOTTOMLEFT")
		self.bar.manager.MainStatusTrackingBarContainer:SetPoint("BOTTOMRIGHT", self.bar.manager, "BOTTOMRIGHT")

		local yOffset = self.db.profile.barPadding + (Bartender4.GameType.Mainline and -6 or 0)
		self.bar.manager.SecondaryStatusTrackingBarContainer:ClearAllPoints()
		self.bar.manager.SecondaryStatusTrackingBarContainer:SetPoint("BOTTOMLEFT", self.bar.manager.MainStatusTrackingBarContainer, "TOPLEFT", 0, yOffset)
		self.bar.manager.SecondaryStatusTrackingBarContainer:SetPoint("BOTTOMRIGHT", self.bar.manager.MainStatusTrackingBarContainer, "TOPRIGHT", 0, yOffset)
	end
end

function StatusBarMod:ApplyConfig()
	self:AnchorTrackingContainers()
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

local function StatusTrackingBarContainer_ResizeContainerBars(container, width)
	local barWidth = (width or container:GetWidth()) - (STATUS_BAR_SIZE_ADJUSTMENT or 6)
	local barHeight = container:GetHeight() - (STATUS_BAR_SIZE_ADJUSTMENT or 6)

	for i, bar in ipairs(container.bars) do
		bar:SetSize(barWidth, barHeight)
		bar.StatusBar:SetSize(barWidth, barHeight)
	end

	container:SetWidth(width)
	if container.UpdateDividers and container.GetExpectedSegments then
		local numSegments = container:GetExpectedSegments()
		container:UpdateDividers(numSegments)
	end
end

StatusBar.width = (STATUS_BAR_CONTAINER_WIDTH or 571) + 8
StatusBar.height = (STATUS_BAR_CONTAINER_HEIGHT or 17) * 2
StatusBar.offsetX = 7
StatusBar.offsetY = 2
function StatusBar:PerformLayout()
	self.manager:SetWidth(self.config.width)
	self.manager:UpdateBarsShown()
	StatusTrackingBarContainer_ResizeContainerBars(self.manager.MainStatusTrackingBarContainer, self.config.width)
	StatusTrackingBarContainer_ResizeContainerBars(self.manager.SecondaryStatusTrackingBarContainer, self.config.width)

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
