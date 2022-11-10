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

		-- remove some EditMode hooks
		if frame.systemInfo then
			frame.Show = nil
			frame.Hide = nil
			frame.SetShown = nil
			frame.IsShown = nil

			Bartender4.Util:PurgeKey(frame, "isShownExternal")
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

local function hideActionButton(button)
	if not button then return end

	button:Hide()
	button:UnregisterAllEvents()
	button:SetAttribute("statehidden", true)
end

function Bartender4:HideBlizzard()
	-- Hidden parent frame
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	self.UIHider = UIHider

	hideActionBarFrame(MainMenuBar, false, false, true)
	hideActionBarFrame(MultiBarBottomLeft, true, false, true)
	hideActionBarFrame(MultiBarBottomRight, true, false, true)
	hideActionBarFrame(MultiBarLeft, true, false, true)
	hideActionBarFrame(MultiBarRight, true, false, true)
	hideActionBarFrame(MultiBar5, true, false, true)
	hideActionBarFrame(MultiBar6, true, false, true)
	hideActionBarFrame(MultiBar7, true, false, true)

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

	hideActionBarFrame(MicroButtonAndBagsBar, false, false, true)
	hideActionBarFrame(StanceBar, true, false, true)
	hideActionBarFrame(PossessActionBar, true, false, true)
	hideActionBarFrame(MultiCastActionBarFrame, false, false, true)
	hideActionBarFrame(PetActionBar, true, false, true)
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
