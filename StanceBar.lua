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

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	scale = 1.5,
}, Bartender4.ButtonBar.defaults) }

function StanceBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("StanceBar", defaults)
	
	self:SetupOptions()
end

function StanceBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Stance", nil, self.db.profile), {__index = StanceBar})
		
		self.bar:ClearSetPoint("CENTER")
		self.bar:ApplyConfig()
		self.bar:SetScript("OnEvent", StanceBar.OnEvent)
	end
	self.bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self.bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self.bar:RegisterEvent("SPELL_UPDATE_USABLE")
	self.bar:RegisterEvent("PLAYER_AURAS_CHANGED")
	self.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function StanceBarMod:OnDisable()
	if not self.bar then return end
	self.bar:UnregisterAllEvents()
	self.bar:Hide()
end

function StanceBarMod:SetupOptions()
	self.options = Bartender4.ButtonBar.prototype:GetOptionObject()
	
	ActionBars.options.args["stance"] = {
			order = 30,
			type = "group",
			name = "Stance Bar",
			desc = "Configure  the Stance Bar",
			childGroups = "tab",
			disabled = function() return GetNumShapeshiftForms() == 0 end,
		}
	ActionBars.options.args["stance"].args = self.options.table
end

function StanceBarMod:ApplyConfig()
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

function StanceButtonPrototype:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
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
