--[[
	Copyright (c) 2009-2012, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

local _, Bartender4 = ...

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

-- The names of the buttons for the key binding UI and LibKeyBound.
-- The totem buttons are named after their totem slot, but numbered here in the order they are shown in.
local BUTTON_ACTION_NAMES = {
	BT4TotemSummonButton = L["Totem Summon Button"],
	BT4TotemButton2 = L["Totem Button 1 (Earth)"],
	BT4TotemButton1 = L["Totem Button 2 (Fire)"],
	BT4TotemButton3 = L["Totem Button 3 (Water)"],
	BT4TotemButton4 = L["Totem Button 4 (Air)"],
	BT4TotemRecallButton = L["Totem Recall Button"],
}

-- the key bindings are listed for every class, so they are named before the class check
BINDING_HEADER_BT4TOTEM = L["Totem Bar"]
for name, actionName in pairs(BUTTON_ACTION_NAMES) do
	_G[("BINDING_NAME_CLICK %s:LeftButton"):format(name)] = actionName
end

if not HasMultiCastActionBar or select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype
local LAB10 = LibStub("LibActionButton-1.0")

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
	page = 1,
	-- the buttons of the Blizzard totem bar are 8 apart, their borders 4
	padding = 4,
	hidehotkey = true,
}, Bartender4.ButtonBar.defaults) }

-- register module
local TotemBarMod = Bartender4:NewModule("TotemBar")

-- create prototype information
local TotemBar = setmetatable({}, {__index = ButtonBar})

local NUM_PAGES = 3
local SLOTS_PER_PAGE = 4

-- Sizes of the Blizzard totem bar
local BUTTON_SIZE = 30
local OVERLAY_SIZE = 34

-- The border art of a button extends beyond it on every side. The layout treats the border as
-- part of the button, so the padding is the space between borders and the bar covers them.
TotemBar.button_width = BUTTON_SIZE
TotemBar.button_height = BUTTON_SIZE
TotemBar.button_margin = (OVERLAY_SIZE - BUTTON_SIZE) / 2
-- The bar always has the size of all six buttons (summon, the totems, recall), however many are
-- shown, so it does not change size as totems and spells are learned.
TotemBar.fixed_button_count = MAX_TOTEMS + 2

-- All artwork is taken from this texture of the game
local TOTEM_TEXTURE = "Interface\\Buttons\\UI-TotemBar"

-- left, right, top, bottom
local SLOT_EMPTY_TCOORDS = {
	[EARTH_TOTEM_SLOT] = { 66 / 128, 96 / 128, 3 / 256, 33 / 256 },
	[FIRE_TOTEM_SLOT] = { 67 / 128, 97 / 128, 100 / 256, 130 / 256 },
	[WATER_TOTEM_SLOT] = { 39 / 128, 69 / 128, 209 / 256, 239 / 256 },
	[AIR_TOTEM_SLOT] = { 66 / 128, 96 / 128, 36 / 256, 66 / 256 },
}
local SLOT_OVERLAY_TCOORDS = {
	[EARTH_TOTEM_SLOT] = { 1 / 128, 35 / 128, 172 / 256, 206 / 256 },
	[FIRE_TOTEM_SLOT] = { 36 / 128, 70 / 128, 172 / 256, 206 / 256 },
	[WATER_TOTEM_SLOT] = { 1 / 128, 35 / 128, 207 / 256, 240 / 256 },
	[AIR_TOTEM_SLOT] = { 36 / 128, 70 / 128, 137 / 256, 171 / 256 },
}
local SPELL_OVERLAY_TCOORDS = { 0.0078125, 0.2734375, 0.53515625, 0.66796875 }

-- Layout of the Blizzard totem flyout
local FLYOUT_WIDTH = 32
local FLYOUT_ENTRY_SIZE = 24
local FLYOUT_ENTRY_INITIAL_OFFSET = 4
local FLYOUT_ENTRY_SPACING = 2
local FLYOUT_ARROW_WIDTH = 28
local FLYOUT_ARROW_HEIGHT = 18

