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
}

read_globals = {
	"bit",
	"max", "min", "floor", "ceil",
	"format",
	"hooksecurefunc",
	"CopyTable",
	"tDeleteItem",

	-- misc custom, third party libraries
	"LibStub",

	-- API functions
	"AttemptToSaveBindings",
	"C_LFGList",
	"C_PetBattles",
	"CanExitVehicle",
	"ClearOverrideBindings",
	"CreateFrame",
	"GetBindingKey",
	"GetBindingText",
	"GetBuildInfo",
	"GetClassicExpansionLevel",
	"GetCurrentBindingSet",
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
	"IsAddOnLoaded",
	"IsModifiedClick",
	"MouseIsOver",
	"PickupPetAction",
	"PlaySound",
	"SaveBindings",
	"SetBinding",
	"SetCVar",
	"SetModifiedClick",
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
	"CharacterMicroButton",
	"CollectionsMicroButton",
	"EJMicroButton",
	"ExtraAbilityContainer",
	"ExtraActionBarFrame",
	"GuildMicroButton",
	"HelpMicroButton",
	"LFDMicroButton",
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
	"QueueStatusFrame",
	"QuestLogMicroButton",
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

	-- FrameXML Constants
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

	-- Classic-only
	"KeyRingButton",
	"MainMenuBarPerformanceBarFrame",
	"MainMenuExpBar",
	"ReputationWatchBar",
}
