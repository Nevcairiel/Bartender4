--[[
	Copyright (c) 2009-2022, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- WoW 10.0 uses new code
if select(4, GetBuildInfo()) >= 100000 then
	return
end

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

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

	MultiBarBottomLeft:SetParent(UIHider)
	MultiBarBottomRight:SetParent(UIHider)
	MultiBarLeft:SetParent(UIHider)
	MultiBarRight:SetParent(UIHider)

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
	end
	UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["StanceBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PETACTIONBAR_YPOS"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["ExtraAbilityContainer"] = nil

	--MainMenuBar:UnregisterAllEvents()
	--MainMenuBar:SetParent(UIHider)
	--MainMenuBar:Hide()
	MainMenuBar:EnableMouse(false)
	MainMenuBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
	MainMenuBar:UnregisterEvent("UI_SCALE_CHANGED")


	local animations = {MainMenuBar.slideOut:GetAnimations()}
	animations[1]:SetOffset(0,0)

	if OverrideActionBar then -- classic doesn't have this
		animations = {OverrideActionBar.slideOut:GetAnimations()}
		animations[1]:SetOffset(0,0)

		-- when blizzard vehicle is turned off, we need to manually fix the state since the OverrideActionBar animation wont run
		hooksecurefunc("BeginActionBarTransition", function(bar, animIn)
			if bar == OverrideActionBar and not self.db.profile.blizzardVehicle then
				OverrideActionBar.slideOut:Stop()
				MainMenuBar:Show()
			end
		end)
	end

	hideActionBarFrame(MainMenuBarArtFrame, false, true)
	hideActionBarFrame(MainMenuBarArtFrameBackground)
	hideActionBarFrame(MicroButtonAndBagsBar, false, false, true)

	if StatusTrackingBarManager then
		StatusTrackingBarManager:Hide()
		--StatusTrackingBarManager:SetParent(UIHider)
	end

	hideActionBarFrame(StanceBarFrame, true, true)
	hideActionBarFrame(PossessBarFrame, false, true)
	hideActionBarFrame(MultiCastActionBarFrame, false, true)
	hideActionBarFrame(PetActionBarFrame, true, true)
	ShowPetActionBar = function() end

	--BonusActionBarFrame:UnregisterAllEvents()
	--BonusActionBarFrame:Hide()
	--BonusActionBarFrame:SetParent(UIHider)

	if not WoWClassic then
		if PlayerTalentFrame then
			PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		else
			hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
		end
	end

	hideActionBarFrame(MainMenuBarPerformanceBarFrame, false, false, true)
	hideActionBarFrame(MainMenuExpBar, false, false, true)
	hideActionBarFrame(ReputationWatchBar, false, false, true)
	hideActionBarFrame(MainMenuBarMaxLevelBar, false, false, true)

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