-- The flyout art comes in one set per totem slot, and one for the page flyout of the summon button
local FLYOUT_OPEN_ARROW_TCOORDS = {
	summon = { 99 / 128, 127 / 128, 84 / 256, 102 / 256 },
	[EARTH_TOTEM_SLOT] = { 99 / 128, 127 / 128, 160 / 256, 178 / 256 },
	[FIRE_TOTEM_SLOT] = { 99 / 128, 127 / 128, 122 / 256, 140 / 256 },
	[WATER_TOTEM_SLOT] = { 99 / 128, 127 / 128, 199 / 256, 217 / 256 },
	[AIR_TOTEM_SLOT] = { 99 / 128, 127 / 128, 237 / 256, 255 / 256 },
}
local FLYOUT_CLOSE_ARROW_TCOORDS = {
	summon = { 99 / 128, 127 / 128, 65 / 256, 83 / 256 },
	[EARTH_TOTEM_SLOT] = { 99 / 128, 127 / 128, 141 / 256, 159 / 256 },
	[FIRE_TOTEM_SLOT] = { 99 / 128, 127 / 128, 103 / 256, 121 / 256 },
	[WATER_TOTEM_SLOT] = { 99 / 128, 127 / 128, 180 / 256, 198 / 256 },
	[AIR_TOTEM_SLOT] = { 99 / 128, 127 / 128, 218 / 256, 236 / 256 },
}
local FLYOUT_TOP_TCOORDS = {
	summon = { 33 / 128, 65 / 128, 1 / 256, 23 / 256 },
	[EARTH_TOTEM_SLOT] = { 0 / 128, 32 / 128, 46 / 256, 68 / 256 },
	[FIRE_TOTEM_SLOT] = { 33 / 128, 65 / 128, 46 / 256, 68 / 256 },
	[WATER_TOTEM_SLOT] = { 0 / 128, 32 / 128, 1 / 256, 23 / 256 },
	[AIR_TOTEM_SLOT] = { 0 / 128, 32 / 128, 91 / 256, 113 / 256 },
}
local FLYOUT_MIDDLE_TCOORDS = {
	summon = { 33 / 128, 65 / 128, 23 / 256, 43 / 256 },
	[EARTH_TOTEM_SLOT] = { 0 / 128, 32 / 128, 68 / 256, 88 / 256 },
	[FIRE_TOTEM_SLOT] = { 33 / 128, 65 / 128, 68 / 256, 88 / 256 },
	[WATER_TOTEM_SLOT] = { 0 / 128, 32 / 128, 23 / 256, 43 / 256 },
	[AIR_TOTEM_SLOT] = { 0 / 128, 32 / 128, 113 / 256, 133 / 256 },
}
local FLYOUT_OPEN_HIGHLIGHT_TCOORDS = { 0.5625, 0.71875, 0.34375, 0.3828125 }
local FLYOUT_CLOSE_HIGHLIGHT_TCOORDS = { 0.5625, 0.71875, 0.26953125, 0.30859375 }

local function isSpellInSpellBook(spellID)
	return spellID and C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player, false) or false
end

