--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

-- The bars are built from the status bar templates of the Blizzard UI, and identified by its bar indices.
-- The manager and the containers of the Blizzard UI are not used, they are tied to its edit mode and to its frame
-- position management.
if not StatusTrackingBarInfo then return end

--[[===================================================================================
	Bar definitions
===================================================================================]]--

-- The bars are identified by their index in StatusTrackingBarInfo.BarsEnum of the Blizzard UI, which also holds
-- their priorities. These differ between the clients.
local BarsEnum = StatusTrackingBarInfo.BarsEnum

-- Not every client has every bar. canShow is never called for a bar whose template the client does not have,
-- so it can use the API of its feature freely.
--
-- The events of a bar are those which can change whether it is available, or the values it shows. The unit
-- events are registered for the player. Not every client has every event.
local BAR_DEFINITIONS = {
	{
		barIndex = BarsEnum.Reputation,
		template = "ReputationStatusBarTemplate",
		events = { "UPDATE_FACTION", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" },
		canShow = function()
			local watchedFactionData = C_Reputation.GetWatchedFactionData()
			return watchedFactionData and watchedFactionData.name ~= ""
		end,
	},
	{
		barIndex = BarsEnum.Experience,
		template = "ExpStatusBarTemplate",
		events = { "ENABLE_XP_GAIN", "DISABLE_XP_GAIN", "PLAYER_MAX_LEVEL_UPDATE", "UPDATE_EXPANSION_LEVEL" },
		unitEvents = { "UNIT_LEVEL" },
		canShow = function()
			return GameRulesUtil.CanShowExperienceBar()
		end,
	},
	{
		barIndex = BarsEnum.Honor,
		template = "HonorStatusBarTemplate",
		events = { "HONOR_XP_UPDATE" },
		canShow = function()
			return IsWatchingHonorAsXP() or C_PvP.IsActiveBattlefield() or IsInActiveWorldPVP()
		end,
	},
	{
		barIndex = BarsEnum.Artifact,
		template = "ArtifactStatusBarTemplate",
		events = { "ARTIFACT_XP_UPDATE", "PLAYER_EQUIPMENT_CHANGED" },
		unitEvents = { "UNIT_INVENTORY_CHANGED" },
		canShow = function()
			return HasArtifactEquipped() and not C_ArtifactUI.IsEquippedArtifactMaxed() and not C_ArtifactUI.IsEquippedArtifactDisabled()
		end,
	},
	{
		barIndex = BarsEnum.Azerite,
		template = "AzeriteBarTemplate",
		events = { "AZERITE_ITEM_EXPERIENCE_CHANGED", "PLAYER_EQUIPMENT_CHANGED" },
		unitEvents = { "UNIT_INVENTORY_CHANGED" },
		canShow = function()
			local azeriteItem = C_AzeriteItem.FindActiveAzeriteItem()
			return not C_AzeriteItem.IsAzeriteItemAtMaxLevel() and azeriteItem and azeriteItem:IsEquipmentSlot() and C_AzeriteItem.IsAzeriteItemEnabled(azeriteItem)
		end,
	},
	{
		barIndex = BarsEnum.HouseFavor,
		template = "HouseFavorBarTemplate",
		events = { "TRACKED_HOUSE_CHANGED" },
		canShow = function()
			return C_Housing.GetTrackedHouseGuid()
		end,
	},
}

-- Drop the bars this client does not have, and order the rest by priority. The priorities decide which bars are
-- shown when more are available than there are containers, and in which order. The bar with the highest
-- priority is shown in the main (bottom) container.
for i = #BAR_DEFINITIONS, 1, -1 do
	local definition = BAR_DEFINITIONS[i]
	if definition.barIndex and C_XMLUtil.GetTemplateInfo(definition.template) then
		definition.priority = StatusTrackingBarInfo.BarPriorities[definition.barIndex] or -1
	else
		table.remove(BAR_DEFINITIONS, i)
	end
end
table.sort(BAR_DEFINITIONS, function(left, right) return left.priority > right.priority end)

if #BAR_DEFINITIONS == 0 then return end

-- The events which concern every bar
local SHARED_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"CVAR_UPDATE",
	"ZONE_CHANGED",
	"ZONE_CHANGED_NEW_AREA",
}

