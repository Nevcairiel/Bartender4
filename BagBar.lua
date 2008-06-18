--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
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
		self.bar = setmetatable(Bartender4.ButtonBar:Create("Bag", self.db.profile), {__index = BagBar})
		
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

local button_count = 5
function BagBarMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()
		self.optionobject.table.general.args.rows.max = button_count
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Bag Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
		}
		self.optionobject:AddElement("general", "enabled", enabled)
		
		local onebag = {
			type = "toggle",
			order = 80,
			name = L["One Bag"],
			desc = L["Only show one Bag Button in the BagBar."],
			get = function() return self.db.profile.onebag end,
			set = function(info, state) self.db.profile.onebag = state; self.bar:FeedButtons(); self.bar:UpdateButtonLayout() end,
		}
		self.optionobject:AddElement("general", "onebag", onebag)
		
		local keyring = {
			type = "toggle",
			order = 80,
			name = L["Keyring"],
			desc = L["Show the keyring button."],
			get = function() return self.db.profile.keyring end,
			set = function(info, state) self.db.profile.keyring = state; self.bar:FeedButtons(); self.bar:UpdateButtonLayout() end,
		}
		self.optionobject:AddElement("general", "keyring", keyring)
		
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
			name = L["Bag Bar"],
			desc = L["Configure the Bag Bar"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("Bag", self.options)
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
	self:FeedButtons()
	self:UpdateButtonLayout()
end

function clearSetPoint(btn, ...)
	btn:ClearAllPoints()
	btn:SetPoint(...)
end

BagBar.button_width = 37
BagBar.button_height = 37
function BagBar:FeedButtons()
	local count = 1
	if self.buttons then
		while next(self.buttons) do
			local btn = table.remove(self.buttons)
			btn:Hide()
			btn:SetParent(UIParent)
			btn:ClearSetPoint("CENTER")
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
		count = count + 1
	end
	
	if not self.config.onebag then
		table_insert(self.buttons, CharacterBag3Slot) 
		table_insert(self.buttons, CharacterBag2Slot) 
		table_insert(self.buttons, CharacterBag1Slot) 
		table_insert(self.buttons, CharacterBag0Slot)
		count = count + 4
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
	
	button_count = count
	if BagBarMod.optionobject then
		BagBarMod.optionobject.table.general.args.rows.max = count
	end
end