function TotemBarMod:OnInitialize()
	-- The module was called MultiCast before, in reference to how Blizzard calls this bar
	self.db = Bartender4.db:RegisterNamespace("MultiCast", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function TotemBarMod:OnEnable()
	if not self.bar then
		-- no Masque skinning, the buttons keep the look of the Blizzard totem bar
		self.bar = setmetatable(Bartender4.ButtonBar:Create("TotemBar", self.db.profile, L["Totem Bar"], true), {__index = TotemBar})
		self.bar:SetScript("OnEvent", TotemBar.OnEvent)
		self.bar:CreateButtons()

		LAB10.RegisterCallback(self, "OnButtonUpdate", function(_, button)
			if button.BT4TotemBar then
				TotemBar.StyleButton(button)
			end
		end)
	end
	self.bar:Enable()
	self:ToggleOptions()

	self.bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
	self.bar:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:ApplyConfig()
end

function TotemBarMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

--[[===================================================================================
	Buttons
===================================================================================]]--

local function createTotemArtTexture(button, layer, sublevel, coords)
	local texture = button:CreateTexture(nil, layer, nil, sublevel)
	texture:SetTexture(TOTEM_TEXTURE)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	return texture
end

-- LibKeyBound shows this instead of the frame name
local function totemBarButtonGetActionName(self)
	return BUTTON_ACTION_NAMES[self:GetName()]
end

-- creates a button of the bar, with the ring that frames it
local function createTotemBarButton(bar, name, overlayCoords)
	local button = LAB10:CreateButton(name, name, bar, nil)
	button.BT4TotemBar = true
	button.GetActionName = totemBarButtonGetActionName

	local overlay = createTotemArtTexture(button, "OVERLAY", 0, overlayCoords)
	overlay:SetSize(OVERLAY_SIZE, OVERLAY_SIZE)
	overlay:SetPoint("CENTER")

	-- the button template is built for full-size buttons, fix up everything that has a fixed size
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button.icon:SetAllPoints()
	for _, key in ipairs({ "NormalTexture", "PushedTexture", "HighlightTexture", "CheckedTexture", "NewActionTexture", "SpellHighlightTexture", "Border", "Flash" }) do
		if button[key] then
			button[key]:SetSize(BUTTON_SIZE, BUTTON_SIZE)
		end
	end
	if button.SlotArt then
		button.SlotArt:Hide()
	end

	-- a spell dropped on the button would replace its state
	button:DisableDragNDrop(true)

	table.insert(bar.buttons, button)
	return button
end

-- LAB re-applies its full-size style on every button update, called from its OnButtonUpdate callback
function TotemBar.StyleButton(button)
	button.HighlightTexture:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button.CheckedTexture:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	-- the generic empty slot background would cover the element art
	button.SlotBackground:Hide()
	if button.icon:IsShown() then
		-- the frame the Blizzard totem bar buttons use
		button:SetNormalAtlas("UI-HUD-ActionBar-IconFrame")
	end
end

function TotemBar:CreateButtons()
	local base = (C_ActionBar.GetMultiCastBarIndex() - 1) * NUM_ACTIONBAR_BUTTONS

	-- all six buttons; UpdateButtons sorts the shown ones to the front for the layout
	self.buttons = {}
	self.numbuttons = 0
	self.totemButtons = {}

	-- every button gets all pages, the page state is pushed to all of them
	local summon = createTotemBarButton(self, "BT4TotemSummonButton", SPELL_OVERLAY_TCOORDS)
	for page = 1, NUM_PAGES do
		summon:SetState(page, "spell", TOTEM_MULTI_CAST_SUMMON_SPELLS[page])
	end
	self.summonButton = summon

	for slot = 1, MAX_TOTEMS do
		local button = createTotemBarButton(self, "BT4TotemButton" .. slot, SLOT_OVERLAY_TCOORDS[slot])
		button.totemSlot = slot
		createTotemArtTexture(button, "BACKGROUND", -1, SLOT_EMPTY_TCOORDS[slot]):SetAllPoints()
		for page = 1, NUM_PAGES do
			button:SetState(page, "action", base + (page - 1) * SLOTS_PER_PAGE + slot)
		end
		self.totemButtons[slot] = button
	end

	local recall = createTotemBarButton(self, "BT4TotemRecallButton", SPELL_OVERLAY_TCOORDS)
	for page = 1, NUM_PAGES do
		recall:SetState(page, "spell", TOTEM_MULTI_CAST_RECALL_SPELLS[1])
	end
	self.recallButton = recall

	-- the page is a secure state, so it can be changed in combat
	self:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])

	self:CreateTotemFlyout()
	self:CreatePageFlyout()
	-- opening one flyout closes the other
	self.totemFlyout:SetFrameRef("other", self.pageFlyout)
	self.pageFlyout:SetFrameRef("other", self.totemFlyout)

	self:SetAttribute("CloseFlyouts", [[
		local totemFlyout, pageFlyout = self:GetFrameRef("totemflyout"), self:GetFrameRef("pageflyout")
		if totemFlyout:IsShown() then
			totemFlyout:RunAttribute("CloseFlyout")
		end
		if pageFlyout:IsShown() then
			pageFlyout:RunAttribute("CloseFlyout")
		end
	]])

	-- Using a button of the bar closes the flyouts. The snippet must not return anything, or it
	-- would change the mouse button LAB's own click handling sees.
	for _, button in ipairs(self.buttons) do
		self:WrapScript(button, "OnClick", [[
			owner:RunAttribute("CloseFlyouts")
		]])
	end
