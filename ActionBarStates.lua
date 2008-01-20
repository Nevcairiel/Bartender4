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

local optGetter, optSetter
do
	local getBar, optionMap, callFunc
	
	optionMap = {
		stance = "StanceStateOption",
		enabled = "StateOption",
	}
	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		local bar = module.actionbars[tonumber(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function."..func)
		return bar[func](bar, ...)
	end
	
	-- universal function to get a option
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info.arg or info[#info]
		return callFunc(bar, "Get", option, info[#info])
	end
	
	-- universal function to set a option
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info.arg or info[#info]
		return callFunc(bar, "Set", option, info[#info], ...)
	end
end

function module:GetStanceOptionsTable()
	local options = {
		enabled = {
			order = 1,
			type = "toggle",
			name = "Enabled",
			desc = "Enable State-based Button Swaping",
			get = optGetter,
			set = optSetter,
		},
	}
	
	return options
end

local S = LibStub("AceLocale-3.0"):GetLocale("BT4Stances")

-- specifiy the available stances for each class
module.DefaultStanceMap = {
	WARRIOR = {
		{ id = "battle", match = S["Battle Stance"] },
		{ id = "def", match = S["Defensive Stance"] },
		{ id = "berserker", match = S["Berserker Stance"] },
	},
	DRUID = {
		{ id = "bear", match = S["Bear Form"], match2 = S["Dire Bear Form"] },
		{ id = "cat", match = S["Cat Form"] },
		{ id = "moonkin", match = S["Moonkin Form"] },
		{ id = "tree", match = S["Tree of Life"] },
		-- prowl is virtual, no real stance
		{ id = "prowl", virtual = true, name = "Cat Form (Prowl)", depend = "cat" },
	},
	ROGUE = {
		{ id = "stealth", match = S["Stealth"] },
	},
	PRIEST = { --shadowform gets a position override because it doesnt have a real stance position .. and priests dont have other stances =)
		{ id = "shadowform", virtual = true, name = "Shadowform", position = 1 },
	}
}

local _, playerclass = UnitClass("player")
local num_shapeshift_forms

function module:CreateStanceMap()
	local defstancemap = self.DefaultStanceMap[playerclass]
	if not defstancemap then return end
	
	self.stancemap = {}
	
	num_shapeshift_forms = GetNumShapeshiftForms()
	
	for k,v in pairs(defstancemap) do
		local entry = { id = v.id, match = v.match, match2 = v.match2, virtual = v.virtual, depend = v.depend, position = v.position }
		if not v.virtual and type(v.match) == "string" then
			entry.name = v.match
		elseif not v.virtual and type(v.match) == "table" then
			entry.name = v.match[1]
		else
			entry.name = v.name
		end
		table_insert(self.stancemap, entry)
	end
	
	for i = 1, num_shapeshift_forms do
		local _, name = GetShapeshiftFormInfo(i)
		local index = tfind(self.stancemap, name, function(h, n) return (h.match == n or h.match2 == n) end)
		if index then
			self.stancemap[index].position = i
		end
	end
end

function ActionBar:UpdateStates()
	if not module.stancemap and module.DefaultStanceMap[playerclass] then module:CreateStanceMap() end
	for i=0,10 do
		self:AddButtonStates(i)
	end
	
	local stateconfig = self.config.states
	if self:GetStateOption("enabled") then
		-- arguments will be parsed from left to right, so we have a priority here
		local statedriver = {}
		
		-- highest priority have our temporary quick-swap keys
		for _,v in pairs(modifiers) do
			local page = tonumber(self:GetStateOption(v))
			if page and page ~= 0 then
				table_insert(statedriver, fmt("[modifier:%s]%s", v, page)) 
			end
		end
		
		-- second priority the manual changes using the actionbar options
		if self.id == 1 then
			for i=2,6 do
				table_insert(statedriver, fmt("[actionbar:%s]%s", i, i))
			end
		end
		
		-- third priority the stances
		if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
		if module.stancemap then
			for i,v in pairs(module.stancemap) do
				local state = self:GetStanceState(v)
				if state and v.position then
					if playerclass == "DRUID" and v.id == "cat" then
						local prowl = self:GetStanceState("prowl")
						if prowl then
							table_insert(statedriver, fmt("[stance:%s,stealth:1]%s", v.position, prowl))
						end
					end
					table_insert(statedriver, fmt("[stance:%s]%s", v.position, state))
				end
			end
		end
		
		table_insert(statedriver, "0")
		
		RegisterStateDriver(self, "page", table_concat(statedriver, ";"))
		self:SetAttribute("statemap-page", "$input")
		self:SetAttribute("state", self:GetAttribute("state-page"))
	else
		UnregisterStateDriver(self)
		self:SetAttribute("state", "0")
	end
	
	self:ApplyStateButton()
	
	SecureStateHeader_Refresh(self)
end

function ActionBar:GetStanceState(stance)
	local stanceconfig = self.config.states.stance[playerclass]
	if type(stance) == "table" then 
		state = tonumber(stanceconfig[stance.id])
	else
		state = tonumber(stanceconfig[stance])
	end
	if state and state == 0 then state = nil end
	return state
end

function ActionBar:GetStanceStateOption(stance)
	local state = self:GetStanceState(stance)
	return (state and tostring(state))
end

function ActionBar:SetStanceStateOption(stance, state)
	local stanceconfig = self.config.states.stance[playerclass]
	stanceconfig[stance] = tonumber(state)
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
	state = tonumber(state)
	if not tfind(self.statebutton, state) then 
		table_insert(self.statebutton, state)
	end
end

function ActionBar:AddRightClickState(state)
	local scrc = Bartender4.db.profile.selfcastrightclick
	local target = scrc and "player" or nil
	
	self:SetAttribute("unit-S" .. state .. "2", target)
end

function ActionBar:ApplyStateButton()
	local states1, states2 = {}, {}
	for _,v in pairs(self.statebutton) do
		table_insert(states1, fmt("%s:S%s1;", v, v))
		table_insert(states2, fmt("%s:S%s2;", v, v))
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
