local debug = require "debug"
local util = require "testkit.util"
local type = type
local pcall = pcall
local assert = assert
local tostring = tostring
local mabs = math.abs
local smatch = string.match
local coType = co.Type
local coGetException = co.getException

-------------------------------------------------------------------------------
-- TestKit Test Environment
-------------------------------------------------------------------------------

local env = setmetatable( {}, { __index = _ENV } )

-------------------------------------------------------------------------------
-- Failure Reporting Functions
-------------------------------------------------------------------------------

local failures

local failureMT = { __tostring = function( failure )
	return failure.text
end }

function env.clearFailures()
	failures = {}
end

function env.getFailures()
	return failures
end

local function addFailure( message, level )
	local info = debug.getinfo( level + 1, "nSl" )
	failures[#failures + 1] = setmetatable( {
		message = message,
		text = util.getSource( info ) .. ":" .. info.currentline .. ": Failure\n" .. message
	}, failureMT )
end

local function fail()
	local lastFailure = failures[#failures]
	lastFailure.fatalFailure = true
	error( lastFailure )
end

-------------------------------------------------------------------------------
-- Failure Assertions (tests if a testing function reports failures correctly)
-------------------------------------------------------------------------------

local function expectFailure( messagePattern, closure, expectFatal, level )
	-- messagePattern is optional
	if not closure then
		closure = messagePattern
		messagePattern = nil
	end
	assert( messagePattern == nil or type( messagePattern ) == 'string' )
	assert( type( closure ) == 'function' )

	local originalNumFailures = #failures
	local ok, err = pcall( closure )
	local numNewFailures = #failures - originalNumFailures
	assert( numNewFailures >= 0 )

	-- extract the new failures
	local newFailures = {}
	for i = 1, numNewFailures do
		newFailures[i] = failures[originalNumFailures + i]
		failures[originalNumFailures + i] = nil
	end
	assert( #failures == originalNumFailures )

	-- check general expectations
	local failMsg
	local isFatalFailure = ( not ok and type( err ) == 'table' and err.fatalFailure )
	if expectFatal ~= isFatalFailure or numNewFailures == 0 then
		failMsg = "Expected: a " .. ( expectFatal and "" or "non-" ) .. "fatal failure\n  Actual: got "
		if isFatalFailure then
			failMsg = failMsg .. "a fatal failure"
		elseif not ok then
			failMsg = failMsg .. "an error"
		elseif numNewFailures == 0 then
			failMsg = failMsg .. "no failure whatsoever"
		else
			failMsg = failMsg .. util.formatCount( numNewFailures, "non-fatal failure", "non-fatal failures" )
		end
		if err then
			failMsg = failMsg .. "\n Message: \"" .. tostring( err ) .. '"'
		end
	end

	-- look for a matching message if a pattern was provided
	if not failMsg and messagePattern then
		local foundMatch = false
		for i, failure in ipairs( newFailures ) do
			if smatch( failure.text, messagePattern ) then
				foundMatch = true
				break
			end
		end
		if not foundMatch then
			failMsg = "  Expected: a failure matching the pattern " .. util.quoteString( messagePattern )
						.. "\n    Actual: no message matched the pattern"
			for i, failure in ipairs( newFailures ) do
				failMsg = failMsg .. "\nFailure #" .. i .. ": " .. util.quoteString( tostring( failure ) )
			end
		end
	end

	if failMsg then
		addFailure( failMsg, level + 1 )
	end
	return failMsg == nil
end

function env.EXPECT_FATAL_FAILURE( messagePattern, closure )
	return expectFailure( messagePattern, closure, true, 1 )
end

function env.EXPECT_NONFATAL_FAILURE( messagePattern, closure )
	return expectFailure( messagePattern, closure, false, 1 )
end

-------------------------------------------------------------------------------
-- Basic Assertions
-------------------------------------------------------------------------------

local function formatObject( object )
	return "(" .. tostring( object ) .. ")"
end

local formatters = {
	["string"] = util.quoteString,
	["table"] = formatObject,
	["function"] = formatObject,
	["thread"] = formatObject,
	["userdata"] = formatObject,
}

local function formatValue( v )
	return ( formatters[type( v )] or tostring )( v )
end

local function expectValue( expected, actual, level )
	if expected == actual then return true end
	addFailure( "Expected: " .. formatValue( expected ) .. "\n  Actual: " .. formatValue( actual ), level + 1 )
	return false
end

local function assertValue( expected, actual, level )
	return expectValue( expected, actual, level + 1 ) or fail()
end

function env.ASSERT_TRUE( condition )
	return assertValue( true, condition and true, 1 )
end

function env.EXPECT_TRUE( condition )
	return expectValue( true, condition and true, 1 )
end

function env.ASSERT_FALSE( condition )
	return assertValue( false, condition or false, 1 )
end

function env.EXPECT_FALSE( condition )
	return expectValue( false, condition or false, 1 )
end

function env.ASSERT_EQ( val1, val2 )
	return assertValue( val1, val2, 1 )
end

function env.EXPECT_EQ( val1, val2 )
	return expectValue( val1, val2, 1 )
end

-------------------------------------------------------------------------------
-- Floating-Point Assertions
-------------------------------------------------------------------------------

local epsilon = 0.000000001

local function expectNear( expected, actual, tolerance, level )
	-- auto-select a tolerance if not provided
	if not tolerance then
		local absExpected = mabs( expected )
		local absActual = mabs( actual )
		local absLargest = absExpected > absActual and absExpected or absActual
		tolerance = absLargest > 0.001 and epsilon or ( absLargest * epsilon )
	end
	local absError = mabs( actual - expected )
	if absError <= tolerance then return true end
	local message = string.format( " Expected: %.12f\n   Actual: %.12f\n    Error: %.24f\nTolerance: %.24f",
						expected, actual, absError, tolerance )
	addFailure( message, level + 1 )
	return false
end

local function assertNear( expected, actual, tolerance, level )
	return expectNear( expected, actual, tolerance, level + 1 ) or fail()
end

function env.ASSERT_DOUBLE_EQ( expected, actual )
	return assertNear( expected, actual, nil, 1 )
end

function env.EXPECT_DOUBLE_EQ( expected, actual )
	return expectNear( expected, actual, nil, 1 )
end

function env.ASSERT_NEAR( expected, actual, tolerance )
	return assertNear( expected, actual, tolerance, 1 )
end

function env.EXPECT_NEAR( expected, actual, tolerance )
	return expectNear( expected, actual, tolerance, 1 )
end

-------------------------------------------------------------------------------
-- Binary Assertions
-------------------------------------------------------------------------------

local binaryOps = {
	["~="] = function( v1, v2 ) return v1 ~= v2 end,
	["<"] = function( v1, v2 ) return v1 < v2 end,
	["<="] = function( v1, v2 ) return v1 <= v2 end,
	[">"] = function( v1, v2 ) return v1 > v2 end,
	[">="] = function( v1, v2 ) return v1 >= v2 end,
}

local function expectBinaryOp( val1, binOp, val2, level )
	local ok, res = pcall( binaryOps[binOp], val1, val2 )
	if ok and res then return true end
	local msg = ", which is false"
	if not ok then
		msg = ", but operation '" .. binOp .. "' raised an error\n Message: " .. tostring( res )
	end
	addFailure( "Expected: " .. formatValue( val1 ) .. " " .. binOp .. " " .. formatValue( val2 ) .. msg, level + 1 )
	return false
end

local function assertBinaryOp( val1, binOp, val2, level )
	return expectBinaryOp( val1, binOp, val2, level + 1 ) or fail()
end

function env.ASSERT_NE( val1, val2 )
	return assertBinaryOp( val1, "~=", val2, 1 )
end

function env.EXPECT_NE( val1, val2 )
	return expectBinaryOp( val1, "~=", val2, 1 )
end

function env.ASSERT_LT( val1, val2 )
	return assertBinaryOp( val1, "<", val2, 1 )
end

function env.EXPECT_LT( val1, val2 )
	return expectBinaryOp( val1, "<", val2, 1 )
end

function env.ASSERT_LE( val1, val2 )
	return assertBinaryOp( val1, "<=", val2, 1 )
end

function env.EXPECT_LE( val1, val2 )
	return expectBinaryOp( val1, "<=", val2, 1 )
end

function env.ASSERT_GT( val1, val2 )
	return assertBinaryOp( val1, ">", val2, 1 )
end

function env.EXPECT_GT( val1, val2 )
	return expectBinaryOp( val1, ">", val2, 1 )
end

function env.ASSERT_GE( val1, val2 )
	return assertBinaryOp( val1, ">=", val2, 1 )
end

function env.EXPECT_GE( val1, val2 )
	return expectBinaryOp( val1, ">=", val2, 1 )
end

-------------------------------------------------------------------------------
-- Exception and/or Error Assertions
-------------------------------------------------------------------------------

local function getActualError( actualType, actualMessage )
	local msg = "\n  Actual: "
	if actualType then
		msg = msg .. "got an exception of type " .. actualType
	elseif actualMessage then
		msg = msg .. "got an error"
	else
		msg = msg .. "the function ran smoothly"
	end
	if actualMessage then
		msg = msg .. "\n Message: " .. actualMessage
	end
	return msg
end

-- returns an error message, or nil on success
local function checkException( expectedType, messagePattern, actualType, actualMessage )
	if ( expectedType ~= actualType and expectedType ) or actualMessage == nil then
		local msg = "Expected: "
		if expectedType then
			msg = msg .. "an exception of type " .. expectedType
		elseif messagePattern then
			msg = msg .. "an error message matching the pattern " .. util.quoteString( messagePattern )
		else
			msg = msg .. "an error with any message"
		end
		return msg .. getActualError( actualType, actualMessage )
	end
	if messagePattern and actualMessage and not smatch( actualMessage, messagePattern ) then
		return "Expected: an error message matching the pattern " .. util.quoteString( messagePattern )
			.. "\n  Actual: the error does not match the pattern.\n Message: \"" .. actualMessage .. '"'
	end
end

local function expectException( expectedType, messagePattern, closure, level )
	-- check passed args (messagePattern is optional; if false, it means we expect no error)
	assert( not expectedType or type( expectedType ) == 'string' )
	if not closure then
		closure = messagePattern
		messagePattern = nil
	else
		assert( messagePattern == false or type( messagePattern ) == 'string' )
	end
	assert( type( closure ) == 'function' )

	local ok, err = pcall( closure )
	local actualType, message
	if not ok then
		actualType, message = coGetException( err )
		assert( message )
	end

	local failureMsg = checkException( expectedType, messagePattern, actualType, message )
	if failureMsg then
		addFailure( failureMsg, level + 1 )
	end

	return failureMsg == nil
end

local function assertException( expectedType, messagePattern, closure, level )
	return expectException( expectedType, messagePattern, closure, level + 1 ) or fail()
end

function env.ASSERT_EXCEPTION( expectedType, messagePattern, closure )
	return assertException( expectedType, messagePattern, closure, 1 )
end

function env.EXPECT_EXCEPTION( expectedType, messagePattern, closure )
	return expectException( expectedType, messagePattern, closure, 1 )
end

function env.ASSERT_ERROR( messagePattern, closure )
	return assertException( nil, messagePattern, closure, 1 )
end

function env.EXPECT_ERROR( messagePattern, closure )
	return expectException( nil, messagePattern, closure, 1 )
end

local function expectNoError( closure, level )
	local ok, err = pcall( closure )
	if not ok then
		addFailure( "Expected: no error" .. getActualError( coGetException( err ) ), level + 1 )
	end
	return ok
end

local function assertNoError( closure, level )
	return expectNoError( closure, level + 1 ) or fail()
end

function env.EXPECT_NO_ERROR( closure )
	return expectNoError( closure, 1 )
end

function env.ASSERT_NO_ERROR( closure )
	return assertNoError( closure, 1 )
end

return env