end

function TotemBar:UpdateButtonConfig()
	if not self.buttonConfig then
		self.buttonConfig = {
			-- a totem slot without an assigned totem has no action, but stays visible
			showGrid = true,
			colors = { range = {}, mana = {} },
			hideElements = { macro = true, equipped = true, borderIfEmpty = true },
			text = {
				hotkey = { font = { size = 10 }, position = { offsetX = -1, offsetY = -2 } },
				count = { font = { size = 12 }, position = { offsetX = -1, offsetY = 2 } },
			},
		}
	end
	local buttonConfig, profile = self.buttonConfig, Bartender4.db.profile
	buttonConfig.outOfRangeColoring = profile.outofrange
	buttonConfig.tooltip = profile.tooltip
	buttonConfig.colors.range[1], buttonConfig.colors.range[2], buttonConfig.colors.range[3] = profile.colors.range.r, profile.colors.range.g, profile.colors.range.b
	buttonConfig.colors.mana[1], buttonConfig.colors.mana[2], buttonConfig.colors.mana[3] = profile.colors.mana.r, profile.colors.mana.g, profile.colors.mana.b
	buttonConfig.hideElements.hotkey = self.config.hidehotkey and true or false

	self:ForAll("UpdateConfig", buttonConfig)
end

--[[===================================================================================
	Flyouts

	The flyouts are secure frames, so they can be opened, filled and closed in combat. All
	showing, hiding, sizing and anchoring happens in restricted snippets; only textures are
	set from insecure code.
===================================================================================]]--

local function setTexCoords(texture, coords)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end

local function createArrowTextures(button, highlightCoords)
	button.normalTexture = button:CreateTexture(nil, "ARTWORK")
	button.normalTexture:SetTexture(TOTEM_TEXTURE)
	button.normalTexture:SetAllPoints()

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture(TOTEM_TEXTURE)
	highlight:SetBlendMode("ADD")
	highlight:SetSize(20, 11)
	highlight:SetPoint("CENTER")
	setTexCoords(highlight, highlightCoords)
end

-- Creates an empty flyout: the frame with its background and the close button.
-- Which set of art it shows is decided when it opens, see flyout:UpdateArt.
local function createFlyoutFrame(bar, name)
	local flyout = CreateFrame("Frame", name, bar, "SecureHandlerBaseTemplate")
	flyout:SetWidth(FLYOUT_WIDTH)
	flyout:SetFrameLevel(bar:GetFrameLevel() + 10)
	flyout:Hide()
	flyout.entries = {}
	flyout:SetAttribute("numentries", 0)

	flyout.top = flyout:CreateTexture(nil, "BACKGROUND")
	flyout.top:SetTexture(TOTEM_TEXTURE)
	flyout.top:SetSize(FLYOUT_WIDTH, 20)
	flyout.top:SetPoint("TOP", 0, -10)

	flyout.middle = flyout:CreateTexture(nil, "BACKGROUND")
	flyout.middle:SetTexture(TOTEM_TEXTURE)
	flyout.middle:SetWidth(FLYOUT_WIDTH)
	flyout.middle:SetPoint("TOP", flyout.top, "BOTTOM")
	flyout.middle:SetPoint("BOTTOM")

	-- hides the flyout and brings back the arrow that opened it
	flyout:SetAttribute("CloseFlyout", [[
		local arrow = self:GetFrameRef("arrow")
		if arrow then
			arrow:Show()
		end
		self:Hide()
	]])

	local close = CreateFrame("Button", name .. "CloseButton", flyout, "SecureHandlerClickTemplate")
	close:SetSize(FLYOUT_ARROW_WIDTH, FLYOUT_ARROW_HEIGHT)
	close:SetPoint("TOP")
	close:RegisterForClicks("AnyUp")
	createArrowTextures(close, FLYOUT_CLOSE_HIGHLIGHT_TCOORDS)
	close:SetAttribute("_onclick", [[
		self:GetParent():RunAttribute("CloseFlyout")
	]])
	flyout.closeButton = close

	-- called from the snippet that opens the flyout
	function flyout:UpdateArt(artKey)
		setTexCoords(self.top, FLYOUT_TOP_TCOORDS[artKey])
		setTexCoords(self.middle, FLYOUT_MIDDLE_TCOORDS[artKey])
		setTexCoords(self.closeButton.normalTexture, FLYOUT_CLOSE_ARROW_TCOORDS[artKey])
	end

	return flyout
