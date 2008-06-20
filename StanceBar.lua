--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local StanceBarMod = Bartender4:NewModule("StanceBar", "AceEvent-3.0")

-- fetch upvalues
local ActionBars = Bartender4:GetModule("ActionBars")
local ButtonBar = Bartender4.ButtonBar.prototype

-- create prototype information
local StanceBar = setmetatable({}, {__index = ButtonBar})
local StanceButtonPrototype = CreateFrame("CheckButton")
local StanceButton_MT = {__index = StanceButtonPrototype}

local format = string.format

local LBF = LibStub("LibButtonFacade", true)
local KeyBound = LibStub("LibKeyBound-1.0")

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	scale = 1.5,
}, Bartender4.ButtonBar.defaults) }

function StanceBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StanceBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function StanceBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("StanceBar", self.db.profile, L["Stance Bar"]), {__index = StanceBar})
		
		self.bar:ClearSetPoint("CENTER")
		self.bar:SetScript("OnEvent", StanceBar.OnEvent)
	end
	self.bar.disabled = nil
	
	self:ToggleOptions()
	self.bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self.bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self.bar:RegisterEvent("SPELL_UPDATE_USABLE")
	self.bar:RegisterEvent("PLAYER_AURAS_CHANGED")
	self.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	self.bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
	self.bar:ApplyConfig(self.db.profile)
end

function StanceBarMod:OnDisable()
	if not self.bar then return end
	self.bar.disabled = true
	self.bar:UnregisterAllEvents()
	self.bar:Hide()
	self:ToggleOptions()
end

local button_count = 10
function StanceBarMod:SetupOptions()
	if not self.options then
		self.optionobject = Bartender4.ButtonBar.prototype:GetOptionObject()
		self.optionobject.table.general.args.rows.max = button_count
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the StanceBar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
		}
		self.optionobject:AddElement("general", "enabled", enabled)
		
		self.disabledoptions = {
			general = {
				type = "group",
				name = L["General Settings"],
				cmdInline = true,
				order = 1,
				args = {
					enabled = enabled,
				}
			}
		}
		
		self.options = {
			order = 30,
			type = "group",
			name = L["Stance Bar"],
			desc = L["Configure  the Stance Bar"],
			childGroups = "tab",
			disabled = function(info) return GetNumShapeshiftForms() == 0 end,
		}
		Bartender4:RegisterBarOptions("StanceBar", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end

function StanceBarMod:ToggleOptions()
	if self.options then
		self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
	end
end

function StanceBarMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
	
	if GetNumShapeshiftForms() == 0 then
		self:Disable()
	end
end

function StanceBarMod:ReassignBindings()
	if InCombatLockdown() then return end
	if not self.bar or not self.bar.buttons then return end
	ClearOverrideBindings(self.bar)
	for i = 1, min(#self.bar.buttons, 10) do
		local button, real_button = ("SHAPESHIFTBUTTON%d"):format(i), ("BT4StanceButton%d"):format(i)
		for k=1, select('#', GetBindingKey(button)) do
			local key = select(k, GetBindingKey(button))
			SetOverrideBindingClick(self.bar, false, key, real_button)
		end
	end
end

function StanceButtonPrototype:Update()
	if not self:IsShown() then return end
	local id = self:GetID()
	local texture, name, isActive, isCastable = GetShapeshiftFormInfo(id)
	
	self.icon:SetTexture(texture)
	
	-- manage cooldowns
	if texture then
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
	local start, duration, enable = GetShapeshiftFormCooldown(id)
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	
	if isActive then
		self:SetChecked(1)
	else
		self:SetChecked(0)
	end
	
	if isCastable then
		self.icon:SetVertexColor(1.0, 1.0, 1.0)
	else
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

function StanceButtonPrototype:GetHotkey()
	local key = GetBindingKey(format("SHAPESHIFTBUTTON%d", self:GetID())) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound:ToShortKey(key)
end

function StanceButtonPrototype:GetBindings()
	local keys, binding = ""
	
	binding = format("SHAPESHIFTBUTTON%d", self:GetID())
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ', ' 
		end
		keys = keys .. GetBindingText(hotKey,'KEY_')
	end
	
	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ', ' 
		end
		keys = keys.. GetBindingText(hotKey,'KEY_')
	end

	return keys
end

function StanceButtonPrototype:SetKey(key)
	SetBinding(key, format("SHAPESHIFTBUTTON%d", self:GetID()))
end

local actionTmpl = "Stance Button %d (%s)"
function StanceButtonPrototype:GetActionName()
	local id = self:GetID()
	return format(actionTmpl, id, select(2, GetShapeshiftFormInfo(id)))
end


function StanceButtonPrototype:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

local function onEnter(self, ...)
	self:OnEnter(...)
	KeyBound:Set(self)
end

function StanceBarMod:CreateStanceButton(id)
	local button = setmetatable(CreateFrame("CheckButton", "BT4StanceButton" .. id, self.bar, "ShapeshiftButtonTemplate"), StanceButton_MT)
	button:SetID(id)
	button.icon = _G[button:GetName() .. "Icon"]
	button.cooldown = _G[button:GetName() .. "Cooldown"]
	button.normalTexture = button:GetNormalTexture()
	button.normalTexture:SetTexture("")
--	button.checkedTexture = button:GetCheckedTexture()
--	button.checkedTexture:SetTexture("")
	
	button.OnEnter = button:GetScript("OnEnter")
	button:SetScript("OnEnter", onEnter)
	
	if LBF then
		local group = self.bar.LBFGroup
		button.LBFButtonData = {
			Button = button
		}
		group:AddButton(button, button.LBFButtonData)
	end
	
	return button
end

function StanceBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)
	self:UpdateStanceButtons()
	self:ForAll("ApplyStyle", self.config.style)
end

StanceBar.button_width = 30
StanceBar.button_height = 30
function StanceBar:UpdateStanceButtons()
	local buttons = self.buttons or {}
	
	local num_stances = GetNumShapeshiftForms()
	
	local updateBindings = (num_stances > #buttons)
	
	for i = (#buttons+1), num_stances do
		buttons[i] = StanceBarMod:CreateStanceButton(i)
	end
	
	for i = 1, num_stances do
		buttons[i]:Show()
		buttons[i]:Update()
	end
	
	for i = num_stances+1, #buttons do
		buttons[i]:Hide()
	end
	
	button_count = num_stances
	if StanceBarMod.optionobject then
		StanceBarMod.optionobject.table.general.args.rows.max = num_stances
	end
	
	self.buttons = buttons
	
	self:UpdateButtonLayout()
	if updateBindings then
		StanceBarMod:ReassignBindings()
	end
	self.disabled = (GetNumShapeshiftForms() == 0) and true or nil
end

function StanceBar:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORMS" and not InCombatLockdown() then
		self:UpdateStanceButtons()
	else
		self:ForAll("Update")
	end
end