--[[===================================================================================
	Layout
===================================================================================]]--

-- The sizes and the artwork follow the status tracking bars of the Blizzard UI of each client.
local LAYOUT
if Bartender4.GameType.Classic then
	LAYOUT = {
		containerHeight = 13,
		defaultWidth = 1024,
		-- the border artwork cannot be resized
		fixedWidth = true,
		-- the bars fill their container
		barInset = 0,
		numSegments = 1,
		secondaryOffset = 0,
		-- the Blizzard UI scales the bars up slightly from Wrath of the Lich King on
		managerScale = (Bartender4.GameType.ClassicEra or Bartender4.GameType.ClassicBCC) and 1 or 1.015,
	}
elseif Bartender4.GameType.Forever then
	LAYOUT = {
		containerHeight = 17,
		defaultWidth = 1192,
		barInset = 3,
		barOffsetX = 1,
		barOffsetY = 2,
		numSegments = 20,
		secondaryOffset = -6,
		managerScale = 1,
	}
else
	LAYOUT = {
		containerHeight = 17,
		defaultWidth = 571,
		barInset = 6,
		barOffsetX = 1,
		barOffsetY = 5,
		numSegments = 1,
		secondaryOffset = -6,
		managerScale = 1,
	}
end

-- The border of the classic bars is the one the Blizzard UI uses for bars which are not docked to its main
-- menu bar. It is made of pieces of this texture, which add up to the fixed width of the bars.
local CLASSIC_BORDER_TEXTURE = "Interface\\PaperDollInfoFrame\\UI-ReputationWatchBar"
-- width, left, right, top, bottom
-- The first two pieces are cut from the same part of the texture, to stretch its left edge.
local CLASSIC_BORDER_PIECES = {
	{ 16, 0.01171875, 0.0625, 0.03125, 0.171875 },
	{ 240, 0.0625, 1, 0.03125, 0.171875 },
	{ 256, 0, 1, 0.203125, 0.34375 },
	{ 256, 0, 1, 0.375, 0.515625 },
	{ 256, 0, 1, 0.546875, 0.6875 },
}

-- Both ends of the border are covered by a cap, each made of this texture and its vertical mirror image
local CLASSIC_CAP_TEXTURE = "Interface\\MainMenuBar\\UI-ExhaustionTickNormal"
local CLASSIC_CAP_SIZE = 9
-- left, right, top, bottom
local CLASSIC_CAP_TCOORDS = { 0.28125, 0.6875, 0.09375, 0.5 }

-- The containers of the classic clients do not fade, the Blizzard UI does not visibly fade them either
local FADE_DURATION = (not Bartender4.GameType.Classic) and 0.5 or nil

local DIVIDER_WIDTH = 3
local DIVIDER_HEIGHT = 10

--[[===================================================================================
	Bar Container

	A container shows the border artwork and one of the bars. It fades in when it is given a bar to show, and
	fades out when it no longer has one.
===================================================================================]]--

-- the index of a container which shows no bar
local NONE = BarsEnum.None

local Container = {}

local function containerFadeOnFinished(self)
	self:GetParent():FinishFading()
end

local function createContainerFadeAnimation(container, fromAlpha, toAlpha)
	local group = container:CreateAnimationGroup()
	group:SetToFinalAlpha(true)

	local alpha = group:CreateAnimation("Alpha")
	alpha:SetOrder(1)
	alpha:SetDuration(FADE_DURATION)
	alpha:SetSmoothing("IN_OUT")
	alpha:SetFromAlpha(fromAlpha)
	alpha:SetToAlpha(toAlpha)

	group:SetScript("OnFinished", containerFadeOnFinished)
	return group
end

local function createClassicBorderCap(container, point, relativeTo, relativePoint, xOffset)
	local left, right, top, bottom = unpack(CLASSIC_CAP_TCOORDS)

	local upper = container:CreateTexture(nil, "OVERLAY", nil, 1)
	upper:SetTexture(CLASSIC_CAP_TEXTURE)
	upper:SetSize(CLASSIC_CAP_SIZE, CLASSIC_CAP_SIZE)
	upper:SetTexCoord(left, right, top, bottom)
	upper:SetPoint(point, relativeTo, relativePoint, xOffset, 3)

	local lower = container:CreateTexture(nil, "OVERLAY", nil, 1)
	lower:SetTexture(CLASSIC_CAP_TEXTURE)
	lower:SetSize(CLASSIC_CAP_SIZE, CLASSIC_CAP_SIZE)
	lower:SetTexCoord(left, right, bottom, top)
	lower:SetPoint("TOP", upper, "BOTTOM", 0, 0)
