local path = require "lua.path"
local util = require "testkit.util"
local type = type
local load = load
local error = error
local pairs = pairs
local xpcall = xpcall
local tostring = tostring
local setmetatable = setmetatable
local tConcat = table.concat
local dbgGetInfo = require( "debug" ).getinfo

-------------------------------------------------------------------------------
-- Test Environment and Helper Functions
-------------------------------------------------------------------------------

local testEnv = require "testkit.env"
local testEnvMT = { __index = testEnv }

local function loadFileIn( filename, env )
    return load( io.lines( filename, 4096 ), filename, 't', env )
end

-------------------------------------------------------------------------------
-- TestKit Suite Class
-------------------------------------------------------------------------------

local Suite = {
	tests = {},		-- list of tests; each element = { name = n, func = f }
	errors = 0,		-- number of test that raised errors
	failures = 0,	-- number of tests that simply failed
	time = 0,		-- total execution time of all tests (in seconds)
}

local SuiteMT = { __index = Suite }

function Suite.new()
	return setmetatable( {}, SuiteMT )
end

local function nullFunction() end

function Suite.loadFrom( filename )
	-- run the script into a new test environment
	local env = setmetatable( {}, testEnvMT )
	local chunk, err = loadFileIn( filename, env )
	if err then error( err ) end
	chunk()

	-- extract the special setup/teardown functions
	local setup = env.setup or nullFunction
	local teardown = env.teardown or nullFunction
	env.setup = nil
	env.teardown = nil

	-- extract the test cases
	local tests = {}
	for k, v in pairs( env ) do
		local tp = type( v )
		if tp ~= 'function' then
			error( "illegal global '" .. tostring( k ) .. "' (" .. tp .. "); only functions are allowed in the global scope" )
		end
		tests[#tests + 1] = { name = k, func = v }
	end

	local dir, baseName = path.split( filename )
	local name, ext = path.splitExt( baseName )

	-- create the Suite
	local suite = Suite.new()
	suite.name = name
	suite.tests = tests
	suite.setup = setup
	suite.teardown = teardown

	return suite
end

local errorMT = { __tostring = function( err )
	return err.message .. "\n" .. err.traceback
end }

local pruneTracesAt = nil
local function testTraceback( message )
	-- find out where we should prune the call stack
	local maxLevel = 2
	while true do
		local info = dbgGetInfo( maxLevel, "f" )
		if not info or info.func == pruneTracesAt then
			break
		end
		maxLevel = maxLevel + 1
	end

	-- format the call stack
	local buf = {}
	for level = 2, maxLevel - 2 do
		local info = dbgGetInfo( level, "nSl" )
		if #buf > 0 then
			buf[#buf + 1] = "\n"
		end
		buf[#buf + 1] = info.source .. ":"
		if info.currentline > 0 then
			buf[#buf + 1] = info.currentline .. ":"
		end
		if info.namewhat ~= "" then
			buf[#buf + 1] = " in function '" .. info.name .. "'"
		else
			if info.what == "main" then
				buf[#buf + 1] = " in main chunk"
			elseif info.what == "C" or info.what == "tail" then
				buf[#buf + 1] = " ?"
			else
				buf[#buf + 1] = " in function <" .. info.source .. ":" .. info.linedefined .. ">"
			end
		end
	end
	return setmetatable( { message = message, traceback = tConcat( buf ) }, errorMT )
end

local function try( f, ... )
	return xpcall( f, testTraceback, ... )
end

pruneTracesAt = try

function Suite:run()
	local testsStr = util.formatCount( #self.tests, "test", "tests" )
	print( "\n[----------]", testsStr .. " from " .. self.name )
	local suiteStartTime = util.tick()
	for i, test in ipairs( self.tests ) do
		-- prepare the test environment
		testEnv.clearFailures()
		local ok, err = try( self.setup )
		if not ok then
			error( "setup() raised error: " .. tostring( err ) )
		end

		-- run the test
		local testName = self.name .. "." .. test.name
		print( "[ RUN      ]", testName )
		local testStartTime = util.tick()
		ok, err = try( test.func )

		-- check the results
		local time = util.elapsed( testStartTime )
		local failures = testEnv.getFailures()
		test.passed = ok and #failures == 0
		test.failures = failures
		test.err = err
		test.time = time

		local statusStr = "[       OK ]"
		if test.err then
			statusStr = "[  ERRORS  ]"
		elseif #test.failures > 0 then
			statusStr = "[  FAILED  ]"
		end
		print( statusStr, testName .. " (" .. util.formatTime( time ) .. ")" )

		-- update stats
		self.errors = self.errors + ( err and 1 or 0 )
		self.failures = self.failures + #failures

		-- teardown the test environment
		ok, err = try( self.teardown )
		if not ok then
			error( "teardown() raised error: " .. tostring( err ) )
		end
	end
	self.time = util.elapsed( suiteStartTime )
	print( "[----------]", testsStr .. " from " .. self.name .. " (" .. util.formatTime( self.time ) .. " total)" )
end

return Suite
