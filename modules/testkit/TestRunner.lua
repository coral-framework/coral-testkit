--------------------------------------------------------------------------------
--- Test Runner
--------------------------------------------------------------------------------

local lfs = require "lfs"
local path = require "path"
require "testkit.Report"

local args = { ... }

-- list of suits to run. A suit is a colection of test cases.
local testSuits = {}
local totalTests = 0
local hasErrors = false

---------------------------------------
-- Helper Functions
---------------------------------------

-- Loads a file into the passed enviroment
local function loadFileIn( filename, env ) 
    local fh, err = io.open( filename, 'rb' )
    if not fh then return nil, err end
	
    local func, err = loadin( env, fh:lines(4096), filename )
    fh:close()
    if not func then return nil, err end
	
    return func
end

-- turns a camel case identifier to a space separated phrase
function separeteCamelCasePhrase( name )
	local phrase = ""
	for i = 1, #name do
	    local c = name:sub(i,i)
		if c == "." then phrase = phrase .. " - "
		elseif c == c:lower() then
			phrase = phrase .. c
		else
			phrase = phrase .. " " .. c:lower()
		end		
	end
	return phrase
end 

-- adds the passed suit of tests to the list to be executed if it has any tests loaded 
function addTestSuit( e, n, fPath )
	table.insert( testSuits, { name = n, readableName =separeteCamelCasePhrase( n ) , filePath = fPath, env = e, testCases={}, errors = 0, failures = 0 } )
end

-- loads a script file and stores the enviroment with all the global functions declared
local MT = { __index = _ENV }
local function safeLoad( scriptPath, scriptName )

	print( "Loading test file: " .. scriptName )
	local safeEnv = setmetatable( {}, MT )
	
	local chunk, err = loadFileIn( scriptPath .. "/" .. scriptName, safeEnv )
	if err then error( "An error occured when loading the file: " .. err ) end

	chunk() -- runs the chunk to fill the enviroment
	addTestSuit( safeEnv, scriptName, scriptPath .. "/" .. scriptName )
end

-- runs the given suit by searching for global functions and running them
local function runSuit( s )
	for k,v in pairs( s.env )	do
		if type( v ) == "function" then
	 		local ok, err = pcall( v )
			local fail = not ok and not err.testError -- failure if is not a test error
			local testCase = { name = k,readableName =separeteCamelCasePhrase( k ), err = not ok, failure = fail }
			if not ok then 
				testCase.errorMessage = err.message or err
				print( "the test '" .. k .."' on the file '" .. s.filePath .. "' has failed.\n" .. testCase.errorMessage )
				s.errors = s.errors + 1
				if fail then s.failures = s.failures + 1 end
				hasErrors = true
			end
			table.insert( s.testCases, testCase )
			totalTests = totalTests + 1
		end		
	end	
end

-- Searches all script files that matches ends with "Tests.lua" on the given 
--  target test folder.
local function loadTestScripts( testsPath )
	for filename in lfs.dir( testsPath ) do
		local typeName = filename:match( "(.+)Tests%.lua$" )
		if typeName then safeLoad( testsPath, typeName .. "Tests.lua" ) end
	end
end

---------------------------------------
-- Main Execution
---------------------------------------

local xmlReportFileName

for i=1, #args do 
	-- parses the output file name
	if args[i] == "-o" and i ~= #args then 
		xmlReportFileName = args[i+1]
	else 
		-- verifies if the arg is not the output filename
		if args[i-1] ~= "-o" then
			loadTestScripts( args[i] ) 
		end
	end
end

print( #testSuits .. " test suits loaded..." ) 

-- run all tests loaded
for i,s in ipairs( testSuits ) do
	runSuit( s ) 
end

print ( totalTests .. " test cases were runned \n" )

writeToXml( totalTests, testSuits, xmlReportFileName )

return hasErrors and 1 or 0



