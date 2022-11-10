--[[
	Copyright (c) 2009-2022, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- WoW Classic (and 9.x) uses the old code
if select(4, GetBuildInfo()) < 100000 then
	return
end

local function hideActionBarFrame(frame, clearEvents, dontRemoveActionButtons)
	if frame then
		if clearEvents then
			frame:UnregisterAllEvents()
		end

		-- remove some EditMode hooks
		if frame.systemInfo then
			frame.Show = nil
			frame.Hide = nil
			frame.SetShown = nil
			frame.IsShown = nil

			Bartender4.Util:PurgeKey(frame, "isShownExternal")
		end

		if frame.actionButtons and not dontRemoveActionButtons then
			table.wipe(frame.actionButtons)
		end

		frame:Hide()
		frame:SetParent(Bartender4.UIHider)
	end
end

local function hideActionButton(button)
	if not button then return end

	button:Hide()
	button:UnregisterAllEvents()
	button:SetAttribute("statehidden", true)

	-- purgeing the index variable prevents some EditMode related updates from taking place
	Bartender4.Util:PurgeKey(button, "index")
end

function Bartender4:HideBlizzard()
	-- Hidden parent frame
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	self.UIHider = UIHider

	hideActionBarFrame(MainMenuBar, false)
	hideActionBarFrame(MultiBarBottomLeft, true)
	hideActionBarFrame(MultiBarBottomRight, true)
	hideActionBarFrame(MultiBarLeft, true)
	hideActionBarFrame(MultiBarRight, true)
	hideActionBarFrame(MultiBar5, true)
	hideActionBarFrame(MultiBar6, true)
	hideActionBarFrame(MultiBar7, true)

	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		hideActionButton(_G["ActionButton" .. i])
		hideActionButton(_G["MultiBarBottomLeftButton" .. i])
		hideActionButton(_G["MultiBarBottomRightButton" .. i])
		hideActionButton(_G["MultiBarRightButton" .. i])
		hideActionButton(_G["MultiBarLeftButton" .. i])
		hideActionButton(_G["MultiBar5Button" .. i])
		hideActionButton(_G["MultiBar6Button" .. i])
		hideActionButton(_G["MultiBar7Button" .. i])
	end

	hideActionBarFrame(MicroButtonAndBagsBar, false, true)
	hideActionBarFrame(StanceBar, true, true)
	hideActionBarFrame(PossessActionBar, true, true)
	hideActionBarFrame(MultiCastActionBarFrame, false, true)
	hideActionBarFrame(PetActionBar, true, true)
	hideActionBarFrame(StatusTrackingBarManager, false)

	-- these events drive visibility, we want the MainMenuBar to remain invisible
	MainMenuBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
	MainMenuBar:UnregisterEvent("PLAYER_REGEN_DISABLED")
	MainMenuBar:UnregisterEvent("ACTIONBAR_SHOWGRID")
	MainMenuBar:UnregisterEvent("ACTIONBAR_HIDEGRID")

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
