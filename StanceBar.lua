--[[ $Id$ ]]

-- register module
local StanceBarMod = Bartender4:NewModule("StanceBar")

-- fetch upvalues
local ActionBars = Bartender4:GetModule("ActionBars")
local ButtonBar = Bartender4.ButtonBar.prototype

-- create prototype information
local StanceBar = setmetatable({}, {__index = ButtonBar})
local StanceButtonPrototype = CreateFrame("CheckButton")
local StanceButton_MT = {__index = StanceButtonPrototype}

local format = string.format

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	scale = 1.5,
}, Bartender4.ButtonBar.defaults) }

function StanceBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StanceBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
	self:SetupOptions()
end

function StanceBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Stance", nil, self.db.profile), {__index = StanceBar})
		
		self.bar:ClearSetPoint("CENTER")
		self.bar:ApplyConfig()
		self.bar:SetScript("OnEvent", StanceBar.OnEvent)
	end
	self:SetupOptions()
	self.bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self.bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self.bar:RegisterEvent("SPELL_UPDATE_USABLE")
	self.bar:RegisterEvent("PLAYER_AURAS_CHANGED")
	self.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	self.bar:Show()
end

function StanceBarMod:OnDisable()
	if not self.bar then return end
	self.bar:UnregisterAllEvents()
	self.bar:Hide()
	self:SetupOptions()
end

function StanceBarMod:SetupOptions()
	if not self.options then
		self.options = Bartender4.ButtonBar.prototype:GetOptionObject()
		
		local enabled = {
			type = "toggle",
			order = 1,
			name = "Enabled",
			desc = "Enable the StanceBar",
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
		}
		self.options:AddElement("general", "enabled", enabled)
		
		self.disabledoptions = {
			general = {
				type = "group",
				name = "General Settings",
				cmdInline = true,
				order = 1,
				args = {
					enabled = enabled,
				}
			}
		}
		
		ActionBars.options.args["Stance"] = {
				order = 30,
				type = "group",
				name = "Stance Bar",
				desc = "Configure  the Stance Bar",
				childGroups = "tab",
				disabled = function(info) return GetNumShapeshiftForms() == 0 end,
			}
	end
	
	ActionBars.options.args["Stance"].args = self:IsEnabled() and self.options.table or self.disabledoptions
end

function StanceBarMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

function StanceButtonPrototype:Update()
	if not self:IsShown() then return end
	local id = self:GetID()
	local texture, name, isActive, isCastable = GetShapeshiftFormInfo(id)
	
	self.icon:SetTexture(texture);
	
	-- manage cooldowns
	if texture then
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
	local start, duration, enable = GetShapeshiftFormCooldown(id)
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	
	if ( isActive ) then
		self:SetChecked(1);
	else
		self:SetChecked(0);
	end
	
	if ( isCastable ) then
		self.icon:SetVertexColor(1.0, 1.0, 1.0)
	else
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

StanceButtonPrototype.ApplyStyle = Bartender4.ButtonStyle.ApplyStyle

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
	button.checkedTexture = button:GetCheckedTexture()
	button.checkedTexture:SetTexture("")
	
	button.OnEnter = button:GetScript("OnEnter")
	button:SetScript("OnEnter", onEnter)
	
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
	
	self.buttons = buttons
	
	self:UpdateButtonLayout()
end

function StanceBar:OnEvent(event, ...)
	if InCombatLockdown() then
		self:ForAll("Update")
	else
		self:UpdateStanceButtons()
	end
end