end

-- Adds an entry to a flyout; the entries stack upwards from the bottom of the flyout.
local function createFlyoutEntry(flyout, template)
	local index = #flyout.entries + 1
	local entry = CreateFrame("Button", flyout:GetName() .. "Button" .. index, flyout, template)
	entry:SetSize(FLYOUT_ENTRY_SIZE, FLYOUT_ENTRY_SIZE)
	if index == 1 then
		entry:SetPoint("BOTTOM", flyout, "BOTTOM", 0, FLYOUT_ENTRY_INITIAL_OFFSET)
	else
		entry:SetPoint("BOTTOM", flyout.entries[index - 1], "TOP", 0, FLYOUT_ENTRY_SPACING)
	end
	entry:RegisterForClicks("AnyUp")
	entry:Hide()

	entry.icon = entry:CreateTexture(nil, "BACKGROUND")
	entry.icon:SetAllPoints()
	entry:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

	flyout.entries[index] = entry
	flyout:SetFrameRef("entry" .. index, entry)
	flyout:SetAttribute("numentries", index)
	return entry
end

-- Creates the arrow above a button of the bar that opens a flyout.
-- The arrow is protected, so it stays shown and is faded in while the mouse is over the button.
local function createFlyoutArrow(opener, flyout, arrowCoords, openSnippet)
	local arrow = CreateFrame("Button", opener:GetName() .. "FlyoutArrow", opener, "SecureHandlerClickTemplate")
	arrow:SetSize(FLYOUT_ARROW_WIDTH, FLYOUT_ARROW_HEIGHT)
	arrow:SetPoint("BOTTOM", opener, "TOP")
	arrow:RegisterForClicks("AnyUp")
	createArrowTextures(arrow, FLYOUT_OPEN_HIGHLIGHT_TCOORDS)
	setTexCoords(arrow.normalTexture, arrowCoords)
	arrow:SetAlpha(0)

	arrow:SetFrameRef("flyout", flyout)
	arrow:SetAttribute("_onclick", openSnippet)

	local function updateAlpha()
		arrow:SetAlpha((opener:IsMouseOver() or arrow:IsMouseOver()) and 1 or 0)
	end
	opener:HookScript("OnEnter", updateAlpha)
	opener:HookScript("OnLeave", updateAlpha)
	arrow:SetScript("OnEnter", updateAlpha)
	arrow:SetScript("OnLeave", updateAlpha)
	-- the arrow is hidden while its flyout is open, and the mouse may be elsewhere when it returns
	arrow:SetScript("OnShow", updateAlpha)

	return arrow
end

