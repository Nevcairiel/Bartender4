--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

if not ExtraAbilityContainer then return end

-- register module
local ExtraActionBarMod = Bartender4:NewModule("ExtraActionBar", "AceHook-3.0", "AceEvent-3.0")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

-- create prototype information
local ExtraActionBar = setmetatable({}, {__index = Bar})

local BAR_SIZE = 128

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

local function noop() end

-- The container of the extra action button and the zone abilities is a system of the edit mode of the Blizzard UI,
-- and a frame its frame position management places. Both move and reparent it, also in combat, where it cannot be
-- moved back. Instead of undoing that afterwards, the container is made immune to it, once:
-- it is taken out of the frame position management, and ignores the anchors the edit mode sets on it.
local function detachContainerFromEditMode(container)
	-- without this the edit mode neither passes the container to the frame position management, nor reparents it
	Bartender4.Util:PurgeKey(container, "isManagedFrame")

	-- these scripts add the container to the frame position management and remove it again, every time it is shown
	container:SetScript("OnShow", nil)
	container:SetScript("OnHide", nil)

	-- it may have been added already
	local showingFrames = container.layoutParent and container.layoutParent.showingFrames
	if showingFrames and showingFrames[container] then
		showingFrames[container] = nil
	end

	-- The edit mode anchors its systems on every update of its layout. It keeps the original functions in
	-- SetPointBase and ClearAllPointsBase, which are used to position the container on the bar.
	container.SetPoint = noop
	container.ClearAllPoints = noop

	-- A layout that was applied before may have snapped the container to another system. That system would move the
	-- container when it hides, the anchors that are set from now on do not create such a link anymore.
	if container.snappedToFrame then
		container.snappedToFrame:RemoveSnappedFrame(container)
		Bartender4.Util:PurgeKey(container, "snappedToFrame")
	end

	-- The selection of the edit mode would allow to drag the container. It has to remain a child of the container,
	-- the edit mode calculates the clamp insets of the container from the position of both.
	container.Selection:SetAlpha(0)
	container.Selection:EnableMouse(false)
end

function ExtraActionBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("ExtraActionBar", self.db.profile, L["Extra Action Bar"], 2), {__index = ExtraActionBar})
		self.bar.content = ExtraAbilityContainer

		detachContainerFromEditMode(ExtraAbilityContainer)
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	self:SecureHook("ExtraActionBar_Update")
	if ZoneAbilityFrame then
		self:SecureHook(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities")
	end
	self:SecureHook(ExtraAbilityContainer, "HighlightSystem")
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
	if ZoneAbilityFrame then
		ZoneAbilityFrame.Style:SetShown(not self.db.profile.hideArtwork)
	end
end

-- Highlighting the container in the edit mode registers it as a target other systems snap to when they are dragged.
-- A system that is snapped to the container would be saved anchored to it, and follow the bar.
function ExtraActionBarMod:HighlightSystem()
	EditModeMagnetismManager:UnregisterFrame(ExtraAbilityContainer)
end

function ExtraActionBarMod:CombatEnded()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.bar:PerformLayout()
end

ExtraActionBar.width = BAR_SIZE
ExtraActionBar.height = BAR_SIZE

function ExtraActionBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("BOTTOM", 0, 160)
		self:SavePosition()
	end

	self:PerformLayout()
end

function ExtraActionBar:PerformLayout()
	-- the container is protected
	if InCombatLockdown() then
		ExtraActionBarMod:RegisterEvent("PLAYER_REGEN_ENABLED", "CombatEnded")
		return
	end

	self:SetSize(BAR_SIZE, BAR_SIZE)
	local container = self.content
	container:SetToplevel(false)
	-- the container is wider than the bar, and would be pushed off the bar close to the edge of the screen
	container:SetClampedToScreen(false)
	container:SetParent(self)
	container:ClearAllPointsBase()
	container:SetPointBase("CENTER", self, "TOPLEFT", BAR_SIZE / 2, -BAR_SIZE / 2)
end
