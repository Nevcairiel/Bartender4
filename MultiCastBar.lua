--[[
	Copyright (c) 2009-2012, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

local _, Bartender4 = ...

if Bartender4.GameType.MainlineStandard or not HasMultiCastActionBar or not MultiCastActionBarFrame or select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
}, Bartender4.Bar.defaults) }

-- register module
local MultiCastMod = Bartender4:NewModule("MultiCast", "AceHook-3.0", "AceEvent-3.0")

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

		-- remove EditMode hooks
		self.bar.content.ClearAllPoints = nil
		self.bar.content.SetPoint = nil
		self.bar.content.SetScale = nil

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

	if MultiCastActionBarFrame and MultiCastActionBarFrame.ApplySystemAnchor then
		self:SecureHook(MultiCastActionBarFrame, "ApplySystemAnchor")
		self:SecureHook(MultiCastActionBarFrame, "HighlightSystem")
	end

	if EditModeManagerFrame and EditModeManagerFrame.UpdateBottomActionBarPositions then
		self:SecureHook(EditModeManagerFrame, "UpdateBottomActionBarPositions", "ApplySystemAnchor")
		self:SecureHookScript(EditModeManagerFrame, "OnShow", "EditModeShown")
		self:SecureHookScript(EditModeManagerFrame, "OnHide", "ReleaseFromEditMode")
	end
	self:ReleaseFromEditMode()

	if UIParentBottomManagedFrameContainer then
		UIParentBottomManagedFrameContainer.showingFrames[MultiCastActionBarFrame] = nil
	end
end

-- EditMode re-anchors every bottom bar that is "in its default position" whenever
-- the bar layout changes (e.g. entering Ghost Wolf), in combat as well, where we
-- cannot move it back. Clear the flag (securely, without taint) so EditMode
-- leaves the totem bar alone. It is restored while EditMode is open, since
-- saving layouts expects a value.
function MultiCastMod:ReleaseFromEditMode()
	local info = MultiCastActionBarFrame.systemInfo
	if info and info.isInDefaultPosition ~= nil and not (EditModeManagerFrame and EditModeManagerFrame:IsShown()) then
		Bartender4.Util:PurgeKey(info, "isInDefaultPosition")
	end
end

function MultiCastMod:EditModeShown()
	local info = MultiCastActionBarFrame.systemInfo
	if info and info.isInDefaultPosition == nil then
		info.isInDefaultPosition = false
	end
end

function MultiCastMod:ApplySystemAnchor()
	self:ReleaseFromEditMode()
	-- Blizzard re-runs its bar layout on e.g. stance changes, also in combat,
	-- where the totem bar cannot be moved. Skip when it is still anchored
	-- correctly, and otherwise re-anchor once combat ends.
	if self.bar:IsAnchoredCorrectly() then return end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	self.bar:PerformLayout()
end

function MultiCastMod:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.bar:PerformLayout()
end

function MultiCastMod:HighlightSystem()
	if MultiCastActionBarFrame.Selection then
		MultiCastActionBarFrame.Selection:Hide()
	end
	EditModeMagnetismManager:UnregisterFrame(MultiCastActionBarFrame)
end

function MultiCastMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

function MultiCastBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

function MultiCastBar:IsAnchoredCorrectly()
	local bar = self.content
	if bar:GetNumPoints() ~= 1 then return false end
	local point, relativeTo, relativePoint, x, y = bar:GetPoint(1)
	return point == "TOPLEFT" and relativeTo == self and relativePoint == "TOPLEFT" and x == 3 and y == 1
end

function MultiCastBar:PerformLayout()
	if InCombatLockdown() then return end
	self:SetSize(230, 40)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 1)
end
