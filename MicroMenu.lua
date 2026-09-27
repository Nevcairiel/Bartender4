--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local MicroMenuMod = Bartender4:NewModule("MicroMenu", "AceHook-3.0", "AceEvent-3.0")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype
local ButtonBar = Bartender4.ButtonBar.prototype

local pairs, setmetatable, table_insert = pairs, setmetatable, table.insert

-- GLOBALS: CharacterMicroButton, SpellbookMicroButton, TalentMicroButton, AchievementMicroButton, QuestLogMicroButton, GuildMicroButton
-- GLOBALS: LFDMicroButton, CollectionsMicroButton, EJMicroButton, MainMenuMicroButton
-- GLOBALS: HasVehicleActionBar, UnitVehicleSkin, HasOverrideActionBar, GetOverrideBarSkin

local BT_MICRO_BUTTONS
if Bartender4.GameType.ClassicMists then
	BT_MICRO_BUTTONS = {
		"CharacterMicroButton",
		"SpellbookMicroButton",
		"TalentMicroButton",
		"AchievementMicroButton",
		"QuestLogMicroButton",
		"SocialsMicroButton",
		"GuildMicroButton",
		"PVPMicroButton",
		"LFGMicroButton",
		"CollectionsMicroButton",
		"EJMicroButton",
		--"HelpMicroButton",
		"StoreMicroButton",
		"MainMenuMicroButton",
	}
elseif Bartender4.GameType.ClassicBCC then
	BT_MICRO_BUTTONS = {
		"CharacterMicroButton",
		"SpellbookMicroButton",
		"TalentMicroButton",
		"QuestLogMicroButton",
		"SocialsMicroButton",
		--"GuildMicroButton", -- social and guild share a spot
		"WorldMapMicroButton",
		"MainMenuMicroButton",
		"HelpMicroButton",
	}
elseif Bartender4.GameType.Classic then
	BT_MICRO_BUTTONS = {
		"CharacterMicroButton",
		"SpellbookMicroButton",
		"TalentMicroButton",
		"QuestLogMicroButton",
		"SocialsMicroButton",
		--"GuildMicroButton", -- social and guild share a spot
		"WorldMapMicroButton",
		"MainMenuMicroButton",
		"HelpMicroButton",
	}
elseif Bartender4.GameType.Forever then
	BT_MICRO_BUTTONS = {
		"CharacterMicroButton",
		"ProfessionMicroButton",
		"SpellbookMicroButton",
		"TalentMicroButton",
		"LegacyMicroButton",
		"QuestLogMicroButton",
		--"HousingMicroButton",
		"GuildMicroButton",
		"LFDMicroButton",
		"CollectionsMicroButton",
		--"EJMicroButton",
		"HelpMicroButton",
		"StoreMicroButton",
		"MainMenuMicroButton",
	}
else
	BT_MICRO_BUTTONS = {
		"CharacterMicroButton",
		"ProfessionMicroButton",
		"PlayerSpellsMicroButton",
		"AchievementMicroButton",
		"QuestLogMicroButton",
		"HousingMicroButton",
		"GuildMicroButton",
		"LFDMicroButton",
		"CollectionsMicroButton",
		"EJMicroButton",
		"StoreMicroButton",
		"MainMenuMicroButton",
	}
end


local HelpAndStoreSameButton = (Bartender4.GameType.Classic or Bartender4.GameType.Forever) and HelpMicroButton and StoreMicroButton and tContains(BT_MICRO_BUTTONS, "StoreMicroButton") and tContains(BT_MICRO_BUTTONS, "HelpMicroButton")

