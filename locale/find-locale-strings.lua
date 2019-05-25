-- Need to hardcode the project id here
local TOC_FILE
-- Automatically find the TOC in the given path, set to false to disable
local AUTO_FIND_TOC = "./"
-- Patterns that should not be scrapped, case-insensitive
-- Anything between the no-lib-strip is automatically ignored
local FILE_BLACKLIST = {"^locale", "^libs"}


-- No more modifying!
local OS_TYPE = os.getenv("HOME") and "linux" or "windows"

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
		if( not TOC_FILE ) then print("Failed to auto detect toc file.") end
	else
		print("Failed to auto find toc, cannot run dir /B or ls -1")
	end
end

if( not TOC_FILE ) then
	return
end

print(string.format("Using TOC file %s", TOC_FILE))
print("")

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
			
			print(string.format("%s (%d keys)", line, keys))
		end
	end
end

-- Compile all of the localization we found into string form
local totalLocalizedKeys = 0
local localization = ""
for key in pairs(localizedKeys) do
	localization = string.format("%sL[\"%s\"] = true\n", localization, key, key)
	totalLocalizedKeys = totalLocalizedKeys + 1
end

if( totalLocalizedKeys == 0 ) then
	print("Warning, failed to find any localizations, perhaps you messed up a configuration variable?")
	return
end

local file = assert(io.open("exported-locale-strings.lua", "w", "Error opening file"))
file:write(localization)
file:close()

print(string.format("Written %d keys to exported-locale-strings.lua", totalLocalizedKeys))
