local debug = require "debug"
local util = require "testkit.util"
local type = type
local pcall = pcall
local assert = assert
local tostring = tostring
local mabs = math.abs
local smatch = string.match
local sformat = string.format
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

function env.clearFailures()
	failures = {}
end

function env.getFailures()
	return failures
end

local function addFailure( message, level )
	local info = debug.getinfo( level + 1, "nSl" )
	failures[#failures + 1] = {
		message = message,
		text = util.getSource( info ) .. ":" .. info.currentline .. ": Failure\n" .. message
	}
end

local function fail()
	local lastFailure = failures[#failures]
	lastFailure.fatalFailure = true
	error( lastFailure )
end

-------------------------------------------------------------------------------
-- Basic Assertions
-------------------------------------------------------------------------------

local function formatValue( v )
	if type( v ) == 'string' then
		return string.format( '%q', v )
	else
		return tostring( v )
	end
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
	return assertValue( true, condition, 1 )
end

function env.EXPECT_TRUE( condition )
	return expectValue( true, condition, 1 )
end

function env.ASSERT_FALSE( condition )
	return assertValue( false, condition, 1 )
end

function env.EXPECT_FALSE( condition )
	return expectValue( false, condition, 1 )
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

local epsilon = 0.0000001

local function expectNear( expected, actual, tolerance, level )
	-- auto-select a tolerance if not provided
	if not tolerance then
		local absExpected = mabs( expected )
		local absActual = mabs( actual )
		local absLargest = absExpected > absActual and absExpected or absActual
		tolerance = absLargest < 0.0001 and epsilon or absLargest * epsilon
	end
	local absError = mabs( actual - expected )
	if absError <= tolerance then return true end
	local message = string.format( " Expected: %f\n   Actual: %f    Error: %fTolerance: %f",
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
	if binaryOps[binOp]( val1, val2 ) then return true end
	local message = "Expected: " .. formatValue( val1 ) .. " " .. binOp .. " " .. formatValue( val2 ) .. ", which is false"
	addFailure( message, level + 1 )
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

-- returns an error message, or nil on success
local function checkException( expectedType, messagePattern, actualType, actualMessage )
	if expectedType ~= actualType then
		local msg = "Expected: "
		if expectedType then
			msg = msg .. "an exception of type " .. expectedType
		elseif messagePattern then
			msg = msg .. "an error with a message matching the pattern " .. sformat( '%q', messagePattern )
		elseif messagePattern == nil then
			msg = msg .. "an error with any message"
		else -- messagePattern == false
			msg = msg .. "no error"
		end
		msg = msg .. "\n  Actual: "
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
	if messagePattern then
		if not actualMessage or not smatch( actualMessage, messagePattern ) then
			return "Expected: a message matching the pattern " .. sformat( '%q', messagePattern )
				.. "\n  Actual: it doesn't match the pattern.\n Message: \"" .. actualMessage .. '"'
		end
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
		local exceptionType, message = coGetException( err )
		addFailure( checkException( nil, false, exceptionType, message ), 1 )
	end
	return ok
end

function env.EXPECT_NO_ERROR( closure )
	return expectNoError( closure, 1 )
end

function env.ASSERT_NO_ERROR( closure )
	return expectNoError( closure, 1 ) or fail()
end

-------------------------------------------------------------------------------
-- Failure Assertions (tests if a testing function reports failures correctly)
-------------------------------------------------------------------------------



return env
