local lfs = require "lfs"
local path = require "lua.path"
local cmdline = require "lua.cmdline"
local Suite = require "testkit.Suite"
local report = require "testkit.report"
local util = require "testkit.util"
local print = print
local ipairs = ipairs

-------------------------------------------------------------------------------
-- Command-Line Handler Functions
-------------------------------------------------------------------------------

local outputFilename = nil
local askedForHelp = false

local flags = {
	-- Aliases
	o = 'output',
	h = 'help',
}

function flags.output( flag, filename )
	if not filename then
		return nil, "missing filename"
	end
	outputFilename = filename
	return 1
end

function flags.help()
	askedForHelp = true
	print [[
Usage: testkit.Run [options] DIR ...
Description:
  Runs all test scripts from the specified dirs.
Available options:
  -o, --output FILENAME  Write test results to a file.
  -h, --help             Show this help message.]]
end

-------------------------------------------------------------------------------
-- Launcher Component
-------------------------------------------------------------------------------

local Component = co.Component( "testkit.Run" )

function Component:main( args )
	-- command-line processing
	if #args == 0 then
		flags.help()
		return 0
	end

	local dirs, errorString = cmdline.process( args, flags )
	if not dirs then
		print( errorString )
		return -2
	end

	if askedForHelp then
		return 0
	end

	if #dirs < 1 then
		print( "Error: you must specify a list of dirs to load the test scripts from." )
		return -2
	end

	local suites = {}
	local stats = { tests = 0, passed = 0, errors = 0, failures = 0, time = 0 }

	-- load test suites from test scripts in the listed dirs
	for _, dir in ipairs( dirs ) do
		print( "Looking for test scripts in " .. dir )
		for filename in lfs.dir( dir ) do
			if filename:match( "Tests%.lua$" ) then
				print( "  Loading " .. filename )
				local ok, res = pcall( Suite.loadFrom, dir .. '/' .. filename )
				if ok then
					suites[#suites + 1] = res
					local numTests = #res.tests
					stats.tests = stats.tests + numTests
					print( "    Loaded " .. numTests .. " tests" )
				else
					print( "    Error: " .. tostring( res ) )
					return -2
				end
			end
		end
	end

	local numTestsStr = util.formatCount( stats.tests, "test", "tests" )
	local numSuitesStr = util.formatCount( #suites, "test suite", "test suites" )

	print( "\n[==========] Running " .. numTestsStr .. " from " .. numSuitesStr .. "." )

	-- run all test suites
	local startTime = util.tick()
	for _, suite in ipairs( suites ) do
		suite:run()
		stats.errors = stats.errors + suite.errors
		stats.failures = stats.failures + suite.failures
	end

	stats.time = util.elapsed( startTime )
	local timeStr = util.formatTime( stats.time )

	print( "\n[==========] " .. numTestsStr .. " from " .. numSuitesStr .. " ran. (" .. timeStr .. " total)" )

	stats.passed = stats.tests - stats.errors - stats.failures
	assert( stats.passed >= 0 )

	if stats.passed > 0 then
		print( "[  PASSED  ] " .. util.formatCount( stats.passed, "test.", "tests." ) )
	end

	if stats.errors > 0 then
		local statusStr = "[  ERRORS  ] "
		print( statusStr .. util.formatCount( stats.errors, "test", "tests" ) .. ", listed below:" )
		for _, suite in ipairs( suites ) do
			if suite.errors > 0 then
				for _, test in ipairs( suite.tests ) do
					if test.err then
						print( statusStr .. suite.name .. "." .. test.name )
					end
				end
			end
		end
	end

	if stats.failures > 0 then
		local statusStr = "[  FAILED  ] "
		print( statusStr .. util.formatCount( stats.failures, "test", "tests" ) .. ", listed below:" )
		for _, suite in ipairs( suites ) do
			if suite.failures > 0 then
				for _, test in ipairs( suite.tests ) do
					if #test.failures > 0 then
						print( statusStr .. suite.name .. "." .. test.name )
					end
				end
			end
		end
	end

	print( "" )

	if outputFilename then
		report.writeToXml( stats, suites, outputFilename )
	end

	return stats.passed < stats.tests and -1 or 0
end
