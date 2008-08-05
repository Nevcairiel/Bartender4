--[[ $Id$ ]]
local ActionBar = Bartender4.ActionBar

local module = Bartender4:GetModule("ActionBars")

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
module.DefaultStanceMap = setmetatable({}, { __index = function(t,k)
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
	end
	rawset(t, k, newT)
	
	return newT
end})

local searchFunc = function(h, n) return (h.match == n or h.match2 == n or h.id == n) end
function module:CreateStanceMap()
	local defstancemap = self.DefaultStanceMap[playerclass]
	if not defstancemap then return end
	
	self.stancemap = defstancemap
end

function ActionBar:UpdateStates()
	if not self.buttons then return end
	self:InitVisibilityDriver()
	self.statebutton = {}
	if not module.stancemap and module.DefaultStanceMap[playerclass] then 
		module.stancemap = module.DefaultStanceMap[playerclass]
	end
	
	self:ForAll("ClearStateAction")
	for i=0,10 do
		self:AddButtonStates(i)
	end
	
	local statedriver = {}
	if self:GetStateOption("possess") then
		self:AddButtonStates(11)
		table_insert(statedriver, "[bonusbar:5]11")
	end
	
	local stateconfig = self.config.states
	if self:GetStateOption("enabled") then
		-- arguments will be parsed from left to right, so we have a priority here
		
		-- highest priority have our temporary quick-swap keys
		for _,v in pairs(modifiers) do
			local page = self:GetStateOption(v)
			if page and page ~= 0 then
				if page == -1 then
					self:RegisterVisibilityCondition(fmt("[modifier:%s]hide", v))
				else
					table_insert(statedriver, fmt("[modifier:%s]%s", v, page)) 
				end
			end
		end
		
		-- second priority the manual changes using the actionbar options
		if self:GetStateOption("actionbar") then
			for i=2,6 do
				table_insert(statedriver, fmt("[actionbar:%s]%s", i, i))
			end
		end
		
		-- third priority the stances
		if module.stancemap then
			if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
			for i,v in pairs(module.stancemap) do
				local state = self:GetStanceState(v)
				if state and state ~= 0 and v.index then
					if playerclass == "DRUID" and v.id == "cat" then
						local prowl = self:GetStanceState("prowl")
						if prowl then
							if prowl == -1 then
								self:RegisterVisibilityCondition(fmt("[bonusbar:%s,stealth:1]hide", v.index))
							else
								table_insert(statedriver, fmt("[bonusbar:%s,stealth:1]%s", v.index, prowl))
							end
						end
					end
					if state == -1 then
						self:RegisterVisibilityCondition(fmt("[bonusbar:%s]hide", v.index))
					else
						table_insert(statedriver, fmt("[bonusbar:%s]%s", v.index, state))
					end
				end
			end
		end
	end
	
	table_insert(statedriver, tostring(self:GetDefaultState() or 0))
	
	RegisterStateDriver(self, "page", table_concat(statedriver, ";"))
	
	self:ApplyStateButton()
	
	self:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		return true
	]])
	
	local newState = self:GetAttribute("state-page")
	self:SetAttribute("state", newState)
	
	self:ApplyVisibilityDriver()
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
	self:AddRightClickState(state)
	self:AddToStateButton(state)
end

function ActionBar:AddToStateButton(state)
	if not self.statebutton then self.statebutton = {} end
	if not tfind(self.statebutton, state) then 
		table_insert(self.statebutton, state)
	end
end

function ActionBar:AddRightClickState(state)
	local scrc = Bartender4.db.profile.selfcastrightclick
	local target = scrc and "player" or nil
	
	self:SetAttribute("unit-S" .. state .. "Right", target)
end

function ActionBar:ApplyStateButton()
	local states1, states2 = {}, {}
	for _,v in pairs(self.statebutton) do
		table_insert(states1, fmt("%s:S%s;", v, v))
		table_insert(states2, fmt("%s:S%sRight;", v, v))
	end
	self:SetAttribute("statebutton", table_concat(states1, ""))
	self:SetAttribute("statebutton2", table_concat(states2, ""))
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
	self:ForAll("RefreshAllStateActions")
end