-- Fills the totem flyout for the totem slot of the clicked arrow and opens it above the button.
-- Entry 1 clears the slot (spell 0), the others are the totems of the slot.
local OPEN_TOTEM_FLYOUT = [[
	local opener = self:GetParent()
	local flyout = self:GetFrameRef("flyout")
	local slot = self:GetAttribute("totemslot")
	local action = opener:GetAttribute("action")

	local other = flyout:GetFrameRef("other")
	if other:IsShown() then
		other:RunAttribute("CloseFlyout")
	end
	local previous = flyout:GetFrameRef("arrow")
	if previous then
		previous:Show()
	end
	flyout:SetAttribute("frameref-arrow", self)

	local limit = flyout:GetAttribute("numentries")
	local count = select("#", GetMultiCastTotemSpells(slot)) + 1
	if count > limit then
		count = limit
	end
	for i = 1, limit do
		local entry = flyout:GetFrameRef("entry" .. i)
		if i <= count then
			local spell = 0
			if i > 1 then
				spell = select(i - 1, GetMultiCastTotemSpells(slot))
			end
			entry:SetAttribute("action", action)
			entry:SetAttribute("spell", spell)
			entry:SetAttribute("totemslot", slot)
			entry:Show()
			entry:CallMethod("UpdateIcon")
		else
			entry:Hide()
		end
	end

	flyout:SetHeight(%d + count * %d + (count - 1) * %d + 2 + %d)
	flyout:ClearAllPoints()
	flyout:SetPoint("BOTTOM", opener, "TOP", 0, 0)
	flyout:Show()
	flyout:CallMethod("UpdateArt", slot)

	self:Hide()
]]
OPEN_TOTEM_FLYOUT = OPEN_TOTEM_FLYOUT:format(FLYOUT_ENTRY_INITIAL_OFFSET, FLYOUT_ENTRY_SIZE, FLYOUT_ENTRY_SPACING, FLYOUT_ARROW_HEIGHT)

local function totemEntryUpdateIcon(self)
	local spell = self:GetAttribute("spell")
	if spell == 0 then
		self.icon:SetTexture(TOTEM_TEXTURE)
		setTexCoords(self.icon, SLOT_EMPTY_TCOORDS[self:GetAttribute("totemslot")])
	else
		self.icon:SetTexture(C_Spell.GetSpellTexture(spell))
		self.icon:SetTexCoord(0, 1, 0, 1)
	end
end

local function totemEntryOnEnter(self)
	local tooltip = Bartender4.db.profile.tooltip
	if tooltip == "disabled" or (tooltip == "nocombat" and InCombatLockdown()) then return end

	local spell = self:GetAttribute("spell")
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if spell == 0 then
		GameTooltip:SetText(MULTI_CAST_TOOLTIP_NO_TOTEM, 1, 1, 1)
	else
		GameTooltip:SetSpellByID(spell)
	end
end

local function createTotemFlyoutEntry(flyout)
	local entry = createFlyoutEntry(flyout, "SecureActionButtonTemplate")
	-- fires once, on release, whatever the ActionButtonUseKeyDown CVar says
	entry:SetAttribute("useOnKeyDown", false)
	-- the entry has no ID, so the action is taken from its attribute
	entry:SetAttribute("type", "multispell")

	entry.UpdateIcon = totemEntryUpdateIcon
	entry:SetScript("OnEnter", totemEntryOnEnter)
	entry:SetScript("OnLeave", GameTooltip_Hide)

	-- close the flyout after the totem is assigned; the post snippet only runs when the
	-- pre snippet returns a message as its second value
	flyout:WrapScript(entry, "OnClick", [[
		return nil, "close"
	]], [[
		owner:RunAttribute("CloseFlyout")
	]])
	return entry
end

function TotemBar:CreateTotemFlyout()
	local flyout = createFlyoutFrame(self, "BT4TotemFlyout")
	self.totemFlyout = flyout
	self:SetFrameRef("totemflyout", flyout)

	self.flyoutArrows = {}
	for slot, button in ipairs(self.totemButtons) do
		local arrow = createFlyoutArrow(button, flyout, FLYOUT_OPEN_ARROW_TCOORDS[slot], OPEN_TOTEM_FLYOUT)
		arrow:SetAttribute("totemslot", slot)
		table.insert(self.flyoutArrows, arrow)
	end
end

-- Makes sure the totem flyout has enough entries for the slot with the most totems.
-- Entries can only be created out of combat; the open snippet copes with too few.
function TotemBar:UpdateTotemFlyoutEntries()
	local needed = 0
	for slot = 1, MAX_TOTEMS do
		needed = max(needed, select("#", GetMultiCastTotemSpells(slot)) + 1)
	end
	for _ = #self.totemFlyout.entries + 1, needed do
		createTotemFlyoutEntry(self.totemFlyout)
	end
end

