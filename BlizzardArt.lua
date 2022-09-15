--[[
	Copyright (c) 2009, CMTitan
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	Based on Nevcairiel's RepXPBar.lua
	All rights to be transferred to Nevcairiel upon inclusion into Bartender4.
	All rights reserved, otherwise.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local WoW10 = select(4, GetBuildInfo()) >= 100000

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

local setmetatable = setmetatable

-- GLOBALS: UIParent

local defaults = { profile = Bartender4:Merge({
	enabled = false,
	leftCap = "DWARF",
	rightCap = "DWARF",
	artLayout = "CLASSIC",
	artSkin = "DWARF",
}, Bartender4.Bar.defaults) }

-- register module
local BlizzardArtMod = Bartender4:NewModule("BlizzardArt", "AceEvent-3.0")

-- create prototype information
local BlizzardArt = setmetatable({}, {__index = Bar})

function BlizzardArtMod:OnInitialize()
	defaults.profile.visibility.possess = false -- Overwrite one of the bar defaults
	self.db = Bartender4.db:RegisterNamespace("BlizzardArt", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function BlizzardArtMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("BlizzardArt", self.db.profile, L["Blizzard Art"], 1), {__index = BlizzardArt})
		self.bar.highLevel = CreateFrame("Frame", nil, self.bar)
		self.bar.highLevel:SetAllPoints(self.bar)
		self.bar.highLevel:SetFrameLevel(4)
		self.bar.leftCap = self.bar.highLevel:CreateTexture("BlizzardArtLeftCap", "ARTWORK")
		self.bar.rightCap = self.bar.highLevel:CreateTexture("BlizzardArtRightCap", "ARTWORK")
		self.bar.barTex0 = self.bar:CreateTexture("BlizzardArtTex0", "ARTWORK")
		self.bar.barTex0:ClearAllPoints()
		self.bar.barTex0:SetHeight(43)
		self.bar.barTex0:SetWidth(256)
		self.bar.barTex0:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 0, -48)
		self.bar.barTex0:SetTexCoord(0.0, 1.0, 0.83203125, 1.0) -- Left quarter of the classic bar
		self.bar.barTex1 = self.bar:CreateTexture("BlizzardArtTex1", "ARTWORK")
		self.bar.barTex1:ClearAllPoints()
		self.bar.barTex1:SetHeight(43)
		self.bar.barTex1:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 256, -48)
		-- Tex1b complements Tex0 and Tex1 into a complete action bar, without the small buttons next to it
		-- It's actually a small repeat of the rightmost 9 pixels of the classic bar
		self.bar.barTex1b = self.bar:CreateTexture("BlizzardArtTex1b", "ARTWORK")
		self.bar.barTex1b:ClearAllPoints()
		self.bar.barTex1b:SetHeight(43)
		self.bar.barTex1b:SetWidth(9)
		self.bar.barTex1b:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 503, -48)
		self.bar.barTex1b:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
		self.bar.barTex1b:SetTexCoord(0.9609375, 0.99609375, 0.08203125, 0.25) -- 9 pixels wide, pixels 246 to 254 of 256, inclusive, to be exact
		self.bar.barTex2 = self.bar:CreateTexture("BlizzardArtTex2", "ARTWORK")
		self.bar.barTex2:ClearAllPoints()
		self.bar.barTex2:SetHeight(43)
		self.bar.barTex2:SetWidth(256)
		self.bar.barTex2:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 512, -48)
		self.bar.barTex3 = self.bar:CreateTexture("BlizzardArtTex3", "ARTWORK")
		self.bar.barTex3:ClearAllPoints()
		self.bar.barTex3:SetHeight(43)
		self.bar.barTex3:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 768, -48)
		self.bar.barTex3b = self.bar:CreateTexture("BlizzardArtTex3b", "ARTWORK")
		-- Tex3b is like Tex1b, but together with Tex2 and Tex3, which would in this case (two action bars) be repeats of Tex0 and Tex1
		self.bar.barTex3b:ClearAllPoints()
		self.bar.barTex3b:SetHeight(43)
		self.bar.barTex3b:SetWidth(9)
		self.bar.barTex3b:SetPoint("BOTTOMLEFT", self.bar, "TOPLEFT", 1015, -48)
		self.bar.barTex3b:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
		self.bar.barTex3b:SetTexCoord(0.9609375, 0.99609375, 0.08203125, 0.25) -- 9 pixels wide, pixels 246 to 254 of 256, inclusive, to be exact

		if WoW10 then
			self.bar.nineSliceParent = CreateFrame("Frame", nil, self.bar)
			self.bar.nineSliceParent:SetFrameLevel(4)
			self.bar.nineSliceParent:SetPoint("TOPLEFT", self.bar, "TOPLEFT", 9, -8)
			self.bar.nineSliceParent:SetSize(562, 45)

			self.bar.nineSliceBorder = CreateFrame("Frame", nil, self.bar.nineSliceParent, "BT4ArtBarBorderArtTemplate")
			self.bar.nineSliceBorder:SetFrameLevel(52)
			self.bar.nineSliceBorder:SetPoint("TOPLEFT", self.bar.nineSliceParent, "TOPLEFT", -4, 4)
			self.bar.nineSliceBorder:SetPoint("BOTTOMRIGHT", self.bar.nineSliceParent, "BOTTOMRIGHT", 7, -7)
			self.bar.nineSliceBorder:Show()

			self.bar.nineSliceBackground = CreateFrame("Frame", nil, self.bar.nineSliceParent, "BT4ArtBarBackgroundTemplate")
			self.bar.nineSliceBackground.Center:SetColorTexture(0,0,0,0.2) -- fixup the slice background
			self.bar.nineSliceBackground:SetAllPoints()
			self.bar.nineSliceBackground:Show()
		end
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()

	if WoW10 then
		self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "ApplyConfig")
	end
