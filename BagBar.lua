--[[ $Id$ ]]

-- register module
local BagBarMod = Bartender4:NewModule("BagBar", "AceHook-3.0")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype
local LBF = LibStub("LibButtonFacade", true)

-- create prototype information
local BagBar = setmetatable({}, {__index = ButtonBar})

local table_insert = table.insert

local defaults = { profile = Bartender4:Merge({ 
	enabled = true,
	keyring = false,
	onebag = false,
}, Bartender4.ButtonBar.defaults) }

function BagBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("BagBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

local noopFunc = function() end

function BagBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Bags", self.db.profile), {__index = BagBar})
		self.bar:FeedButtons()
		
		-- TODO: real start position
		self.bar:SetPoint("CENTER")
	end
	self.bar.disabled = nil
	self:ToggleOptions()
	self.bar:ApplyConfig(self.db.profile)
end

function BagBarMod:OnDisable()
	if not self.bar then return end
	self.bar.disabled = true
	self.bar:Hide()
	self:ToggleOptions()
end

function BagBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function BagBarMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()
		local enabled = {
			type = "toggle",
			order = 1,
			name = "Enabled",
			desc = "Enable the Bag Bar",
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
		}
		self.optionobject:AddElement("general", "enabled", enabled)
		
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
		self.options = {
			order = 30,
			type = "group",
			name = "Bag Bar",
			desc = "Configure the Bag Bar",
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("Bags", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end

function BagBarMod:ToggleOptions()
	if self.options then
		self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
	end
end

function BagBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)
	self:UpdateButtonLayout()
end

function clearSetPoint(btn, ...)
	btn:ClearAllPoints()
	btn:SetPoint(...)
end

BagBar.button_width = 37
BagBar.button_height = 37
function BagBar:FeedButtons()
	if self.buttons then
		while next(self.buttons) do
			local btn = table.remove(self.buttons)
			btn:Hide()
			btn:SetParent(nil)
			if btn ~= KeyRingButton and btn.LBFButtonData then 
				local group = self.LBFGroup
				group:RemoveButton(btn)
			end
		end
	else
		self.buttons = {}
	end
	
	if self.config.keyring then
		table_insert(self.buttons, KeyRingButton)
	end
	
	if not self.config.onebag then
		table_insert(self.buttons, CharacterBag3Slot) 
		table_insert(self.buttons, CharacterBag2Slot) 
		table_insert(self.buttons, CharacterBag1Slot) 
		table_insert(self.buttons, CharacterBag0Slot)
	end
	
	table_insert(self.buttons, MainMenuBarBackpackButton)
	
	for i,v in pairs(self.buttons) do 
		v:SetParent(self)
		v:Show()
		if v ~= KeyRingButton then 
			v:SetNormalTexture("") 
			
			if LBF then
				local group = self.LBFGroup
				if not v.LBFButtonData then
					v.LBFButtonData = {
						Button = v,
						Icon = _G[v:GetName() .. "IconTexture"],
					}
				end
				group:AddButton(v, v.LBFButtonData)
			end
		end
		
		v.ClearSetPoint = clearSetPoint
	end
end