-- Opens the page flyout above the summon button. Its entries are set up out of combat.
local OPEN_PAGE_FLYOUT = [[
	local opener = self:GetParent()
	local flyout = self:GetFrameRef("flyout")

	local other = flyout:GetFrameRef("other")
	if other:IsShown() then
		other:RunAttribute("CloseFlyout")
	end
	flyout:SetAttribute("frameref-arrow", self)

	flyout:ClearAllPoints()
	flyout:SetPoint("BOTTOM", opener, "TOP", 0, 0)
	flyout:Show()
	flyout:CallMethod("UpdateArt", "summon")

	self:Hide()
]]

local function pageEntryOnEnter(self)
	local tooltip = Bartender4.db.profile.tooltip
	if tooltip == "disabled" or (tooltip == "nocombat" and InCombatLockdown()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetSpellByID(TOTEM_MULTI_CAST_SUMMON_SPELLS[self:GetAttribute("page")])
end

function TotemBar:CreatePageFlyout()
	local flyout = createFlyoutFrame(self, "BT4TotemPageFlyout")
	self.pageFlyout = flyout
	self:SetFrameRef("pageflyout", flyout)

	for _ = 1, NUM_PAGES do
		local entry = createFlyoutEntry(flyout, "SecureHandlerClickTemplate")
		-- the bar is the parent of the flyout
		entry:SetAttribute("_onclick", [[
			local flyout = self:GetParent()
			local bar = flyout:GetParent()
			local page = self:GetAttribute("page")
			bar:SetAttribute("state-page", page)
			bar:CallMethod("OnPageSelected", page)
			flyout:RunAttribute("CloseFlyout")
		]])
		entry:SetScript("OnEnter", pageEntryOnEnter)
		entry:SetScript("OnLeave", GameTooltip_Hide)
	end

	table.insert(self.flyoutArrows, createFlyoutArrow(self.summonButton, flyout, FLYOUT_OPEN_ARROW_TCOORDS.summon, OPEN_PAGE_FLYOUT))
end

-- Assigns the pages with a known summon spell to the entries of the page flyout.
-- The spellbook cannot be checked from a snippet, so this happens out of combat.
function TotemBar:UpdatePageFlyoutEntries()
	local flyout = self.pageFlyout
	local count = 0
	for page, spellID in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
		if page <= NUM_PAGES and isSpellInSpellBook(spellID) then
			count = count + 1
			local entry = flyout.entries[count]
			entry:SetAttribute("page", page)
			entry.icon:SetTexture(C_Spell.GetSpellTexture(spellID))
			entry:Show()
		end
	end
	for i = count + 1, #flyout.entries do
		flyout.entries[i]:Hide()
	end
	flyout:SetHeight(FLYOUT_ENTRY_INITIAL_OFFSET + count * FLYOUT_ENTRY_SIZE + max(count - 1, 0) * FLYOUT_ENTRY_SPACING + 2 + FLYOUT_ARROW_HEIGHT)
end

-- used by the fade out of the bar, the flyouts and the arrows are outside of the bar area
function TotemBar:IsMouseOverContent()
	if self.totemFlyout:IsShown() and self.totemFlyout:IsMouseOver() then
		return true
	end
	if self.pageFlyout:IsShown() and self.pageFlyout:IsMouseOver() then
		return true
	end
	for _, arrow in ipairs(self.flyoutArrows) do
		if arrow:IsVisible() and arrow:IsMouseOver() then
			return true
		end
	end
	return false
end

--[[===================================================================================
	Paging
===================================================================================]]--

-- Called from the page flyout when the user picks a page, also in combat.
-- Only the user's choice is saved; a page shown as a fallback for it is not.
function TotemBar:OnPageSelected(page)
	page = tonumber(page)
	if page then
		self.config.page = page
	end
end

-- the page to show: the wanted one if its summon spell is known, otherwise the first known one
local function resolveKnownPage(page)
	page = tonumber(page) or 1
	if page < 1 or page > NUM_PAGES then
		page = 1
	end
	if isSpellInSpellBook(TOTEM_MULTI_CAST_SUMMON_SPELLS[page]) then
		return page
	end
	for i = 1, NUM_PAGES do
		if isSpellInSpellBook(TOTEM_MULTI_CAST_SUMMON_SPELLS[i]) then
			return i
		end
	end
	return 1
end

--[[===================================================================================
	Layout
===================================================================================]]--

-- Updates the cached list of totem slots the player has, in display order.
-- Returns false if it cannot be determined right now.
function TotemBar:UpdateActiveSlots()
	-- GetTotemInfo returns secret values while addon restrictions are active
	if InCombatLockdown() then return false end

	local active = {}
	for _, slot in ipairs(SHAMAN_TOTEM_PRIORITIES) do
		local haveTotem = GetTotemInfo(slot)
		local spell = GetMultiCastTotemSpells(slot)
		if issecretvalue(haveTotem) or issecretvalue(spell) then return false end
		if haveTotem and spell then
			active[#active + 1] = slot
		end
	end
	self.activeSlots = active
	return true
end

function TotemBar:UpdateButtons()
	if InCombatLockdown() or not self.activeSlots then
		self.updateOnCombatLeave = true
		return
	end

	-- the buttons may move or hide, and the totems of a slot may have changed
	self:Execute([[
		self:RunAttribute("CloseFlyouts")
	]])
	self:UpdateTotemFlyoutEntries()
	self:UpdatePageFlyoutEntries()

	local page = resolveKnownPage(self.config.page)
	if tonumber(self:GetAttribute("state-page")) ~= page then
		self:SetAttribute("state-page", page)
	end

	-- the shown buttons in display order, followed by the hidden ones
	local buttons, hidden = {}, {}
	local function showOrHideButton(button, show)
		if show then
			button:Show()
			button:SetAttribute("statehidden", nil)
			button:UpdateAction()
			buttons[#buttons + 1] = button
		else
			button:Hide()
			button:SetAttribute("statehidden", true)
			-- a hidden button must not stay anchored to a button of the layout
			button:ClearAllPoints()
			hidden[#hidden + 1] = button
		end
	end

	local active = {}
	for _, slot in ipairs(self.activeSlots) do
		active[slot] = true
	end
	local hasTotems = #self.activeSlots > 0

	showOrHideButton(self.summonButton, hasTotems and isSpellInSpellBook(TOTEM_MULTI_CAST_SUMMON_SPELLS[page]))
	for _, slot in ipairs(SHAMAN_TOTEM_PRIORITIES) do
		showOrHideButton(self.totemButtons[slot], active[slot])
	end
	showOrHideButton(self.recallButton, hasTotems and isSpellInSpellBook(TOTEM_MULTI_CAST_RECALL_SPELLS[1]))

	self.numbuttons = #buttons
	for _, button in ipairs(hidden) do
		buttons[#buttons + 1] = button
	end
	self.buttons = buttons

	self:UpdateButtonLayout()
end

-- The arrows above the buttons only work with a single row: in a second row they would cover
-- the buttons of the first.
function TotemBar:GetRows()
	return 1
end

function TotemBar:SetClickThrough(click)
	ButtonBar.SetClickThrough(self, click)
	for _, arrow in ipairs(self.flyoutArrows) do
		arrow:EnableMouse(not self.config.clickthrough)
	end
end

-- re-evaluate the totem slots and known spells
function TotemBar:Refresh()
	if not self:UpdateActiveSlots() then
		self.updateOnCombatLeave = true
		return
	end
	self:UpdateButtons()
end

function TotemBar:OnEvent(event, ...)
	if event == "PLAYER_REGEN_ENABLED" then
		if self.updateOnCombatLeave and not InCombatLockdown() then
			self.updateOnCombatLeave = nil
			self:Refresh()
		end
	else
		self:Refresh()
	end
end

function TotemBar:ApplyConfig(config)
	if config then
		self.config = config
	end
	-- The bar always grows down, like it always has one row. The bar code reads this value
	-- straight from the config, so it is pinned there.
	self.config.position.growVertical = "DOWN"

	if not self:UpdateActiveSlots() then
		self.updateOnCombatLeave = true
	end

	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", -115, -60)
		self:SavePosition()
	end

	self:UpdateButtonConfig()
	-- shows and lays out the buttons, which also sizes the bar
	self:UpdateButtons()
end
