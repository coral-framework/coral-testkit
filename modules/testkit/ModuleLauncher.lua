local lfs = require "lfs"
local path = require "path"

local args = { ... }

-- list of suits to run. A suit is a colection of test cases.
local testSuits = {}
local totalTests = 0
local hasErrors = false

-----------------------------------------------------
-- Util functions
-----------------------------------------------------


-- Loads a file into the passed enviroment
local function loadFileIn( filename, env ) 
    local fh, err = io.open( filename, 'rb' )
    if not fh then return nil, err end
    local func, err = loadin( env, fh:lines(4096), filename )
    fh:close()
    if not func then return nil, err end
    return func
end

-- adds the passed suit of tests to the list to be executed if it has any tests loaded 
function addTestSuit( e, n )
	table.insert( testSuits, { name = n, env = e, testCases={}, errors = 0, failures = 0 } )
end

local MT = { __index = _ENV }

-- loads a script file and stores the enviroment with all the global functions declared
local function safeLoad( scriptName )
	local filePath = co.findScript( scriptName )
	local safeEnv = setmetatable( {}, MT )
	print( "Loading test file: " .. filePath )

	local chunk, err = loadFileIn( filePath, safeEnv )
	if err then error( "An error occured when loading the file: " .. err ) end

	chunk() -- runs the chunk to fill the enviroment
	addTestSuit( safeEnv, scriptName ) 
end

-- runs the given suit by searching for global functions and running them
local function runSuit( s )
	for k,v in pairs( s.env )	do
		if type( v ) == "function" then
	 		local ok, err = pcall( v )
			local fail = not ok and not err.testError -- failure if is not a test error
			local testCase = { name = k, err = not ok, failure = fail }
			if not ok then 
				testCase.errorMessage = err.message or err
				print( "the test '" .. k .. "' has failed.\n" .. testCase.errorMessage )
				s.errors = s.errors + 1
				if fail then s.failures = s.failures + 1 end
				hasErrors = true
			end
			table.insert( s.testCases, testCase )
			totalTests = totalTests + 1
		end		
	end	
end

-- searches all script files that matches ends with "Test.lua" on the given module root folder
local function loadModuleTypes( moduleName )

	-- Initializes commmon paths
	local moduleDirPath = moduleName:gsub( '%.', '/' )
	local coralPaths = co.getPaths()

	-- For each repository
	for i, repositoryDir in ipairs( coralPaths ) do
		local moduleDir = repositoryDir .. '/' .. moduleDirPath
		if path.isDir( moduleDir ) then
			-- For each file in module directory
			for filename in lfs.dir( moduleDir ) do
				local typeName = filename:match( "(.+)Tests%.lua$" )
				if typeName then safeLoad( moduleName .. "." .. typeName .. "Tests" ) end
			end
		end
	end
end

-- creates a folder if necessary, the outputfile and returns a file handle.
-- if an error occours returns nil and a error message
function openOutputFile( xmlReportFileName )
	if not xmlReportFileName then 
		return nil, "The output file name was not given, use the -o [FILE_NAME] sintax." 
	end
	local xmlReportFileName = path.normalize( lfs.currentdir() .. "/" .. xmlReportFileName )

	local outputDir = xmlReportFileName:match("(.*)/[^/]*")
	if not path.exists( outputDir ) and outputDir ~= "" then
		print ( "Creating output folder: " .. outputDir )
		path.makePath( outputDir )
	end

	print( "Writting report to file: " .. xmlReportFileName )

	local file, err = io.open( xmlReportFileName, "w" )
	if err then return nil, ( "The file could not be opened. " .. err ) end

	return file
end

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

-- gets the xml report in the JUnit format
function getXmlReport()
	local xmlReport = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	local function report( r ) xmlReport = xmlReport .. r .. "\n" end

	report( "<testsuites name=\"AllTests\" tests=\"" .. totalTests .. "\">" )

	for i,s in ipairs( testSuits ) do
		report( "<testsuite name=\"" .. separeteCamelCasePhrase( s.name ) .. "\" tests=\"" .. #s.testCases .. "\" errors =\"" .. s.errors .. "\" failures =\"" .. s.failures .. "\" >" )
		for j,c in ipairs( s.testCases ) do
			if c.err or c.failure then 
				report( "\t<testcase name=\"" .. separeteCamelCasePhrase( c.name ) .. "\" status=\"error\" >" )
				report( "\t\t<error type=\"" .. c.errorMessage .. "\"/>" )
				report( "\t</testcase>" )
			else
				report( "\t<testcase name=\"" .. separeteCamelCasePhrase( c.name ) .. "\" status=\"run\" />" )
			end
		end
		report "</testsuite>"
	end

	report( "</testsuites>" )
	return xmlReport
end


-----------------------------------------------------

local xmlReportFileName

for i=1, #args do 
	--parses the output file name
	if args[i] == "-o" and i ~= #args then 
		xmlReportFileName = args[i+1] 	
		i = i + 1
	else
	 	loadModuleTypes( args[i] )
	end
end

print( #testSuits .. " test suits loaded..." ) 

-- run all tests loaded
for i,s in ipairs( testSuits ) do
	runSuit( s ) 
end

print ( totalTests .. " test cases were runned \n" )


local file, err = openOutputFile( xmlReportFileName )
if err then print( err ); return 1 end

file:write( getXmlReport() )
file:close()

return hasErrors and 1 or 0



