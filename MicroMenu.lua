--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local MicroMenuMod = Bartender4:NewModule("MicroMenu", "AceHook-3.0", "AceEvent-3.0")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype

local pairs, setmetatable, table_insert = pairs, setmetatable, table.insert

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
local WoW10 = select(4, GetBuildInfo()) >= 100000

-- GLOBALS: CharacterMicroButton, SpellbookMicroButton, TalentMicroButton, AchievementMicroButton, QuestLogMicroButton, GuildMicroButton
-- GLOBALS: LFDMicroButton, CollectionsMicroButton, EJMicroButton, MainMenuMicroButton
-- GLOBALS: HasVehicleActionBar, UnitVehicleSkin, HasOverrideActionBar, GetOverrideBarSkin

local BT_MICRO_BUTTONS = WoWClassic and CopyTable(MICRO_BUTTONS) or
	{
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"CollectionsMicroButton",
	"EJMicroButton",
	"StoreMicroButton",
	"MainMenuMicroButton",
	}

-- create prototype information
local MicroMenuBar = setmetatable({}, {__index = ButtonBar})

local defaults = { profile = Bartender4:Merge({
	enabled = true,
	vertical = false,
	visibility = {
		possess = false,
	},
	padding = WoW10 and 1 or -3,
	position = {
		scale = WoW10 and 1.0 or 0.8,
	},
}, Bartender4.ButtonBar.defaults) }

function MicroMenuMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("MicroMenu", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function MicroMenuMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("MicroMenu", self.db.profile, L["Micro Menu"], true), {__index = MicroMenuBar})
		local buttons = {}

		-- handle lfg/worldmap button on classic
		if WoWClassic then
			tDeleteItem(BT_MICRO_BUTTONS, C_LFGList.IsLookingForGroupEnabled() and "WorldMapMicroButton" or "LFGMicroButton")
		end

		for i=1, #BT_MICRO_BUTTONS do
			table_insert(buttons, _G[BT_MICRO_BUTTONS[i]])
		end
		self.bar.buttons = buttons

		-- check if its owned by the UI on initial load
		if self.bar.buttons[1]:GetParent() ~= MainMenuBarArtFrame then
			self.ownedByUI = true
		end

		MicroMenuMod.button_count = #buttons

		self.bar.anchors = {}
		for i,v in pairs(buttons) do
			self.bar.anchors[i] = { v:GetPoint() }	-- Save orig button anchors.
			v:SetFrameLevel(self.bar:GetFrameLevel() + 1)
			v.ClearSetPoint = self.bar.ClearSetPoint
		end
	end

	self:SecureHook("UpdateMicroButtons", "MicroMenuBarShow")
	self:SecureHook("UpdateMicroButtonsParent")
	self:SecureHook("ActionBarController_UpdateAll")
	if C_PetBattles then
		self:RegisterEvent("PET_BATTLE_CLOSE")
	end

	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	self:MicroMenuBarShow()
end

function MicroMenuMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function MicroMenuMod:PET_BATTLE_CLOSE()
	UpdateMicroButtonsParent(self.bar)
	self:MicroMenuBarShow()
end

function MicroMenuMod:ActionBarController_UpdateAll()
	if self.ownedByUI and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN and not (C_PetBattles and C_PetBattles.IsInBattle()) then
		UpdateMicroButtonsParent(self.bar)
		self:MicroMenuBarShow()
	end
end

function MicroMenuMod:UpdateMicroButtonsParent(parent)
	-- our own parent, ignore
	if parent == self.bar then
		self.ownedByUI = false
		return
	end

	-- any other parent then MainMenuBarArtFrame means its taken over by the Override bar or the PetBattleFrame
	if parent and ((Bartender4.db.profile.blizzardVehicle and parent == OverrideActionBar) or parent == (PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame)) then
		self.ownedByUI = true
		self:BlizzardBarShow()
		return
	end
	self.ownedByUI = false
	self:MicroMenuBarShow()
end

function MicroMenuMod:MicroMenuBarShow()
	-- Only "fix" button anchors if another frame that uses the MicroButtonBar isn't active.
	if not self.ownedByUI then
		UpdateMicroButtonsParent(self.bar)
		self.bar:UpdateButtonLayout()
	end
end

function MicroMenuMod:BlizzardBarShow()
	-- Only reset button positions not set in MoveMicroButtons()
	for i,v in pairs(self.bar.buttons) do
		if v ~= CharacterMicroButton and v ~= LFDMicroButton then
			v:ClearSetPoint(unpack(self.bar.anchors[i]))
		end
	end
end


if WoWClassic then
	MicroMenuBar.button_width = 29
	MicroMenuBar.button_height = 58
	MicroMenuBar.vpad_offset = -20
elseif WoW10 then
	MicroMenuBar.button_width = 19
	MicroMenuBar.button_height = 26
	MicroMenuBar.vpad_offset = 0
else
	MicroMenuBar.button_width = 28
	MicroMenuBar.button_height = 36
end
function MicroMenuBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", -105, 30)
		self:SavePosition()
	end

	self:UpdateButtonLayout()
end

if HelpMicroButton and StoreMicroButton then
	function MicroMenuBar:UpdateButtonLayout()
		ButtonBar.UpdateButtonLayout(self)
		-- If the StoreButton is hidden we want to replace it with the Help button
		if not StoreMicroButton:IsShown() then
			HelpMicroButton:Show()
			HelpMicroButton:ClearAllPoints()
			HelpMicroButton:SetAllPoints(StoreMicroButton)
		else
			HelpMicroButton:Hide()
			HelpMicroButton:ClearAllPoints()
		end
	end
end