-- create prototype information
local MicroMenuBar = setmetatable({}, {__index = ButtonBar})

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
	vertical = false,
	visibility = {
		possess = false,
	},
	padding = (Bartender4.GameType.ClassicEra or Bartender4.GameType.ClassicMists) and -3 or (Bartender4.GameType.Classic and -4 or 1),
	position = {
		scale = Bartender4.GameType.Classic and 0.8 or 1.0,
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

		-- guild and social share a spot
		if Bartender4.GameType.Classic then
			tDeleteItem(BT_MICRO_BUTTONS, "GuildMicroButton")
		end

		-- these are handled below, if both are in here it'll error
		if HelpAndStoreSameButton then
			tDeleteItem(BT_MICRO_BUTTONS, "HelpMicroButton")
		end

		for i=1, #BT_MICRO_BUTTONS do
			local button = _G[BT_MICRO_BUTTONS[i]]
			if button then
				table_insert(buttons, button)
			end
		end
		self.bar.buttons = buttons

		-- check if its owned by the UI on initial load
		if MicroMenu then
			if MicroMenuContainer then
				self.ownedByUI = (MicroMenu:GetParent() ~= UIParent and MicroMenu:GetParent() ~= Bartender4.UIHider and MicroMenu:GetParent() ~= MicroMenuContainer)
			else
				self.ownedByUI = (MicroMenu:GetParent() ~= UIParent and MicroMenu:GetParent() ~= Bartender4.UIHider)
			end

			if not self.ownedByUI then
				for i,v in pairs(buttons) do
					v:SetParent(self.bar)
				end
			end

		elseif self.bar.buttons[1]:GetParent() ~= MainMenuBarArtFrame then
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
	if UpdateMicroButtonsParent then
		self:SecureHook("UpdateMicroButtonsParent")
		UpdateMicroButtonsParent(self.bar)
	end
	if MicroMenu then
		self:SecureHook(MicroMenu, "SetParent", "MicroMenuSetParent")
	end
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

function MicroMenuMod:RestoreMicroButtonParent()
	if UpdateMicroButtonsParent then
		UpdateMicroButtonsParent(self.bar)
	end
	if MicroMenu then
		MicroMenu:SetParent(UIParent)
	end
end

function MicroMenuMod:PET_BATTLE_CLOSE()
	self:RestoreMicroButtonParent()
	self:MicroMenuBarShow()
end

function MicroMenuMod:ActionBarController_UpdateAll()
	if self.ownedByUI and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN and not (C_PetBattles and C_PetBattles.IsInBattle()) then
		self:RestoreMicroButtonParent()
		self:MicroMenuBarShow()
	end
end

function MicroMenuMod:MicroMenuSetParent(_, parent)
	if parent == UIParent or (MicroMenuContainer and parent == MicroMenuContainer) then
		for i,v in pairs(self.bar.buttons) do
			v:SetParent(self.bar)
		end

		self.ownedByUI = false
		self:MicroMenuBarShow()
		return
	end

	for i,v in pairs(self.bar.buttons) do
		v:SetParent(MicroMenu)
	end

	self.ownedByUI = true
	MicroMenu.oldGridSettings = nil -- reset grid settings so that layout always runs
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
		if UpdateMicroButtonsParent then
			UpdateMicroButtonsParent(self.bar)
		end
		self.bar:UpdateButtonLayout()
	end
end

function MicroMenuMod:BlizzardBarShow()
	if Bartender4.GameType.Classic then
		-- Only reset button positions not set in MoveMicroButtons()
		for i,v in pairs(self.bar.buttons) do
			if v ~= CharacterMicroButton and v ~= PVPMicroButton then
				v:ClearSetPoint(unpack(self.bar.anchors[i]))
			end
		end
	end
end

MicroMenuBar.button_width = 32
MicroMenuBar.button_height = 40
MicroMenuBar.vpad_offset = 0
if Bartender4.GameType.Mainline then
	MicroMenuBar.hpad_offset = -8
end
function MicroMenuBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", -105, 30)
		self:SavePosition()
	end

	self:UpdateButtonLayout()
end

function MicroMenuBar:UpdateButtonLayout()
	ButtonBar.UpdateButtonLayout(self)

	if HelpAndStoreSameButton then
		HelpMicroButton:ClearAllPoints()
		HelpMicroButton:SetAllPoints(StoreMicroButton)
		-- If the StoreButton is hidden we want to replace it with the Help button
		if not StoreMicroButton:IsShown() then
			HelpMicroButton:Show()
		else
			HelpMicroButton:Hide()
		end
	end

	if Bartender4.GameType.Classic and GuildMicroButton then
		GuildMicroButton:SetParent(self)
		GuildMicroButton:ClearAllPoints()
		GuildMicroButton:SetAllPoints(SocialsMicroButton)
	end
end

if not Bartender4.GameType.Classic and QueueStatusButton then
	local QueueStatusMod = Bartender4:NewModule("QueueStatusButtonBar", "AceHook-3.0")

	-- create prototype information
	local QueueStatusBar = setmetatable({}, {__index = Bar})

	local queuedefaults = { profile = Bartender4.Util:Merge({
		enabled = true,
		visibility = {
			possess = false,
		},
		position = {
			x = -315,
			y = 150,
			point = "BOTTOMRIGHT",
		},
	}, Bartender4.Bar.defaults) }

	function QueueStatusMod:OnInitialize()
		self.db = Bartender4.db:RegisterNamespace("QueueStatus", queuedefaults)
		self:SetEnabledState(self.db.profile.enabled)
	end

	function QueueStatusMod:OnEnable()
		if not self.bar then
			self.bar = setmetatable(Bartender4.Bar:Create("QueueStatus", self.db.profile, L["Queue Status"], 1), {__index = QueueStatusBar})
			self.bar:SetSize(45, 45)
			self.bar.content = QueueStatusButton
			self.bar.content:SetParent(self.bar)
		end
		if QueueStatusButton.UpdatePosition then
			self:SecureHook(QueueStatusButton, "UpdatePosition", "UpdateLayout")
		end
		self.bar:Enable()
		self:ToggleOptions()
		self:ApplyConfig()
	end

	function QueueStatusMod:ApplyConfig()
		self.bar:ApplyConfig(self.db.profile)
	end

	function QueueStatusMod:UpdateLayout()
		self.bar:PerformLayout()
	end

	function QueueStatusBar:ApplyConfig(config)
		Bar.ApplyConfig(self, config)

		self:PerformLayout()
	end

	QueueStatusBar.width = 45
	QueueStatusBar.height = 45

	function QueueStatusBar:PerformLayout()
		local bar = self.content
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
	end
end