end

local function createContainerBorder(container)
	if Bartender4.GameType.Classic then
		local first, previous
		for _, piece in ipairs(CLASSIC_BORDER_PIECES) do
			local width, left, right, top, bottom = unpack(piece)
			local texture = container:CreateTexture(nil, "OVERLAY")
			texture:SetTexture(CLASSIC_BORDER_TEXTURE)
			texture:SetSize(width, LAYOUT.containerHeight)
			texture:SetTexCoord(left, right, top, bottom)
			if previous then
				texture:SetPoint("LEFT", previous, "RIGHT", 0, 0)
			else
				texture:SetPoint("LEFT", container, "LEFT", 0, 0)
				first = texture
			end
			previous = texture
		end

		createClassicBorderCap(container, "TOP", first, "TOPLEFT", 1)
		createClassicBorderCap(container, "TOP", previous, "TOPRIGHT", -1)
	else
		local texture = container:CreateTexture(nil, "OVERLAY")
		texture:SetAtlas("UI-HUD-ExperienceBar-Frame")
		texture:SetAllPoints(container)
	end
end

local function createContainer(manager)
	local container = Mixin(CreateFrame("Frame", nil, manager), Container)
	container:SetHeight(LAYOUT.containerHeight)
	container:Hide()

	createContainerBorder(container)

	if FADE_DURATION then
		container.FadeInAnimation = createContainerFadeAnimation(container, 0, 1)
		container.FadeOutAnimation = createContainerFadeAnimation(container, 1, 0)
	end

	container.bars = {}
	for _, definition in ipairs(BAR_DEFINITIONS) do
		local bar = CreateFrame("Frame", nil, container, definition.template)
		bar:Hide()

		-- The bars ask the manager of the Blizzard UI whether their text is locked. They are given their own
		-- function to ask our manager instead, the function of the mixin is shared with the Blizzard bars.
		bar.ShouldBarTextBeDisplayed = function(self)
			return GetCVarBool("xpBarText") or self.textLocked or manager:IsTextLocked()
		end

		bar:ClearAllPoints()
		if LAYOUT.barOffsetX then
			bar:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", LAYOUT.barOffsetX, LAYOUT.barOffsetY)
		else
			bar:SetAllPoints(container)
		end

		container.bars[definition.barIndex] = bar
	end
	container.shownBarIndex = NONE

	if LAYOUT.numSegments > 1 then
		container.dividers = {}
		for i = 1, LAYOUT.numSegments - 1 do
			local divider = CreateFrame("Frame", nil, container)
			divider:SetSize(DIVIDER_WIDTH, DIVIDER_HEIGHT)
			local texture = divider:CreateTexture(nil, "OVERLAY")
			texture:SetAtlas("ui-hud-experiencebar-divider")
			texture:SetAllPoints(divider)
			container.dividers[i] = divider
		end
	end

	table.insert(manager.barContainers, container)
end

function Container:SetContainerWidth(width)
	self:SetWidth(width)

	local barWidth = width - LAYOUT.barInset
	local barHeight = LAYOUT.containerHeight - LAYOUT.barInset
	for _, bar in pairs(self.bars) do
		bar:SetSize(barWidth, barHeight)
		bar.StatusBar:SetSize(barWidth, barHeight)
	end

	if self.dividers then
		local segmentWidth = width / LAYOUT.numSegments
		for i, divider in ipairs(self.dividers) do
			divider:ClearAllPoints()
			PixelUtil.SetPoint(divider, "LEFT", self, "LEFT", segmentWidth * i, 0)
		end
	end

	-- the tick of a bar is positioned by the width of the bar
	self:UpdateBarTick()
end

