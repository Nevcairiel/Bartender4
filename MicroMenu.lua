local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local MicroMenuMod = Bartender4:NewModule("MicroMenu", "AceHook-3.0")

-- fetch upvalues
local ActionBars = Bartender4:GetModule("ActionBars")
local Bar = Bartender4.Bar.prototype

-- create prototype information
local MicroMenuBar = setmetatable({}, {__index = Bar})

local table_insert = table.insert

local defaults = { profile = Bartender4:Merge({
	enabled = true,
	vertical = false,
	visibility = {
		possess = false,
	},
}, Bartender4.Bar.defaults) }

function MicroMenuMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("MicroMenu", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

local noopFunc = function() end

function MicroMenuMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("MicroMenu", self.db.profile, L["Micro Menu"]), {__index = MicroMenuBar})
		local buttons = {}
		table_insert(buttons, CharacterMicroButton)
		table_insert(buttons, SpellbookMicroButton)
		table_insert(buttons, TalentMicroButton)
		table_insert(buttons, AchievementMicroButton)
		table_insert(buttons, QuestLogMicroButton)
		table_insert(buttons, SocialsMicroButton)
		table_insert(buttons, PVPMicroButton)
		table_insert(buttons, LFGMicroButton)
		table_insert(buttons, MainMenuMicroButton)
		table_insert(buttons, HelpMicroButton)
		self.bar.buttons = buttons
		
		self:RawHook("UpdateTalentButton", noopFunc, true)
		
		for i,v in pairs(buttons) do
			v:SetParent(self.bar)
			v:Show()
			v:SetFrameLevel(self.bar:GetFrameLevel() + 1)
		end
		
		-- TODO: real start position
		self.bar:SetPoint("CENTER")
	end
	self.bar:Enable()
	self:ToggleOptions()
	self.bar:ApplyConfig(self.db.profile)
end

function MicroMenuMod:OnDisable()
	if not self.bar then return end
	self.bar:Disable()
	self:ToggleOptions()
end

function MicroMenuMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function MicroMenuBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)
	self:PerformLayout()
end

function MicroMenuBar:PerformLayout()
	if self.config.vertical then
		-- TODO: vertical
	else
		self:SetSize(252, 45)
		self.buttons[1]:ClearAllPoints()
		self.buttons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, 18)
		for i = 2, #self.buttons do
			self.buttons[i]:ClearAllPoints()
			self.buttons[i]:SetPoint("TOPLEFT", self.buttons[i-1], "TOPRIGHT", -4, 0)
		end
	end
end
