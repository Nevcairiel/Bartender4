local AceAddon = LibStub("AceAddon-3.0")
Bartender4 = AceAddon:NewAddon("Bartender4", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

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
	}
}

function Bartender4:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Bartender4DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
	
	self:SetupOptions()
	
	self.Locked = true
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CombatLockdown")
	MainMenuBarArtFrame:Hide()
	MainMenuBar:Hide()
	MainMenuBarArtFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	--MainMenuBarArtFrame:UnregisterEvent("BAG_UPDATE")
	MainMenuBarArtFrame:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	--MainMenuBarArtFrame:UnregisterEvent("KNOWN_CURRENCY_TYPES_UPDATE")
	--MainMenuBarArtFrame:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	MainMenuBarArtFrame:UnregisterEvent("ADDON_LOADED")
	MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERING_VEHICLE")
	MainMenuBarArtFrame:UnregisterEvent("UNIT_ENTERED_VEHICLE")
	MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITING_VEHICLE")
	MainMenuBarArtFrame:UnregisterEvent("UNIT_EXITED_VEHICLE")
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
	for k,v in AceAddon:IterateModulesOfAddon(self) do
		v:ToggleModule()
		if v:IsEnabled() and type(v.ApplyConfig) == "function" then
			v:ApplyConfig()
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

local LDB = LibStub("LibDataBroker-1.1", true)
if LDB then
	local L_BT_LEFT = L["|cffffff00Click|r to toggle bar lock"]
	local L_BT_RIGHT = L["|cffffff00Right-click|r to open the options menu"]

	LibStub("LibDataBroker-1.1"):NewDataObject("Bartender4", {
		type = "launcher",
		text = "Bartender4",
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
end
