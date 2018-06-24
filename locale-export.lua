local TOC_FILE
local AUTO_FIND_TOC = "./"
-- Patterns that should not be scrapped, case-insensitive
-- Anything between the no-lib-strip is automatically ignored
local FILE_BLACKLIST = {"^localization", "^lib"}

-- No more modifying!
local OS_TYPE = os.getenv("HOME") and "linux" or "windows"

local function printerr(pattern, ...)
	io.stderr:write(string.format(pattern .. "\n", ...))
end

-- Find the TOC now
if( AUTO_FIND_TOC ) then
	local pipe = OS_TYPE == "windows" and io.popen(string.format("dir /B \"%s\"", AUTO_FIND_TOC)) or io.popen(string.format("ls -1 \"%s\"", AUTO_FIND_TOC))
	if( type(pipe) == "userdata" ) then
		for file in pipe:lines() do
			if( string.match(file, "(.+)%.toc") ) then
				TOC_FILE = file
				break
			end
		end

		pipe:close()
		if( not TOC_FILE ) then printerr("Failed to auto detect toc file.") end
	else
		printerr("Failed to auto find toc, cannot run dir /B or ls -1")
	end
end

if( not TOC_FILE ) then
	while( not TOC_FILE ) do
		io.stdout:write("TOC path: ")
		TOC_FILE = io.stdin:read("*line")
		TOC_FILE = TOC_FILE ~= "" and TOC_FILE or nil
		if( TOC_FILE ) then
			local file = io.open(TOC_FILE)
			if( file ) then
				file:close()
				break
			else
				printerr("%s does not exist.", TOC_FILE)
				return
			end
		end
	end
end

printerr("Using TOC file %s", TOC_FILE)
printerr("")

-- Parse through the TOC file so we know what to scan
local ignore
local localizedKeys = {}
for line in io.lines(TOC_FILE) do
	line = string.gsub(line, "\r", "")
	
	if( string.match(line, "#@no%-lib%-strip@") ) then
		ignore = true
	elseif( string.match(line, "#@end%-no%-lib%-strip@") ) then
		ignore = nil
	end
		
	if( not ignore and string.match(line, "%.lua") and not string.match(line, "^%s*#")) then
		-- Make sure it's a valid file
		local blacklist
		for _, check in pairs(FILE_BLACKLIST) do
			if( string.match(string.lower(line), check) ) then
				blacklist = true
				break
			end
		end
	
		-- File checks out, scrap everything
		if( not blacklist ) then
			-- Fix slashes
			if( OS_TYPE == "linux" ) then
				line = string.gsub(line, "\\", "/")
			end
			
			local keys = 0
			local contents = io.open(line):read("*all")
		
			for match in string.gmatch(contents, "L%[\"(.-)%\"]") do
				if( not localizedKeys[match] ) then keys = keys + 1 end
				localizedKeys[match] = true
			end
			
			printerr("%s (%d keys)", line, keys)
		end
	end
end

-- Compile all of the localization we found into string form
local totalLocalizedKeys = 0
local localization = ""
for key in pairs(localizedKeys) do
	localization = string.format("%s\nL[\"%s\"] = true", localization, key, key)
	totalLocalizedKeys = totalLocalizedKeys + 1
end

if( totalLocalizedKeys == 0 ) then
	printerr("Warning, failed to find any localizations, perhaps you messed up a configuration variable?")
	return
end

printerr("Found %d keys total", totalLocalizedKeys)

print(localization)
