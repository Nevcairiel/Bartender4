--[[
	Copyright (c) 2009-2022, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- WoW Classic (and 9.x) uses the old code
if select(4, GetBuildInfo()) < 100000 then
	return
end

local function hideActionBarFrame(frame, clearEvents, reanchor, noAnchorChanges)
	if frame then
		if clearEvents then
			frame:UnregisterAllEvents()
		end

		frame:Hide()
		frame:SetParent(Bartender4.UIHider)

		-- setup faux anchors so the frame position data returns valid
		if reanchor and not noAnchorChanges then
			local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
			frame:ClearAllPoints()
			if left and right and top and bottom then
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)
			else
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 10, 10)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", 20, 20)
			end
		elseif not noAnchorChanges then
			frame:ClearAllPoints()
		end
	end
end

function Bartender4:HideBlizzard()
	-- Hidden parent frame
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	self.UIHider = UIHider

	hideActionBarFrame(MultiBarBottomLeft, true)
	hideActionBarFrame(MultiBarBottomRight, true)
	hideActionBarFrame(MultiBarLeft, true)
	hideActionBarFrame(MultiBarRight, true)
	hideActionBarFrame(MultiBar5, true)
	hideActionBarFrame(MultiBar6, true)
	hideActionBarFrame(MultiBar7, true)

	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		_G["ActionButton" .. i]:Hide()
		_G["ActionButton" .. i]:UnregisterAllEvents()
		_G["ActionButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomLeftButton" .. i]:Hide()
		_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomRightButton" .. i]:Hide()
		_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarRightButton" .. i]:Hide()
		_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarLeftButton" .. i]:Hide()
		_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBar5Button" .. i]:Hide()
		_G["MultiBar5Button" .. i]:UnregisterAllEvents()
		_G["MultiBar5Button" .. i]:SetAttribute("statehidden", true)

		_G["MultiBar6Button" .. i]:Hide()
		_G["MultiBar6Button" .. i]:UnregisterAllEvents()
		_G["MultiBar6Button" .. i]:SetAttribute("statehidden", true)

		_G["MultiBar7Button" .. i]:Hide()
		_G["MultiBar7Button" .. i]:UnregisterAllEvents()
		_G["MultiBar7Button" .. i]:SetAttribute("statehidden", true)
	end

	--MainMenuBar:UnregisterAllEvents()
	MainMenuBar:SetParent(UIHider)
	MainMenuBar:Hide()
	--MainMenuBar:EnableMouse(false)

	hideActionBarFrame(MicroButtonAndBagsBar, false, false, true)
	hideActionBarFrame(StanceBar, true)
	hideActionBarFrame(PossessActionBar, true)
	hideActionBarFrame(MultiCastActionBarFrame, false, false, true)
	hideActionBarFrame(PetActionBar, true)
	hideActionBarFrame(StatusTrackingBarManager, false)

	if IsAddOnLoaded("Blizzard_NewPlayerExperience") then
		self:NPE_LoadUI()
	elseif NPE_LoadUI ~= nil then
		self:SecureHook("NPE_LoadUI")
	end
end

function Bartender4:NPE_LoadUI()
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end
