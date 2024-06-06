--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
Bartender4 = LibStub("AceAddon-3.0"):NewAddon(Bartender4, "Bartender4", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
_G.Bartender4 = Bartender4

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
local WoW10 = select(4, GetBuildInfo()) >= 100000

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local LibDualSpec = (not WoWClassic or WoWWrath or WoWCata) and LibStub("LibDualSpec-1.0", true)

local _G = _G
local type, pairs, hooksecurefunc = type, pairs, hooksecurefunc

-- GLOBALS: LibStub, UIParent, PlaySound, SOUNDKIT, RegisterStateDriver, UnregisterStateDriver
-- GLOBALS: BINDING_HEADER_Bartender4, BINDING_CATEGORY_Bartender4, BINDING_NAME_TOGGLEACTIONBARLOCK, BINDING_NAME_BTTOGGLEACTIONBARLOCK
-- GLOBALS: BINDING_HEADER_BT4PET, BINDING_CATEGORY_BT4PET, BINDING_HEADER_BT4STANCE, BINDING_CATEGORY_BT4STANCE
-- GLOBALS: CreateFrame, MultiBarBottomLeft, MultiBarBottomRight, MultiBarLeft, MultiBarRight, UIPARENT_MANAGED_FRAME_POSITIONS
-- GLOBALS: MainMenuBar, OverrideActionBar, MainMenuBarArtFrame, MainMenuExpBar, MainMenuBarMaxLevelBar, ReputationWatchBar
-- GLOBALS: StanceBarFrame, PossessBarFrame, PetActionBarFrame, PlayerTalentFrame

local defaults = {
	profile = {
		tooltip = "enabled",
		buttonlock = true,
		outofrange = "button",
		colors = { range = { r = 0.8, g = 0.1, b = 0.1 }, mana = { r = 0.5, g = 0.5, b = 1.0 } },
		selfcastmodifier = true,
		focuscastmodifier = true,
		selfcastrightclick = false,
		snapping = true,
		blizzardVehicle = false,
		flyoutBackground = true,
		minimapIcon = {},
		mouseovermod = "NONE"
	}
}

Bartender4.CONFIG_VERSION = 3

local createLDBLauncher

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB", defaults)
	self.db.RegisterCallback(self, "OnNewProfile", "InitializeProfile")
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")

	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(Bartender4.db, "Bartender4")
	end

	self:SetupOptions()

	self.Locked = true
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatLockdown")

	self:HideBlizzard()
	self:RegisterPetBattleDriver()
	self:UpdateBlizzardVehicle()

	-- fix the strata of the QueueStatusFrame, otherwise it overlaps our bars
	if QueueStatusFrame then -- classic doesn't have this
		QueueStatusFrame:SetParent(UIParent)
	end

	if LDB then
		createLDBLauncher()
	end

	BINDING_HEADER_Bartender4 = "Bartender4"
	BINDING_NAME_BTTOGGLEACTIONBARLOCK = BINDING_NAME_TOGGLEACTIONBARLOCK
	local ActionBarsMod = Bartender4:GetModule("ActionBars")
	for _, i in ipairs(ActionBarsMod.LIST_ACTIONBARS) do
		local name = ActionBarsMod:GetBarName(i)
		_G[("BINDING_HEADER_BT4BLANK%d"):format(i)] = name
		for k=1,12 do
			_G[("BINDING_NAME_CLICK BT4Button%d:Keybind"):format(((i-1)*12)+k)] = ("%s %s"):format(name, L["Button %s"]:format(k))
		end
	end
	BINDING_HEADER_BT4PET = L["Pet Bar"]
	BINDING_HEADER_BT4STANCE = L["Stance Bar"]
	for k=1,10 do
		_G[("BINDING_NAME_CLICK BT4PetButton%d:LeftButton"):format(k)] = ("%s %s"):format(L["Pet Bar"], L["Button %s"]:format(k))
		_G[("BINDING_NAME_CLICK BT4StanceButton%d:LeftButton"):format(k)] = ("%s %s"):format(L["Stance Bar"], L["Button %s"]:format(k))
	end

	if EditModeManagerFrame then
		EventRegistry:RegisterCallback("EditMode.Enter", function() self:Unlock(true) end)
		EventRegistry:RegisterCallback("EditMode.Exit", function() self:Lock() end)

		if EditModeManagerFrame.EnableSnapCheckButton then
			self:SecureHook(EditModeManagerFrame.EnableSnapCheckButton, "OnCheckButtonClick", "UpdateSnapFromEditMode")
			self:SecureHook(EditModeManagerFrame.EnableSnapCheckButton, "SetControlChecked", "UpdateSnapFromEditMode")
		end
	end
end

function Bartender4:InitializeProfile()
	local PresetMod = self:GetModule("Presets")
	if not self.finishedLoading then
		PresetMod.applyBlizzardOnEnable = true
	else
		PresetMod:ResetProfile("BLIZZARD")
	end
end

function Bartender4:RegisterDefaultsKey(key, subdefaults)
	defaults.profile[key] = subdefaults

	self.db:RegisterDefaults(defaults)
end

function Bartender4:UpdateModuleConfigs()
	local unlock = false
	if not self.Locked then
		self:Lock()
		unlock = true
	end

	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(self) do
		v:ToggleModule()
		if v:IsEnabled() and type(v.ApplyConfig) == "function" then
			v:ApplyConfig()
		end
	end
	if LDB and LDBIcon then
		LDBIcon:Refresh("Bartender4", Bartender4.db.profile.minimapIcon)
	end

	self:UpdateBlizzardVehicle()

	if unlock then
		self:Unlock()
	end
end

function Bartender4:RegisterPetBattleDriver()
	if not self.petBattleController then
		self.petBattleController = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		self.petBattleController:SetAttribute("_onstate-petbattle", [[
			if newstate == "petbattle" then
				for i=1,6 do
					local button, vbutton = ("CLICK BT4Button%d:Keybind"):format(i), ("ACTIONBUTTON%d"):format(i)
					for k=1,select("#", GetBindingKey(button)) do
						local key = select(k, GetBindingKey(button))
						self:SetBinding(true, key, vbutton)
					end
					-- do the same for the default UIs bindings
					for k=1,select("#", GetBindingKey(vbutton)) do
						local key = select(k, GetBindingKey(vbutton))
						self:SetBinding(true, key, vbutton)
					end
				end
			else
				self:ClearBindings()
			end
		]])
		RegisterStateDriver(self.petBattleController, "petbattle", "[petbattle]petbattle;nopetbattle")
	end
end

function Bartender4:UpdateBlizzardVehicle()
	if not OverrideActionBar then return end -- classic doesn't have this
	if self.db.profile.blizzardVehicle then
		--MainMenuBar:SetParent(UIParent)
		OverrideActionBar:SetParent(UIParent)
		if ActionBarController_GetCurrentActionBarState() ~= LE_ACTIONBAR_STATE_OVERRIDE then
			OverrideActionBar:Hide()
		end
		if not self.vehicleController then
			self.vehicleController = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
			self.vehicleController:SetFrameRef("overrideActionBar", OverrideActionBar)
			self.vehicleController:SetAttribute("_onstate-vehicle", [[
				if newstate == "override" then
					local f = self:GetFrameRef("overrideActionBar")
					if (f:GetAttribute("actionpage") or 0) > 10 then
						newstate = "vehicle"
					end
				end
				if newstate == "vehicle" then
					for i=1,6 do
						local button, vbutton = ("CLICK BT4Button%d:Keybind"):format(i), ("OverrideActionBarButton%d"):format(i)
						for k=1,select("#", GetBindingKey(button)) do
							local key = select(k, GetBindingKey(button))
							self:SetBindingClick(true, key, vbutton)
						end
						-- do the same for the default UIs bindings
						button = ("ACTIONBUTTON%d"):format(i)
						for k=1,select("#", GetBindingKey(button)) do
							local key = select(k, GetBindingKey(button))
							self:SetBindingClick(true, key, vbutton)
						end
					end
				else
					self:ClearBindings()
				end
			]])
		end
		RegisterStateDriver(self.vehicleController, "vehicle", "[overridebar]override;[vehicleui]vehicle;novehicle")
	else
		--MainMenuBar:SetParent(self.UIHider)
		OverrideActionBar:SetParent(self.UIHider)
		if self.vehicleController then
			UnregisterStateDriver(self.vehicleController, "vehicle")
		end
	end
end

function Bartender4:CombatLockdown()
	self:Lock()
	LibStub("AceConfigDialog-3.0"):Close("Bartender4")
end

function Bartender4:ToggleLock()
	if self.Locked then
		self:Unlock()
	else
		self:Lock()
	end
end

local getSnap, setSnap
do
	function getSnap()
		return Bartender4.db.profile.snapping
	end

	function setSnap(value)
		Bartender4.Bar:ForAll("StopDragging")
		Bartender4.db.profile.snapping = value
		LibStub("AceConfigRegistry-3.0"):NotifyChange("Bartender4")
	end
end

function Bartender4:ShowUnlockDialog()
	if not self.unlock_dialog then
		local f = CreateFrame("Frame", "Bartender4Dialog", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		f:SetFrameStrata("DIALOG")
		f:SetToplevel(true)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:SetClampedToScreen(true)
		f:SetWidth(360)
		f:SetHeight(110)
		f:SetBackdrop{
			bgFile="Interface\\DialogFrame\\UI-DialogBox-Background" ,
			edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			insets = {left = 11, right = 12, top = 12, bottom = 11},
			tileSize = 32,
			edgeSize = 32,
		}
		f:SetPoint("TOP", 0, -50)
		f:Hide()
		f:SetScript('OnShow', function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION) end)
		f:SetScript('OnHide', function() PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT) end)

		f:RegisterForDrag('LeftButton')
		f:SetScript('OnDragStart', function(frame) frame:StartMoving() end)
		f:SetScript('OnDragStop', function(frame) frame:StopMovingOrSizing() end)

		local header = f:CreateTexture(nil, "ARTWORK")
		header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		header:SetWidth(256); header:SetHeight(64)
		header:SetPoint("TOP", 0, 12)

		local title = f:CreateFontString("ARTWORK")
		title:SetFontObject("GameFontNormal")
		title:SetPoint("TOP", header, "TOP", 0, -14)
		title:SetText(L["Bartender4"])

		local desc = f:CreateFontString("ARTWORK")
		desc:SetFontObject("GameFontHighlight")
		desc:SetJustifyV("TOP")
		desc:SetJustifyH("LEFT")
		desc:SetPoint("TOPLEFT", 18, -32)
		desc:SetPoint("BOTTOMRIGHT", -18, 48)
		desc:SetText(L["Bars unlocked. Move them now and click Lock when you are done."])

		local snapping = CreateFrame("CheckButton", "Bartender4Snapping", f, WoW10 and "UICheckButtonTemplate" or "OptionsCheckButtonTemplate")
		_G[snapping:GetName() .. "Text"]:SetText(L["Bar Snapping"])

		snapping:SetScript("OnShow", function(frame)
			frame:SetChecked(getSnap())
		end)

		snapping:SetScript("OnClick", function(frame)
			setSnap(frame:GetChecked())
		end)

		local lockBars = CreateFrame("CheckButton", "Bartender4DialogLock", f, WoW10 and "UIPanelButtonTemplate" or "OptionsButtonTemplate")
		lockBars:SetWidth(150)
		_G[lockBars:GetName() .. "Text"]:SetText(L["Lock"])

		lockBars:SetScript("OnClick", function()
			Bartender4:Lock()
			LibStub("AceConfigRegistry-3.0"):NotifyChange("Bartender4")
		end)

		--position buttons
		snapping:SetPoint("BOTTOMLEFT", 14, 10)
		lockBars:SetPoint("BOTTOMRIGHT", -14, 14)

		self.unlock_dialog = f
	end
	self.unlock_dialog:Show()
