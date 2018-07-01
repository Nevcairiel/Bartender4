-- Need to hardcode the project id here
local ADDON_PROJECT_ID = 13501
local TOC_FILE
-- Automatically identify the slug based on the .git or .svn configuration data, change the path if it's not in root, or set to false to disable
local AUTO_IDENTIFY_SLUG = "./"
-- Automatically find the TOC in the given path, set to false to disable
local AUTO_FIND_TOC = "./"
-- Only necessary if you aren't auto identify the slug, curseforge or wowace.
local SITE_LOCATION = nil
-- Personally I keep the api key in another file and just have this reference that to get it
-- If you want to do this, create the file with CURSE_API_KEY = "<key>" in it and set the path here
-- set this to nil and it will ask you for your API key
local API_KEY_FILE = "../../cf-api-key.lua"
-- Patterns that should not be scrapped, case-insensitive
-- Anything between the no-lib-strip is automatically ignored
local FILE_BLACKLIST = {"^localization", "^lib"}

-- default language to import to
local DEFAULT_LANGUAGE = "enUS"
-- Removes phrases that are not found through this
local DELETE_UNIMPORTED = true

-- No more modifying!
local OS_TYPE = os.getenv("HOME") and "linux" or "windows"

-- Mak sure we have LuaSockets
local _, http = pcall(require, "ssl.https")
local _, ltn = pcall(require, "ltn12")
if( not http ) then
	print("Failed to find socket.http, did you install LuaSockets?")
elseif( not ltn ) then
	print("Failed to find ltn12, did you install LuaSockets?")
end

-- check project id is set
if not ADDON_PROJECT_ID then
	print("No project id specified, did you set it?")
	return
end

-- Figure out the API key
if( API_KEY_FILE ) then
	local file = io.open(API_KEY_FILE)
	if( not file ) then
		print(string.format("It appears the API key file %s does not exist.", API_KEY_FILE))
	else
		file:close()
		dofile(API_KEY_FILE)
		
		if( not CURSE_API_KEY ) then
			print("You did not define CURSE_API_KEY in your key file, make sure it does not have local next to it.")
		end
	end
end

if( not CURSE_API_KEY ) then
	while( not CURSE_API_KEY ) do
		io.stdout:write("Enter API key: ")
		CURSE_API_KEY = io.stdin:read("*line")
		CURSE_API_KEY = CURSE_API_KEY ~= "" and CURSE_API_KEY or nil
	end
end

-- Attempt to automatically identify the addon slug
if( AUTO_IDENTIFY_SLUG ) then
	local git = io.open(AUTO_IDENTIFY_SLUG .. ".git/config")
	local svn = io.popen("svn info --show-item url " .. AUTO_IDENTIFY_SLUG)

	if( git ) then
		local contents = git:read("*all")

		SITE_LOCATION = string.match(contents, "repos%.([^\n]-)%.com/wow/([^\n]-)")
	elseif( svn ) then
		local contents = svn:read("*all")
	
		SITE_LOCATION = string.match(contents, "repos%.([^\n]-)%.com/wow/([^\n]-)")
	end
	
	if( git ) then git:close() end
	if( svn ) then svn:close() end
	
	if( not SITE_LOCATION ) then
		print("Failed to identify site location.")
	end
end

if( not SITE_LOCATION ) then
	while( not SITE_LOCATION ) do
		io.stdout:write("Site location [wowace/curseforge]: ")
		SITE_LOCATION = io.stdin:read("*line")
		SITE_LOCATION = ( SITE_LOCATION == "wowace" or SITE_LOCATION == "curseforge" ) and SITE_LOCATION or nil
	end
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
		if( not TOC_FILE ) then print("Failed to auto detect toc file.") end
	else
		print("Failed to auto find toc, cannot run dir /B or ls -1")
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
				print(string.format("%s does not exist.", TOC_FILE))
			end
		end
	end
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
	localization = string.format("%s\nL[\"%s\"] = true", localization, key, key)
	totalLocalizedKeys = totalLocalizedKeys + 1
end

if( totalLocalizedKeys == 0 ) then
	print("Warning, failed to find any localizations, perhaps you messed up a configuration variable?")
	return
end

print(string.format("Found %d keys total", totalLocalizedKeys))

local addonData = {
	["metadata"] = ("{ language: \"%s\", \"namespace\": \"\", \"missing-phrase-handling\": \"%s\" }"):format(DEFAULT_LANGUAGE, DELETE_UNIMPORTED and "DeletePhrase" or "DoNothing"),
	["localizations"] = localization,
}

-- Send it off
local boundary = string.format("-------%s", os.time())
local source = {}
local body = ""

for key, data in pairs(addonData) do
	body = string.format("%s--%s\r\n", body, boundary)
	body = string.format("%sContent-Disposition: form-data; name=\"%s\"\r\n\r\n", body, key)
	body = string.format("%s%s\r\n", body, data)
end

body = string.format("%s--%s--\r\n", body, boundary)

local host = SITE_LOCATION == "curseforge" and "wow.curseforge.com" or "www.wowace.com"

http.request({
	method = "POST",
	url = string.format("https://%s/api/projects/%s/localization/import", host, ADDON_PROJECT_ID),
	sink = ltn12.sink.table(source),
	source = ltn12.source.string(body),
	headers = {
		["X-Api-Token"] = CURSE_API_KEY,
		["Content-Type"] = string.format("multipart/form-data; boundary=\"%s\"", boundary),
		["Content-Length"] = string.len(body),
	},
})

local contents = table.concat(source, "\n")
print(contents)
print("")

print(string.format("Updated localization on %s!", SITE_LOCATION))