function Container:SetShownBar(barIndex)
	if self.shownBarIndex == barIndex then
		return
	end
	self.shownBarIndex = barIndex

	self:StopFading()
	if barIndex ~= NONE then
		self:UpdateShownState()
		if self.FadeInAnimation and self:IsVisible() then
			self:SetAlpha(0)
			self.FadeInAnimation:Play()
		end
	elseif self.FadeOutAnimation and self:IsVisible() then
		-- the bar remains shown until the container has faded out
		self.FadeOutAnimation:Play()
	else
		self:UpdateShownState()
	end
end

-- Shows the bar of the container and hides the others, or hides the container when it has no bar
function Container:UpdateShownState()
	for barIndex, bar in pairs(self.bars) do
		if barIndex == self.shownBarIndex then
			self:UpdateBar(bar)
			bar:Show()
		else
			bar:Hide()
		end
	end

	self:SetShown(self.shownBarIndex ~= NONE)
end

function Container:IsFading()
	return self.FadeInAnimation and (self.FadeInAnimation:IsPlaying() or self.FadeOutAnimation:IsPlaying()) or false
end

function Container:StopFading()
	if self.FadeInAnimation then
		self.FadeInAnimation:Stop()
		self.FadeOutAnimation:Stop()
	end
	self:SetAlpha(1)
end

-- Brings the container into the state it has after fading. This is also used to recover a container whose fade
-- did not run to its end, for example because it was hidden meanwhile.
function Container:FinishFading()
	if self.shownBarIndex == NONE then
		self:UpdateShownState()
	end
	self:SetAlpha(1)
end

function Container:GetShownBar()
	return self.bars[self.shownBarIndex]
end

function Container:UpdateShownBarAll()
	local shownBar = self:GetShownBar()
	if shownBar then
		self:UpdateBar(shownBar)
	end
end

function Container:UpdateBar(bar)
	bar:UpdateAll()
	self:UpdateBarText(bar)
end

-- Some bars only write their text when they are hovered, which leaves it empty or outdated while it is locked
function Container:UpdateBarText(bar)
	if bar.UpdateOverlayFrameText then
		bar:UpdateOverlayFrameText()
	end
end

function Container:UpdateBarTextVisibility()
	local shownBar = self:GetShownBar()
	if shownBar then
		shownBar:UpdateTextVisibility()
		self:UpdateBarText(shownBar)
	end
end

function Container:UpdateBarTick()
	local shownBar = self:GetShownBar()
	if shownBar then
		shownBar:UpdateTick()
	end
end

--[[===================================================================================
	Manager

	The manager decides which bars are shown, and in which container.
===================================================================================]]--

local Manager = {}

local function createManager(parent)
	local manager = Mixin(CreateFrame("Frame", nil, parent), Manager)
	manager:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT")
	manager:SetFrameStrata("MEDIUM")
	manager:SetFrameLevel(2)
	manager:SetScale(LAYOUT.managerScale)
	manager:SetScript("OnEvent", manager.Refresh)
	manager:SetScript("OnShow", manager.OnShow)

	manager.barContainers = {}

	-- The main container, and the secondary container above it. Their borders can overlap, the secondary
	-- container is raised so its border is always the one on top.
	createContainer(manager)
	createContainer(manager)
	manager.barContainers[2]:SetFrameLevel(manager.barContainers[1]:GetFrameLevel() + 1)

	return manager
end

function Manager:RegisterEvents()
	for _, event in ipairs(SHARED_EVENTS) do
		self:RegisterEvent(event)
	end

	for _, definition in ipairs(BAR_DEFINITIONS) do
		for _, event in ipairs(definition.events) do
			if C_EventUtils.IsEventValid(event) then
				self:RegisterEvent(event)
			end
		end
		if definition.unitEvents then
			for _, event in ipairs(definition.unitEvents) do
				self:RegisterUnitEvent(event, "player")
			end
		end
	end
end

-- Updates the values of the shown bars, and which bars are shown
function Manager:Refresh()
	for _, container in ipairs(self.barContainers) do
		container:UpdateShownBarAll()
	end

	self:UpdateBarsShown()
end

function Manager:OnShow()
	-- a fade may not have run to its end when the bars were hidden
	for _, container in ipairs(self.barContainers) do
		if not container:IsFading() then
			container:FinishFading()
		end
	end

	-- the bars are not kept up to date while the module is disabled
	self:Refresh()
end

