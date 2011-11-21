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

local scriptPattern = "Tests%.lua$"
local testPattern = nil
local numIterations = 1
local breakOnFailure = false
local shuffleIsOn = false
local outputFilename = nil
local askedForHelp = false

local flags = {
	-- Aliases
	s = 'script',
	t = 'test',
	r = 'repeat',
	b = 'breakonfailure',
	o = 'output',
	h = 'help',
}

function flags.script( flag, pattern )
	if not pattern then
		return nil, "missing script pattern"
	end
	scriptPattern = pattern
	return 1
end

function flags.test( flag, pattern )
	if not pattern then
		return nil, "missing test name pattern"
	end
	testPattern = pattern
	return 1
end

flags["repeat"] = function( flag, num )
	if not num then
		return nil, "missing number of repeats"
	end
	num = tonumber( num )
	if not num then
		return nil, "invalid number of repeats"
	end
	if num < 1 then
		num = 2 ^ 31
	end
	numIterations = num
	return 1
end

function flags.breakonfailure()
	breakOnFailure = true
end

function flags.shuffle()
	shuffleIsOn = true
end

function flags.output( flag, filename )
	if not filename then
		return nil, "missing output filename"
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
  -s, --script PATTERN   Load scripts matching PATTERN (default: Tests%.lua$).
  -t, --test PATTERN     Only execute tests matching PATTERN (default: ".").
  -r, --repeat N         Run the tests N times (zero = forever; default: 1).
  -b, --breakonfailure   Stop repeating the tests at the first failure.
      --shuffle          Run the tests in a random order.
  -o, --output FILENAME  Write test results to a file (in JUnit's XML format).
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
	local stats = { tests = 0 }

	-- load test suites from test scripts in the listed dirs
	print( "Loading files that match the pattern " .. util.quoteString( scriptPattern ) )
	for _, dir in ipairs( dirs ) do
		print( "Looking for test scripts in " .. dir )
		for filename in lfs.dir( dir ) do
			if filename:match( scriptPattern ) then
				local ok, suite = pcall( Suite.loadFrom, dir .. '/' .. filename )
				if ok then
					suite:filter( testPattern )
					if #suite.tests > 0 then
						suites[#suites + 1] = suite
						stats.tests = stats.tests + #suite.tests
					end
					print( "  Loaded " .. filename .. " (".. #suite.allTests .. " tests)" )
				else
					print( "  Error in " .. filename .. ": " .. tostring( suite ) )
					return -2
				end
			end
		end
	end

	-- issue a notice if there is a test filter in effect
	if testPattern then
		print( "\nNotice: filtering tests by pattern " .. util.quoteString( testPattern ) )
	end

	local failed = false
	for iteration = 1, numIterations do
		stats.passed = 0
		stats.errors = 0
		stats.failures = 0
		stats.time = 0

		if iteration > 1 then
			print( "\nRepeating all tests (iteration " .. iteration .. ") . . ." )
			if shuffleIsOn then
				util.shuffle( suites )
			end
		end

		-- print initial stats
		local numTestsStr = util.formatCount( stats.tests, "test", "tests" )
		local numSuitesStr = util.formatCount( #suites, "test suite", "test suites" )
		print( "\n[==========] Running " .. numTestsStr .. " from " .. numSuitesStr .. "." )

		-- run all test suites
		local startTime = util.tick()
		for _, suite in ipairs( suites ) do
			if shuffleIsOn then
				suite:shuffle()
			end
			suite:run()
			stats.errors = stats.errors + suite.errors
			stats.failures = stats.failures + suite.failures
		end

		stats.time = util.elapsed( startTime )

		-- print final stats
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

		failed = failed or ( stats.passed < stats.tests )
		if failed and breakOnFailure then
			break
		end
	end

	print( "" )

	if outputFilename then
		report.writeToXml( stats, suites, outputFilename )
	end

	return failed and -1 or 0
end
