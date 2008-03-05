--[[ $Id: StanceBar.lua 61678 2008-02-17 01:37:33Z nevcairiel $ ]]

-- register module
local PetBarMod = Bartender4:NewModule("PetBar")

-- fetch upvalues
local ActionBars = Bartender4:GetModule("ActionBars")
local ButtonBar = Bartender4.ButtonBar.prototype

-- create prototype information
local PetBar = setmetatable({}, {__index = ButtonBar})
local PetButtonPrototype = CreateFrame("CheckButton")
local PetButton_MT = {__index = PetButtonPrototype}

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	scale = 1.0,
}, Bartender4.ButtonBar.defaults) }

function PetBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("PetBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
	self:SetupOptions()
end

function PetBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Pet", nil, self.db.profile), {__index = PetBar})
		
		local buttons = {}
		for i=1,10 do
			buttons[i] = self:CreatePetButton(i)
		end
		self.bar.buttons = buttons
		
		-- TODO: real positioning
		self.bar:ClearSetPoint("CENTER")
		
		self.bar:SetScript("OnEvent", PetBar.OnEvent)
		
		self.bar:SetAttribute("unit", "pet")
	end
	self.bar.disabled = nil
	
	RegisterUnitWatch(self.bar, false)
	
	self.bar:RegisterEvent("PLAYER_CONTROL_LOST")
	self.bar:RegisterEvent("PLAYER_CONTROL_GAINED")
	self.bar:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	self.bar:RegisterEvent("UNIT_PET")
	self.bar:RegisterEvent("UNIT_FLAGS")
	self.bar:RegisterEvent("UNIT_AURA")
	self.bar:RegisterEvent("PET_BAR_UPDATE")
	self.bar:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self.bar:RegisterEvent("PET_BAR_SHOWGRID")
	self.bar:RegisterEvent("PET_BAR_HIDEGRID")
	
	self:ApplyConfig()
	self:SetupOptions()
end

function PetBarMod:OnDisable()
	if not self.bar then return end
	self.bar.disabled = true
	
	UnregisterUnitWatch(self.bar)
	
	self.bar:UnregisterAllEvents()
	self.bar:Hide()
	self:SetupOptions()
end

function PetBarMod:CreatePetButton(id)
	local name = "BT4PetButton" .. id
	local button = setmetatable(CreateFrame("CheckButton", name, self.bar, "PetActionButtonTemplate"), PetButton_MT)
	button:SetFrameStrata("MEDIUM")
	button:SetID(id)
	button:UnregisterAllEvents()
	button:SetScript("OnEvent", nil)
	button.id = id
	button.flash = _G[name .. "Flash"]
	button.cooldown = _G[name .. "Cooldown"]
	button.icon = _G[name .. "Icon"]
	button.autocastable = _G[name .. "AutoCastable"]
	button.autocast = _G[name .. "AutoCast"]
	
	button.normalTexture = button:GetNormalTexture()
	button.pushedTexture = button:GetPushedTexture()
	button.highlightTexture = button:GetHighlightTexture()
	
	button.textureCache = {}
	button.textureCache.pushed = button.pushedTexture:GetTexture()
	button.textureCache.highlight = button.highlightTexture:GetTexture()
	
	return button
end

function PetBarMod:SetupOptions()
	if not self.options then
		self.options = Bartender4.ButtonBar.prototype:GetOptionObject()
		
		local enabled = {
			type = "toggle",
			order = 1,
			name = "Enabled",
			desc = "Enable the PetBar",
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
		ActionBars.options.args["Pet"] = {
				order = 30,
				type = "group",
				name = "Pet Bar",
				desc = "Configure the Pet Bar",
				childGroups = "tab",
			}
	end
	ActionBars.options.args["Pet"].args = self:IsEnabled() and self.options.table or self.disabledoptions
end

function PetBarMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

function PetButtonPrototype:Update()
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	
	if not isToken then
		self.icon:SetTexture(texture)
		self.tooltipName = name;
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end
	
	self.isToken = isToken
	self.tooltipSubtext = subtext
	self:SetChecked(isActive and 1 or 0)
	if autoCastAllowed then
		self.autocastable:Show()
	else
		self.autocastable:Hide()
	end
	if autoCastEnabled then
		self.autocast:Show()
	else
		self.autocast:Hide()
	end
	
	if texture then
		if GetPetActionsUsable() then
			SetDesaturation(self.icon, nil)
		else
			SetDesaturation(self.icon, 1)
		end
		self.icon:Show()
		self.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		self.normalTexture:SetTexCoord(0, 0, 0, 0)
		self:ShowButton()
	else
		self.icon:Hide()
		self.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot")
		self.normalTexture:SetTexCoord(-0.1, 1.1, -0.1, 1.12)
		self:HideButton()
	end
	self:UpdateCooldown()
end

function PetButtonPrototype:ShowButton()
	if self.overlay then return end
	
	self.pushedTexture:SetTexture(self.textureCache.pushed)
	self.highlightTexture:SetTexture(self.textureCache.highlight)
end

function PetButtonPrototype:HideButton()
	if self.overlay then return end
	
	self.pushedTexture:SetTexture("")
	self.highlightTexture:SetTexture("")
end

function PetButtonPrototype:UpdateCooldown()
	local start, duration, enable = GetPetActionCooldown(self.id)
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
end

-- import style function
PetButtonPrototype.ApplyStyle = Bartender4.ButtonStyle.ApplyStyle

function PetButtonPrototype:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

PetBar.button_width = 30
PetBar.button_height = 30
function PetBar:OnEvent(event, arg1)
	if event == "PET_BAR_UPDATE" or 
		(event == "UNIT_PET" and arg1 == "player") or
		((event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 == "pet") or
		event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED"
	then
		self:ForAll("Update")
	elseif event == "PET_BAR_UPDATE_COOLDOWN" then
		self:ForAll("UpdateCooldown")
	elseif event == "PET_BAR_SHOWGRID" then
		self:ForAll("ShowGrid")
	elseif event == "PET_BAR_HIDEGRID" then
		self:ForAll("HideGrid")
	end
end

function PetBar:ApplyConfig()
	ButtonBar.ApplyConfig(self)
	self:UpdateButtonLayout()
	self:ForAll("Update")
	self:ForAll("ApplyStyle", self.config.style)
end

function PetBar:Unlock()
	UnregisterUnitWatch(self)
	ButtonBar.Unlock(self)
end

function PetBar:Lock()
	ButtonBar.Lock(self)
	RegisterUnitWatch(self, false)
end