end

function BlizzardArtMod:ApplyConfig()
	self.bar:ApplyConfig()
end

function BlizzardArt:ApplyConfig()
	local config = BlizzardArtMod.db.profile
	Bar.ApplyConfig(self, config)

	if not config.position.x then
		self:ClearAllPoints()
		self:SetPoint("BOTTOM", UIParent, "BOTTOM", -512, 48)
	end

	-- MODERN is only supported in WoW 10.0+
	if not WoW10 and config.artLayout == "MODERN" then
		config.artLayout = "CLASSIC"
	end

	if WoW10 and config.artLayout == "MODERN" then
		-- hide all the classic artwork
		self.barTex0:Hide()
		self.barTex1:Hide()
		self.barTex1b:Hide()
		self.barTex2:Hide()
		self.barTex3:Hide()
		self.barTex3b:Hide()

		local factionGroup = UnitFactionGroup("player")
		if ( factionGroup == "Horde" ) then
			self.leftCap:SetAtlas("ui-hud-actionbar-wyvern-left")
			self.rightCap:SetAtlas("ui-hud-actionbar-wyvern-right")
		else
			self.leftCap:SetAtlas("ui-hud-actionbar-gryphon-left")
			self.rightCap:SetAtlas("ui-hud-actionbar-gryphon-right")
		end

		self.leftCap:SetSize(104.5, 98)
		self.leftCap:ClearAllPoints()
		self.leftCap:SetPoint("BOTTOMRIGHT", self.nineSliceParent, "BOTTOMLEFT", 9, -22)
		self.rightCap:SetTexCoord(0,1,0,1)
		self.rightCap:SetSize(104.5, 98)
		self.rightCap:ClearAllPoints()
		self.rightCap:SetPoint("BOTTOMLEFT", self.nineSliceParent, "BOTTOMRIGHT", -8, -22)

		-- show the modern NineSlice border/background
		self.nineSliceParent:Show()

		-- show button art
		if not self.modernButtonArt then
			self.modernButtonArt = {}
			for i=1,12 do
				self.modernButtonArt[i] = CreateFrame("Frame", nil, self.nineSliceParent)
				self.modernButtonArt[i]:SetSize(45,45)
				self.modernButtonArt[i].SlotArt = self.modernButtonArt[i]:CreateTexture(nil, "BACKGROUND")
				self.modernButtonArt[i].SlotArt:SetAllPoints()
				self.modernButtonArt[i].SlotArt:SetAtlas("ui-hud-actionbar-iconframe-slot")
				if i < 12 then
					self.modernButtonArt[i].Divider = CreateFrame("Frame", nil, self.modernButtonArt[i], "BT4ArtBarButtonRightDivider")
					self.modernButtonArt[i].Divider:SetPoint("LEFT", self.modernButtonArt[i], "RIGHT", -5, 0)
					self.modernButtonArt[i].Divider:SetPoint("TOP")
					self.modernButtonArt[i].Divider:SetPoint("BOTTOM")
				end
			end

			local layout = GridLayoutUtil.CreateStandardGridLayout(12, 2, 2, 1, 1)
			GridLayoutUtil.ApplyGridLayout(self.modernButtonArt, AnchorUtil.CreateAnchor("TOPLEFT", self.nineSliceParent, "TOPLEFT"), layout)
		end

		self:SetSize(577, 61)
	else
		self.barTex0:Show()
		self.barTex1:Show()

		if WoW10 then
			self.nineSliceParent:Hide()
		end

		self.leftCap:SetHeight(128)
		self.leftCap:SetWidth(128)
		self.leftCap:ClearAllPoints()
		self.leftCap:SetPoint("BOTTOM", self, "TOPLEFT", -32, -48)
		self.rightCap:SetHeight(128)
		self.rightCap:SetWidth(128)
		self.rightCap:SetTexCoord(1.0, 0.0, 0.0, 1.0) -- Horizontal mirror
		self.rightCap:ClearAllPoints()

		local showKeyRing = KeyRingButton and GetCVarBool("showKeyring") or nil

		if config.artSkin == "HUMAN" then -- Lions on the background of buttons
			self.barTex0:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Human")
			self.barTex1:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Human")
			if config.artLayout ~= "CLASSIC" then -- Human skin is actually outdated, for classic layout the second half is Dwarf anyway
				self.barTex2:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Human")
				self.barTex3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Human")
			else
				self.barTex2:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
				self.barTex3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
			end
		else -- Or griffins (default)
			self.barTex0:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
			self.barTex1:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
			self.barTex2:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
			self.barTex3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
		end

		if config.leftCap == "NONE" then -- No left cap
			self.leftCap:Hide()
		elseif config.leftCap == "HUMAN" then -- Lion
			self.leftCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human")
			self.leftCap:Show()
		else -- Griffin (default)
			self.leftCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf")
			self.leftCap:Show()
		end
		if config.rightCap == "NONE" then -- No right cap
			self.rightCap:Hide()
		elseif config.rightCap == "HUMAN" then -- Lion
			self.rightCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human")
			self.rightCap:Show()
		else -- Griffin (default)
			self.rightCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf")
			self.rightCap:Show()
		end

		if MainMenuBarPerformanceBarFrame then
			MainMenuBarPerformanceBarFrame:Hide()
		end
		if config.artLayout == "CLASSIC" then -- Classical layout: one bar, micro menu and bags
			self:SetSize(1024, 53)
			self.barTex1:SetWidth(256)
			self.barTex1:SetTexCoord(0.0, 1.0, 0.58203125, 0.75) -- Second quarter of classic bar
			self.barTex1b:Hide()
			self.barTex2:Show()
			self.barTex3:Show()
			self.barTex3:SetWidth(256)

			self.barTex3b:Hide()
			self.rightCap:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 992, -48)

			if showKeyRing then
				self.barTex3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-KeyRing");
				self.barTex3:SetTexCoord(0, 1, 0.1640625, 0.5);
				self.barTex2:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-KeyRing");
				self.barTex2:SetTexCoord(0, 1, 0.6640625, 1);
			else
				self.barTex3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
				self.barTex3:SetTexCoord(0.0, 1.0, 0.08203125, 0.25)
				self.barTex2:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf")
				self.barTex2:SetTexCoord(0.0, 1.0, 0.33203125, 0.5)
			end

			if MainMenuBarPerformanceBarFrame and GetClassicExpansionLevel and GetClassicExpansionLevel() < 2 then
				MainMenuBarPerformanceBarFrame:SetParent(self)
				MainMenuBarPerformanceBarFrame:ClearAllPoints()
				if showKeyRing then
					MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 774, -58)
				else
					MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 781, -58)
				end
				MainMenuBarPerformanceBarFrame:Show()
				MainMenuBarPerformanceBarFrame:SetFrameLevel(self:GetFrameLevel() - 1)
			end
		elseif config.artLayout == "TWOBAR" then -- Two bars next to each other
			self:SetSize(1024, 53)
			self.barTex1:SetWidth(247) -- Tex1b will complement the other 9 pixels
			self.barTex1:SetTexCoord(0.0, 0.96484375, 0.58203125, 0.75) -- First 247 pixels of second quarter of classic bar
			self.barTex1b:Show() -- Tex1b is used here
			self.barTex2:Show()
			self.barTex2:SetTexCoord(0.0, 1.0, 0.83203125, 1.0) -- First quarter of classic bar, or: repeat of Tex0
			self.barTex3:Show()
			self.barTex3:SetWidth(247) -- Tex3 will complement the other 9 pixels
			self.barTex3:SetTexCoord(0.0, 0.96484375,  0.58203125, 0.75) -- First 247 pixels of second quarter of classic bar, or: repeat of Tex1
			self.barTex3b:Show() -- Tex3b is used here
			self.rightCap:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 992, -48)
		else -- Only one bar
			self:SetSize(512, 53) -- Half size, since it's only one bar wide
			self.barTex1:SetWidth(247) -- Tex1b will complement the other 9 pixels
			self.barTex1:SetTexCoord(0.0, 0.96484375, 0.58203125, 0.75) -- First 247 pixels of second quarter of classic bar
			self.barTex1b:Show() -- Tex1b is used here
			self.barTex2:Hide() -- Hide second half
			self.barTex3:Hide()
			self.barTex3b:Hide()
			self.rightCap:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 480, -48)
		end
	end
end

BlizzardArt.ClickThroughSupport = false
function BlizzardArt:ControlClickThrough()
end
