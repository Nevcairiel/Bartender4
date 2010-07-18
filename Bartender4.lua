--[[
	Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local AceAddon = LibStub("AceAddon-3.0")
Bartender4 = AceAddon:NewAddon("Bartender4", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local defaults = {
	profile = {
		tooltip = "enabled",
		buttonlock = false,
		outofrange = "button",
		colors = { range = { r = 0.8, g = 0.1, b = 0.1 }, mana = { r = 0.5, g = 0.5, b = 1.0 } },
		selfcastmodifier = true,
		focuscastmodifier = true,
		selfcastrightclick = false,
		snapping = true,
		blizzardVehicle = false,
		minimapIcon = {},
	}
}

Bartender4.CONFIG_VERSION = 3

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")

	self:SetupOptions()

	self.Locked = true
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatLockdown")

	self:HideBlizzard()
	self:UpdateBlizzardVehicle()

	if LDB then
		createLDBLauncher()
	end

	BINDING_HEADER_Bartender4 = "Bartender4"
	BINDING_CATEGORY_Bartender4 = "Action Bars"
	BINDING_NAME_BTTOGGLEACTIONBARLOCK = BINDING_NAME_TOGGLEACTIONBARLOCK
	for i=1,10 do
		if i > 1 then
			_G[('BINDING_CATEGORY_BT4BLANK%d'):format(i)] = "Action Bars" -- myBindings2 compat
			_G[('BINDING_HEADER_BT4BLANK%d'):format(i)] = "Bartender4 " .. L["Bar %s"]:format(i)
		end
		for k=1,12 do
			_G[("BINDING_NAME_CLICK BT4Button%d:LeftButton"):format(((i-1)*12)+k)] = ("Bartender4 %s %s"):format(L["Bar %s"]:format(i), L["Button %s"]:format(k))
		end
	end
	BINDING_HEADER_BT4PET = "Bartender4 " .. L["Pet Bar"]
	BINDING_CATEGORY_BT4PET = "Action Bars"
	BINDING_HEADER_BT4STANCE = "Bartender4 " .. L["Stance Bar"]
	BINDING_CATEGORY_BT4STANCE = "Action Bars"
	for k=1,10 do
		_G[("BINDING_NAME_CLICK BT4PetButton%d:LeftButton"):format(k)] = ("Bartender4 %s %s"):format(L["Pet Bar"], L["Button %s"]:format(k))
		_G[("BINDING_NAME_CLICK BT4StanceButton%d:LeftButton"):format(k)] = ("Bartender4 %s %s"):format(L["Stance Bar"], L["Button %s"]:format(k))
	end
end

function Bartender4:HideBlizzard()
	--MultiActionBar_Update = function() end
	MultiActionBar_UpdateGrid = function() end

	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		_G["ActionButton" .. i]:Hide()
		_G["ActionButton" .. i]:UnregisterAllEvents()

		_G["MultiBarBottomLeftButton" .. i]:Hide()
		_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()

		_G["MultiBarBottomRightButton" .. i]:Hide()
		_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()

		_G["MultiBarRightButton" .. i]:Hide()
		_G["MultiBarRightButton" .. i]:UnregisterAllEvents()

		_G["MultiBarLeftButton" .. i]:Hide()
		_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
	end
	--UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['ShapeshiftBarFrame'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['PossessBarFrame'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['PETACTIONBAR_YPOS'] = nil

	MainMenuBar:UnregisterAllEvents()
	MainMenuBar:Hide()

	--MainMenuBarArtFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	--MainMenuBarArtFrame:UnregisterEvent("BAG_UPDATE")
	MainMenuBarArtFrame:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	--MainMenuBarArtFrame:UnregisterEvent("KNOWN_CURRENCY_TYPES_UPDATE")
	--MainMenuBarArtFrame:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	MainMenuBarArtFrame:UnregisterEvent("ADDON_LOADED")
	--MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERING_VEHICLE")
	--MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERED_VEHICLE")
	--MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITING_VEHICLE")
	--MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITED_VEHICLE")
	MainMenuBarArtFrame:Hide()

	--MainMenuExpBar:UnregisterAllEvents()
	--MainMenuExpBar:Hide()

	ShapeshiftBarFrame:UnregisterAllEvents()
	ShapeshiftBarFrame:Hide()

	BonusActionBarFrame:UnregisterAllEvents()
	BonusActionBarFrame:Hide()

	PossessBarFrame:UnregisterAllEvents()
	PossessBarFrame:Hide()

	if PlayerTalentFrame then
		PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	else
		hooksecurefunc('TalentFrame_LoadUI', function() PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED') end)
	end
end

--[[ function Bartender4:OnEnable()
	--
end
--]]

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

	for k,v in AceAddon:IterateModulesOfAddon(self) do
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

function Bartender4:UpdateBlizzardVehicle()
	if self.db.profile.blizzardVehicle then
		MainMenuBarArtFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
		MainMenuBarArtFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
		MainMenuBarArtFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
		MainMenuBarArtFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
		MainMenuBarArtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		local vehicleModule = Bartender4:GetModule("Vehicle", true)
		vehicleModule:Disable()
		vehicleModule.blizzardVehicle = true
		
		RegisterStateDriver(MainMenuBar, "visibility", "hide")
		RegisterStateDriver(ShapeshiftBarFrame, "visibility", "hide")
		RegisterStateDriver(PossessBarFrame, "visibility", "hide")

		if not self.vehicleController then
			self.vehicleController = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
			self.vehicleController:SetAttribute("_onstate-vehicle", [[
				if newstate == "vehicle" then
					for i=1,6 do
						local button, vbutton = ("ACTIONBUTTON%d"):format(i), ("VehicleMenuBarActionButton%d"):format(i)
						for k=1,select('#', GetBindingKey(button)) do
							local key = select(k, GetBindingKey(button))
							self:SetBindingClick(true, key, vbutton)
						end
					end
				else
					self:ClearBindings()
				end
			]])
		end
		RegisterStateDriver(self.vehicleController, "vehicle", "[vehicleui]vehicle;novehicle")
		local btn = "VehicleMenuBarActionButton%d"
		for i=1,6 do
			local name = btn:format(i)
			local button = _G[name]
			button.UpdateUsable = Bartender4.Button.prototype.UpdateUsable
			button:SetScript("OnUpdate", Bartender4.Button.onUpdate)
			button.icon = _G[("%sIcon"):format(name)]
			button.border = _G[("%sBorder"):format(name)]
			button.cooldown = _G[("%sCooldown"):format(name)]
			button.macroName = _G[("%sName"):format(name)]
			button.hotkey = _G[("%sHotKey"):format(name)]
			button.count = _G[("%sCount"):format(name)]
			button.flash = _G[("%sFlash"):format(name)]
			button.BT4init = true
			button:SetParent(VehicleMenuBarActionButtonFrame)
		end
	else
		MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERING_VEHICLE")
		MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERED_VEHICLE")
		MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITING_VEHICLE")
		MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITED_VEHICLE")
		MainMenuBarArtFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")

		local vehicleModule = Bartender4:GetModule("Vehicle")
		vehicleModule.blizzardVehicle = nil
		if vehicleModule.db and vehicleModule.db.profile.enabled then
			vehicleModule:Enable()
		end
		UnregisterStateDriver(MainMenuBar, "visibility")
		UnregisterStateDriver(ShapeshiftBarFrame, "visibility")
		UnregisterStateDriver(PossessBarFrame, "visibility")
		if self.vehicleController then
			UnregisterStateDriver(self.vehicleController, "vehicle")
		end
		local btn = "VehicleMenuBarActionButton%d"
		for i=1,6 do
			local name = btn:format(i)
			local button = _G[name]
			button.BT4init = nil
			button:SetScript("OnUpdate", ActionButton_OnUpdate)
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
		local f = CreateFrame('Frame', 'Bartender4Dialog', UIParent)
		f:SetFrameStrata('DIALOG')
		f:SetToplevel(true)
		f:EnableMouse(true)
		f:SetClampedToScreen(true)
		f:SetWidth(360)
		f:SetHeight(110)
		f:SetBackdrop{
			bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
			edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
			tile = true,
			insets = {left = 11, right = 12, top = 12, bottom = 11},
			tileSize = 32,
			edgeSize = 32,
		}
		f:SetPoint('TOP', 0, -50)
		f:Hide()
		f:SetScript('OnShow', function() PlaySound('igMainMenuOption') end)
		f:SetScript('OnHide', function() PlaySound('gsTitleOptionExit') end)

		local tr = f:CreateTitleRegion()
		tr:SetAllPoints(f)

		local header = f:CreateTexture(nil, 'ARTWORK')
		header:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Header')
		header:SetWidth(256); header:SetHeight(64)
		header:SetPoint('TOP', 0, 12)

		local title = f:CreateFontString('ARTWORK')
		title:SetFontObject('GameFontNormal')
		title:SetPoint('TOP', header, 'TOP', 0, -14)
		title:SetText(L["Bartender4"])

		local desc = f:CreateFontString('ARTWORK')
		desc:SetFontObject('GameFontHighlight')
		desc:SetJustifyV('TOP')
		desc:SetJustifyH('LEFT')
		desc:SetPoint('TOPLEFT', 18, -32)
		desc:SetPoint('BOTTOMRIGHT', -18, 48)
		desc:SetText(L["Bars unlocked. Move them now and click Lock when you are done."])

		local snapping = CreateFrame('CheckButton', 'Bartender4Snapping', f, 'OptionsCheckButtonTemplate')
		_G[snapping:GetName() .. 'Text']:SetText(L["Bar Snapping"])

		snapping:SetScript('OnShow', function(self)
			self:SetChecked(getSnap())
		end)

		snapping:SetScript('OnClick', function(self)
			setSnap(snapping:GetChecked())
		end)

		local lockBars = CreateFrame('CheckButton', 'Bartender4DialogLock', f, 'OptionsButtonTemplate')
		getglobal(lockBars:GetName() .. 'Text'):SetText(L["Lock"])

		lockBars:SetScript('OnClick', function(self)
			Bartender4:Lock()
			LibStub("AceConfigRegistry-3.0"):NotifyChange("Bartender4")
		end)

		--position buttons
		snapping:SetPoint('BOTTOMLEFT', 14, 10)
		lockBars:SetPoint('BOTTOMRIGHT', -14, 14)

		self.unlock_dialog = f
	end
	self.unlock_dialog:Show()
end

function Bartender4:HideUnlockDialog()
	if self.unlock_dialog then
		self.unlock_dialog:Hide()
	end
end

function Bartender4:Unlock()
	if self.Locked then
		self.Locked = false
		Bartender4.Bar:ForAll("Unlock")
		self:ShowUnlockDialog()
	end
end

function Bartender4:Lock()
	if not self.Locked then
		self.Locked = true
		Bartender4.Bar:ForAll("Lock")
		self:HideUnlockDialog()
	end
end

function Bartender4:Merge(target, source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:Merge(target[k], v)
		elseif not target[k] then
			target[k] = v
		end
	end
	return target
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