function Manager:UpdateBarsShown()
	-- the definitions are ordered by priority, so the bars to show are the first ones which are available
	local barIndices = {}
	for _, definition in ipairs(BAR_DEFINITIONS) do
		if #barIndices < #self.barContainers and definition.canShow() then
			table.insert(barIndices, definition.barIndex)
		end
	end

	for i, container in ipairs(self.barContainers) do
		container:SetShownBar(barIndices[i] or NONE)
	end
end

function Manager:SetTextLocked(locked)
	locked = locked and true or false
	if self.textLocked ~= locked then
		self.textLocked = locked
		self:UpdateBarTextVisibility()
	end
end

-- The text can also be locked by the configuration, independently of the lock above which follows the Blizzard UI
function Manager:SetConfigTextLocked(locked)
	locked = locked and true or false
	if self.configTextLocked ~= locked then
		self.configTextLocked = locked
		self:UpdateBarTextVisibility()
	end
end

function Manager:IsTextLocked()
	return self.textLocked or self.configTextLocked or false
end

function Manager:UpdateBarTextVisibility()
	for _, container in ipairs(self.barContainers) do
		container:UpdateBarTextVisibility()
	end
end

--[[===================================================================================
	Module
===================================================================================]]--

local defaults = { profile = Bartender4.Util:Merge({
	enabled = false,
	width = LAYOUT.defaultWidth,
	barPadding = Bartender4.GameType.Mainline and 3 or -3,
	lockText = false,
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
		self.bar.content:Show()

		self.bar.manager = createManager(self.bar.content)
	end
	self.bar.manager:RegisterEvents()
	self.bar.manager:Show()

	-- The Blizzard UI tells its own manager to lock the text or to update the bars, for example from the
	-- reputation frame. The manager is only watched to follow these, it is not used otherwise.
	if StatusTrackingBarManager then
		self:SecureHook(StatusTrackingBarManager, "SetTextLocked", "BlizzardManagerTextLocked")
		self:SecureHook(StatusTrackingBarManager, "UpdateBarsShown", "BlizzardManagerBarsUpdated")
		self.bar.manager:SetTextLocked(StatusTrackingBarManager:IsTextLocked())
	end

	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	self.bar.manager:Refresh()
end

function StatusBarMod:BlizzardManagerTextLocked(_, locked)
	self.bar.manager:SetTextLocked(locked)
end

function StatusBarMod:BlizzardManagerBarsUpdated()
	self.bar.manager:Refresh()
end

function StatusBarMod:OnDisable()
	if self.bar then
		self.bar.manager:UnregisterAllEvents()
		self.bar.manager:Hide()
	end

	Bartender4.modulePrototype.OnDisable(self)
end

function StatusBarMod:AnchorTrackingContainers()
	local manager = self.bar.manager
	local main, secondary = manager.barContainers[1], manager.barContainers[2]

	main:ClearAllPoints()
	main:SetPoint("BOTTOMLEFT", manager, "BOTTOMLEFT")

	local yOffset = self.db.profile.barPadding + LAYOUT.secondaryOffset
	secondary:ClearAllPoints()
	secondary:SetPoint("BOTTOMLEFT", main, "TOPLEFT", 0, yOffset)
end

function StatusBarMod:ApplyConfig()
	self:AnchorTrackingContainers()
	self:UpdateTextLock()
	self.bar:ApplyConfig(self.db.profile)
end

function StatusBarMod:UpdateTextLock()
	self.bar.manager:SetConfigTextLocked(self.db.profile.lockText)
end

function StatusBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

StatusBar.height = 34
StatusBar.offsetX = 7
StatusBar.offsetY = 2
function StatusBar:PerformLayout()
	local width = LAYOUT.fixedWidth and LAYOUT.defaultWidth or self.config.width

	self.manager:SetSize(width, LAYOUT.containerHeight * 2)
	for _, container in ipairs(self.manager.barContainers) do
		container:SetContainerWidth(width)
	end

	self:SetSize(width + 8, self.height)

	local bar = self.content
	bar:SetSize(width, self.height)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", self.offsetX, self.offsetY)
end

StatusBar.ClickThroughSupport = false
function StatusBar:ControlClickThrough()
	--self.content:EnableMouse(not self.config.clickthrough)
end
