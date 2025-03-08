std = "lua51"
max_line_length = false
exclude_files = {
	"libs/",
	"locale/find-locale-strings.lua",
	".luacheckrc"
}

ignore = {
	"11./BINDING_.*", -- Setting an undefined (Keybinding) global variable
	"211", -- Unused local variable
	"211/L", -- Unused local variable "L"
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
	"542", -- empty if branch
}

globals = {
	"_G",
	"UIPARENT_MANAGED_FRAME_POSITIONS",
	"ShowPetActionBar",

	"CharacterReagentBag0Slot",
	"CharacterBag3Slot",
	"CharacterBag2Slot",
	"CharacterBag1Slot",
	"CharacterBag0Slot",
	"MainMenuBarBackpackButton",
	"MicroMenu",

	"UIParentBottomManagedFrameContainer",
}

read_globals = {
	"bit",
	"max", "min", "floor", "ceil",
	"format",
	"hooksecurefunc",
	"issecurevariable",
	"CopyTable",
	"tDeleteItem",
	"table.wipe",

	-- misc custom, third party libraries
	"LibStub",
	"KeyboundDialog",
	"AceGUIWidgetLSMlists",

	-- API groups
	"C_AddOns",
	"C_LFGList",
	"C_PetBattles",
	"C_Spell",
	"C_SpellBook",

	-- API functions
	"AttemptToSaveBindings",
	"CanExitVehicle",
	"ClearOverrideBindings",
	"CreateFrame",
	"GetBindingKey",
	"GetBindingText",
	"GetBuildInfo",
	"GetClassicExpansionLevel",
	"GetCurrentBindingSet",
	"GetCursorInfo",
	"GetCVarBool",
	"GetModifiedClick",
	"GetNumShapeshiftForms",
	"GetPetActionCooldown",
	"GetPetActionInfo",
	"GetPetActionsUsable",
	"GetShapeshiftFormCooldown",
	"GetShapeshiftFormInfo",
	"GetSpecialization",
	"GetSpellBookItemInfo",
	"GetSpellInfo",
	"HasExtraActionBar",
	"InCombatLockdown",
	"IsKeyRingEnabled",
	"IsModifiedClick",
	"IsPetAttackAction",
	"MouseIsOver",
	"PickupPetAction",
	"PlaySound",
	"SaveBindings",
	"SetBinding",
	"SetBindingClick",
	"SetCVar",
	"SetModifiedClick",
	"SetOverrideBinding",
	"SetOverrideBindingClick",
	"UnitClass",
	"UnitFactionGroup",
	"UnitHasVehicleUI",
	"UnitOnTaxi",
	"VehicleExit",

	-- FrameXML functions
	"ActionBarController_GetCurrentActionBarState",
	"AnchorUtil",
	"AutoCastShine_AutoCastStart",
	"AutoCastShine_AutoCastStop",
	"CooldownFrame_Set",
	"EditModeMagnetismManager",
	"GridLayoutUtil",
	"HasMultiCastActionBar",
	"MainMenuBarVehicleLeaveButton_Update",
	"NPE_LoadUI",
	"RegisterStateDriver",
	"SetDesaturation",
	"Tutorials",
	"UnregisterStateDriver",
	"UpdateMicroButtonsParent",

	-- FrameXML Frames
	"AchievementMicroButton",
	"BagsBar",
	"CharacterMicroButton",
	"CollectionsMicroButton",
	"EditModeManagerFrame",
	"EJMicroButton",
	"EventRegistry",
	"ExtraAbilityContainer",
	"ExtraActionBarFrame",
	"GameTooltip",
	"GuildMicroButton",
	"HelpMicroButton",
	"PVPMicroButton",
	"MainMenuBar",
	"MainMenuBarArtFrame",
	"MainMenuBarArtFrameBackground",
	"MainMenuBarMaxLevelBar",
	"MainMenuMicroButton",
	"MainMenuBarVehicleLeaveButton",
	"MicroButtonAndBagsBar",
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"MultiBarLeft",
	"MultiBarRight",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
	"MultiCastActionBarFrame",
	"OverrideActionBar",
	"PetActionBar",
	"PetActionBarFrame",
	"PetBattleFrame",
	"PlayerTalentFrame",
	"PossessActionBar",
	"PossessBarFrame",
	"QueueStatusButton",
	"QueueStatusFrame",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"SpellbookMicroButton",
	"SpellFlyout",
	"StanceBar",
	"StanceBarFrame",
	"StatusTrackingBarManager",
	"StoreMicroButton",
	"TalentMicroButton",
	"UIParent",
	"WorldFrame",
	"ZoneAbilityFrame",

	-- FrameXML Misc
	"BackdropTemplateMixin",
	"ChatFontNormal",
	"GameFontNormal",
	"MICRO_BUTTONS",
	"Spell",

	-- FrameXML Constants
	"Enum",
	"LE_ACTIONBAR_STATE_MAIN",
	"LE_ACTIONBAR_STATE_OVERRIDE",
	"LEAVE_VEHICLE",
	"OKAY",
	"SOUNDKIT",
	"WOW_PROJECT_ID",
	"WOW_PROJECT_MAINLINE",
	"WOW_PROJECT_CLASSIC",
	"WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
	"WOW_PROJECT_WRATH_CLASSIC",
	"WOW_PROJECT_CATACLYSM_CLASSIC",

	-- Classic-only
	"KeyRingButton",
	"MainMenuBar_UpdateKeyRing",
	"MainMenuBarPerformanceBarFrame",
	"MainMenuExpBar",
	"ReputationWatchBar",
}
