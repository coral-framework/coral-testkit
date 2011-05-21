--------------------------------------------------------------------------------
--- Test Runner
--------------------------------------------------------------------------------

local lfs = require "lfs"
local path = require "path"
local report = require "testkit.Report"

local args = { ... }

-- list of suits to run. A suit is a colection of test cases.
local testSuites = {}
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

-- Turns a camel case identifier to a space separated phrase
local function separateCamelCasePhrase( name )
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

-- Returns the copy of the given table
local function copyTable( t )
	local t2 = {}
	for k,v in pairs( t ) do
		t2[k] = v
	end
	return t2
end

---------------------------------------
-- TestRunner Fucntions
---------------------------------------

local function verifyEnvIntegrity( suite, originalEnv )
	for k,v in pairs( suite.environment ) do
 		if originalEnv[k] ~= v then
 			error( "One or more variables in " .. suite.filePath .. " are not" ..
 			" local, and therefore, the test environment has been corrupted." )
 		end
  	end
end

-- Adds the passed suit of tests to the list to be executed if it has any tests loaded 
local function addTestSuite( e, n, fPath )

	local newTable = { 	name = n,
						readableName = separateCamelCasePhrase( n ),
						filePath = fPath,
						environment = e,
						testCases = {},
						testErrors = 0,
						failures = 0
					 }
					 
	testSuites[#testSuites + 1] = newTable
end

-- Loads a script file and stores the enviroment with all the global functions declared
local MT = { __index = _ENV }
local function safeLoad( scriptPath, scriptName )

	print( "Loading test file: " .. scriptName )
	local safeEnv = setmetatable( {}, MT )
	
	local chunk, err = loadFileIn( scriptPath .. "/" .. scriptName, safeEnv )
	if err then error( "An error occured when loading the file: " .. err ) end

	chunk() -- runs the chunk to fill the enviroment
	
	addTestSuite( safeEnv, scriptName, scriptPath .. "/" .. scriptName )
end

-- closure needed to get the call stack in case it is not a test error
local traceback = require( "debug" ).traceback
local function errorClosure( err )
	if err.testError  then
		return err
	else
		return "** Failure is not a test error **\n" .. err .. "\n" .. traceback()
	end
end

-- Runs the given suit by searching for global functions and running them
local function runSuite( s )
	local originalEnv = copyTable( s.environment )
	
	for k,v in pairs( s.environment ) do
		if type( v ) == "function" then
			
	 		local ok, err = xpcall( v, errorClosure )
			verifyEnvIntegrity( s, originalEnv )
			
			local fail = not ok and not err.testError -- failure if is not a test error
			local testCase = { name = k, readableName = separateCamelCasePhrase( k ), err = not ok, failure = fail }
			if not ok then 
				testCase.errorMessage = err.message or err
				print( "the test '" .. k .."' on the file '" .. s.filePath .. "' has failed.\n" .. testCase.errorMessage )
				s.testErrors = s.testErrors + 1
				if fail then s.failures = s.failures + 1 end
				hasErrors = true
			end
			s.testCases[#s.testCases + 1] =  testCase
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

print( #testSuites .. " test suits loaded..." ) 

-- Run all tests loaded
for i,s in ipairs( testSuites ) do
	runSuite( s ) 
end

print ( totalTests .. " test cases were executed.\n" )

report.writeToXml( totalTests, testSuites, xmlReportFileName )

return hasErrors and 1 or 0



