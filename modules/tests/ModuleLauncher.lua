local lfs = require "lfs"
local path = require "path"
local TypeWrapper = require "co.compiler.TypeWrapper"


local testSuits = {}
local args = { ... }


local function loadfilein(filename, env) 
    local fh, err = io.open(filename, 'rb')
    if not fh then return nil, err end
    local func, err = loadin(env, fh:lines(4096), filename)
    fh:close()
    if not func then return nil, err end
    return func
end

-- adds the passed suit of tests to the list to be executed if it has any tests loaded 
function addTestSuit( e, n )
	table.insert( testSuits, { name = n, env = e, testCases={}, errors = 0, failures = 0 } )
end

local MT = { __index = _ENV }

local function safeLoad( scriptName )
	local filePath = co.findScript( scriptName )

	local safeEnv = setmetatable( {}, MT )
	local chunk = loadfilein( filePath, safeEnv )
	chunk()
	addTestSuit( safeEnv, scriptName ) 
	print ( "loaded " .. scriptName )
end

local function runSuit( s )
	for k,v in pairs( s.env )	do
		if type( v ) == "function" then
	 		local ok, err = pcall( v )
			local fail = not ok and not err.testError -- failure if is not a test error
			local testCase = { name = k, err = not ok, failure = fail }
			if not ok then 
				testCase.errorMessage = err.message or err
				print( "the test '" .. k .. "' has faild.\n" .. testCase.errorMessage )
				s.errors = s.errors + 1
				if fail then s.failures = s.failures + 1 end
			end
			table.insert( s.testCases, testCase )
		end		
	end	
end

-- Loads all module types by locating CSL files in the module's namespace
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
				local typeName = filename:match( "(.+)Test%.lua$" )
				if typeName then safeLoad( moduleName .. "." .. typeName .. "Test" ) end
			end
		end
	end
end

-----------------------------------------------------

local xmlReportFileName

for i=1, #args do 
	--parses the output file name
	if args[i] == "-o" then 
		xmlReportFileName = args[i+1] 	
		i = i + 1
	else
	 	loadModuleTypes( args[i] )
	end
end

if not xmlReportFileName then 
	print "The output file name was not given, use the -o [FILE_NAME] sintax." 
	return
end

file,err = io.open( xmlReportFileName, "w" )
if err then 
	print "The file could not be opened"
	return
end

print( #testSuits .. " test suits loaded.\n" )

-- run all tests loaded
for i,s in ipairs( testSuits ) do
	runSuit( s ) 
end

print( "WRITING REPORT TO FILE:" .. xmlReportFileName )

local xmlReport = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
local function report( r ) xmlReport = xmlReport .. r .. "\n" end

for i,s in ipairs( testSuits ) do
	report( "<testsuite name=\"" .. s.name .. "\" tests=\"" .. #s.testCases .. "\" errors =\"" .. s.errors .. "\" failures =\"" .. s.failures .. "\" >" )
	for j,c in ipairs( s.testCases ) do
		if c.err or c.failure then 
			report( "\t<testcase name=\"" .. c.name .. "\" status=\"error\" >" )
			report( "\t\t<error type=\"" .. c.errorMessage .. "\"/>" )
			report( "\t</testcase>" )
		else
			report( "\t<testcase name=\"" .. c.name .. "\" status=\"run\" />" )
		end
	end
	report "</testsuite>"
end
file:write( xmlReport )




