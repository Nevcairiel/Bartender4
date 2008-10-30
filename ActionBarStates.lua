local ActionBar = Bartender4.ActionBar

local table_insert = table.insert
local table_concat = table.concat
local fmt = string.format

local modifiers = { "ctrl", "alt", "shift" }

local function tfind(haystack, needle, searchfunc)
	for i,v in pairs(haystack) do
		if (searchfunc and searchfunc(v, needle) or (v == needle)) then return i end
	end
	return nil
end

local _, playerclass = UnitClass("player")

-- specifiy the available stances for each class
local DefaultStanceMap = setmetatable({}, { __index = function(t,k)
	local newT = nil
	if k == "WARRIOR" then
		newT = {
			{ id = "battle", name = GetSpellInfo(2457), index = 1},
			{ id = "def", name = GetSpellInfo(71), index = 2 },
			{ id = "berserker", name = GetSpellInfo(2458), index = 3 },
		}
	elseif k == "DRUID" then
		newT = {
			{ id = "bear", name = GetSpellInfo(5487), index = 3 },
			{ id = "cat", name = GetSpellInfo(768), index = 1 },
				-- prowl is virtual, no real stance
			{ id = "prowl", name = ("%s (%s)"):format((GetSpellInfo(768)), (GetSpellInfo(5215))), index = false},
			{ id = "moonkin", name = GetSpellInfo(24858), index = 4 },
			{ id = "treeoflife", name = GetSpellInfo(33891), index = 2 },
		}
	elseif k == "ROGUE" then
		newT = {
			{ id = "stealth", name = GetSpellInfo(1784), index = 1 },
		}
	elseif k == "PRIEST" then
		newT = {
			{ id = "shadowform", name = GetSpellInfo(15473), index = 1 },
		}
	elseif k == "WARLOCK" then
		newT = {
			{ id = "metamorphosis", name = GetSpellInfo(59672), index = 2, type = "form"},
		}
	end
	rawset(t, k, newT)
	
	return newT
end})
Bartender4.StanceMap = DefaultStanceMap

local searchFunc = function(h, n) return (h.match == n or h.match2 == n or h.id == n) end

local stancemap
function ActionBar:UpdateStates(returnOnly)
	if not self.buttons then return end
	self.statebutton = {}
	if not stancemap and DefaultStanceMap[playerclass] then
		stancemap = DefaultStanceMap[playerclass]
	end
	
	self:ForAll("ClearStateAction")
	for i=0,11 do
		self:AddButtonStates(i)
	end
	
	local statedriver
	
	if returnOnly or not self:GetStateOption("customEnabled") then
		statedriver = {}
		if self:GetStateOption("possess") then
			table_insert(statedriver, "[bonusbar:5]11")
		end
		
		local stateconfig = self.config.states
		if self:GetStateOption("enabled") then
			-- arguments will be parsed from left to right, so we have a priority here
			
			-- highest priority have our temporary quick-swap keys
			for _,v in pairs(modifiers) do
				local page = self:GetStateOption(v)
				if page and page ~= 0 then
					table_insert(statedriver, fmt("[mod:%s]%s", v, page))
				end
			end
			
			-- second priority the manual changes using the actionbar options
			if self:GetStateOption("actionbar") then
				for i=2,6 do
					table_insert(statedriver, fmt("[bar:%s]%s", i, i))
				end
			end
			
			-- third priority the stances
			if stancemap then
				if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
				for i,v in pairs(stancemap) do
					local state = self:GetStanceState(v)
					if state and state ~= 0 and v.index then
						if playerclass == "DRUID" and v.id == "cat" then
							local prowl = self:GetStanceState("prowl")
							if prowl then
								table_insert(statedriver, fmt("[bonusbar:%s,stealth:1]%s", v.index, prowl))
							end
						end
						table_insert(statedriver, fmt("[%s:%s]%s", v.type or "bonusbar", v.index, state))
					end
				end
			end
		end
		
		table_insert(statedriver, tostring(self:GetDefaultState() or 0))
		statedriver = table_concat(statedriver, ";")
	else
		statedriver = self:GetStateOption("custom")
	end
	
	self:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])
	
	if not returnOnly then
		UnregisterStateDriver(self, "page")
		RegisterStateDriver(self, "page", statedriver or "")
	end
	
	self:SetAttribute("_onstate-assist-help", [[
		local state = (newstate ~= "nil") and newstate or nil
		control:ChildUpdate("assist-help", state)
	]])
	
	self:SetAttribute("_onstate-assist-harm", [[
		local state = (newstate ~= "nil") and newstate or nil
		control:ChildUpdate("assist-harm", state)
	]])
	
	local preSelf = ""
	if Bartender4.db.profile.selfcastmodifier then
		preSelf = "[mod:SELFCAST]player;"
	end
	
	local preFocus = ""
	if Bartender4.db.profile.focuscastmodifier then
		preFocus = "[mod:FOCUSCAST,target=focus,exists,nodead]focus;"
	end
	
	UnregisterStateDriver(self, "assist-help")
	UnregisterStateDriver(self, "assist-help")
	
	if self.config.autoassist then
		RegisterStateDriver(self, "assist-help", ("%s%s[help]nil; [target=targettarget, help]targettarget; nil"):format(preSelf, preFocus))
		RegisterStateDriver(self, "assist-harm", ("%s[harm]nil; [target=targettarget, harm]targettarget; nil"):format(preFocus))
	end
	
	return statedriver
end

function ActionBar:GetStanceState(stance)
	local stanceconfig = self.config.states.stance[playerclass]
	if type(stance) == "table" then
		state = stanceconfig[stance.id]
	else
		state = stanceconfig[stance]
	end
	return state or 0
end

function ActionBar:GetStanceStateOption(stance)
	local state = self:GetStanceState(stance)
	return state
end

function ActionBar:SetStanceStateOption(stance, state)
	local stanceconfig = self.config.states.stance[playerclass]
	stanceconfig[stance] = state
	self:UpdateStates()
end

function ActionBar:AddButtonStates(state, page)
	if not page then page = state end
	for _, button in self:GetAll() do
		local action = (page == 0) and button.id or (button.rid + (page - 1) * 12)
		button:SetStateAction(state, action)
	end
end

function ActionBar:GetStateOption(key)
	return self.config.states[key]
end

function ActionBar:SetStateOption(key, value)
	self.config.states[key] = value
	self:UpdateStates()
end

function ActionBar:GetDefaultState()
	return self.config.states.default
end

function ActionBar:SetDefaultState(_, value)
	self.config.states.default = value
	self:UpdateStates()
end

function ActionBar:GetConfigAutoAssist()
	return self.config.autoassist
end

function ActionBar:SetConfigAutoAssist(_, value)
	if value ~= nil then
		self.config.autoassist = value
	end
	self:UpdateStates()
	self:ForAll("RefreshAllStateActions")
end

function ActionBar:SetCopyCustomConditionals()
	self.config.states.custom = self:UpdateStates(true)
	self:UpdateStates()
end
