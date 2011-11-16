local debug = require "debug"

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

function env.addFailure( msg, level )
	level = level or 1
	failures[#failures + 1] = { message = msg, info = debug.getinfo( level, "nSl" ) }
end

-------------------------------------------------------------------------------
-- Assertion Functions
-------------------------------------------------------------------------------

local function addFailure( message )
	env.addFailure( message, 4 )
end

-- verifies if the given value is a function
local function normalizeValue( value )
	if type( value ) == 'function' then
		return value()
	end
	if type( value ) == 'table' then
		error( "table values are not suported in comparisons." )
	end
	return value
end

function env.ASSERT_TRUE( condition, message )
	condition = normalizeValue( condition )
	if type( condition ) ~= 'boolean' then
		error( "An assertion should recive a bolean value and not a '" .. type( condition ) .. "' type." )
	end

	if not condition then
		addFailure( message or "condition is false" )
	end
end

function env.ASSERT_EQ( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )

	if type(value) ~= type(expected) then
		error( "compared values are two different types" )
	end

 	if value ~= expected then
 		if not message then
 			message = "expected '" .. tostring( expected ) .. "', got '" .. tostring( value ) .. "'"
 		end
		addFailure( message )
	end
end

function env.ASSERT_DOUBLE_EQ( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )

	largerAbsolute = math.abs( ( ( value > expected ) and value ) or expected )
	delta = math.abs( ( math.abs( value ) - math.abs( expected ) ) )
	tolerance = ( ( largerAbsolute < 0.0001 ) and 0.0000001 ) or largerAbsolute * 0.0000001

	valueAbs = math.abs( value )
	expectedAbs = math.abs( expected )

	largerAbsolute = ( ( valueAbs > expectedAbs ) and  valueAbs ) or expectedAbs

	delta = math.abs( valueAbs - expectedAbs )
	tolerance = ( ( largerAbsolute < 1000 ) and 0.0000001 ) or largerAbsolute * 0.0000001

 	if delta > tolerance or ( expected * value ) < 0 then
 		if not message then
 			message = "expected '" .. tostring( expected ) .. "', got '" .. tostring( value ) .. "'"
 		end
		addFailure( message )
	end
end

function env.EXPECT_EXCEPTION( errorMessage, func, ...  )
	local ok, err = pcall( func, table.unpack({...}) )
	if ok then
		addFailure( "Expected to raise an exception but it didn't." )
	else
		if not err:match( errorMessage ) then
			addFailure( "An exception was raised but the message \"" .. err .. "\" didn't match with the expected:\"" .. errorMessage .. "\"" )
		end
	end
end

return env