end

function Bartender4:HideUnlockDialog()
	if self.unlock_dialog then
		self.unlock_dialog:Hide()
	end
end

function Bartender4:Unlock(fromEditMode)
	if InCombatLockdown() then return end

	if self.Locked then
		self.Locked = false
		Bartender4.Bar:ForAll("Unlock")
		if not fromEditMode then
			self:ShowUnlockDialog()
		else
			self:UpdateSnapFromEditMode()
		end
	end
end

function Bartender4:Lock()
	if not self.Locked then
		self.Locked = true
		Bartender4.Bar:ForAll("Lock")
		self:HideUnlockDialog()
	end
end

function Bartender4:UpdateSnapFromEditMode()
	if EditModeManagerFrame and EditModeManagerFrame.EnableSnapCheckButton then
		setSnap(EditModeManagerFrame.EnableSnapCheckButton:IsControlChecked())
	end
end

Bartender4.Util = {}
function Bartender4.Util:PurgeKey(t, k)
	t[k] = nil
	local c = 42
	repeat
		if t[c] == nil then
			t[c] = nil
		end
		c = c + 1
	until issecurevariable(t, k)
end

function Bartender4.Util:Merge(target, source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:Merge(target[k], v)
		elseif target[k] == nil then
			target[k] = v
		end
	end
	return target
end

Bartender4.Compat = {}
if C_Spell and C_Spell.GetSpellName then
	Bartender4.Compat.GetSpellName = C_Spell.GetSpellName
else
	function Bartender4.Compat.GetSpellName(id)
		return (GetSpellInfo(id))
	end
end

Bartender4.modulePrototype = {}
function Bartender4.modulePrototype:ToggleModule(info, value)
	if value ~= nil then
		self.db.profile.enabled = value
	else
		value = self.db.profile.enabled
	end
	if value and not self:IsEnabled() then
		self:Enable()
	elseif not value and self:IsEnabled() then
		self:Disable()
	end
end

function Bartender4.modulePrototype:ToggleOptions()
	if self.options then
		self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
	end
end

function Bartender4.modulePrototype:OnDisable()
	if not self.bar then return end
	-- assign new config table
	self.bar.config = self.db.profile
	self.bar:Disable()
	self:ToggleOptions()
end

Bartender4:SetDefaultModulePrototype(Bartender4.modulePrototype)

function createLDBLauncher()
	local L_BT_LEFT = L["|cffffff00Click|r to toggle bar lock"]
	local L_BT_RIGHT = L["|cffffff00Right-click|r to open the options menu"]

	local LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject("Bartender4", {
		type = "launcher",
		label = "Bartender4",
		OnClick = function(_, msg)
			if msg == "LeftButton" then
				if Bartender4.Locked then
					Bartender4["Unlock"](Bartender4)
				else
					Bartender4["Lock"](Bartender4)
				end
			elseif msg == "RightButton" then
				if LibStub("AceConfigDialog-3.0").OpenFrames["Bartender4"] then
					LibStub("AceConfigDialog-3.0"):Close("Bartender4")
				else
					LibStub("AceConfigDialog-3.0"):Open("Bartender4")
				end
			end
		end,
		icon = "Interface\\Icons\\INV_Drink_05",
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("Bartender4")
			tooltip:AddLine(L_BT_LEFT)
			tooltip:AddLine(L_BT_RIGHT)
		end,
	})

	if LDBIcon then
		LDBIcon:Register("Bartender4", LDBObj, Bartender4.db.profile.minimapIcon)
	end
end
