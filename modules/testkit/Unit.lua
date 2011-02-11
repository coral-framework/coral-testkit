--------------------------------------------------------------------------------
--- Unit Testing
--------------------------------------------------------------------------------

---------------------------------------
-- Helper Functions
---------------------------------------

-- rises a test error. Used to diferentiate a regular error and a assertion error.
local function tError( m, default )
	error( { message = m or ( "assertion failed: " .. default ), testError = true } )
end

-- verifies if the given value is a function
local function normalizeValue( value )
	if type( value ) == 'function' then return value() end
	if type( value ) == 'table' then error( "table values are not suported in comparisons." ) end
	return value
end

---------------------------------------
-- Testing Methods
---------------------------------------

function ASSERT_TRUE( condition, message )
	condition = normalizeValue( condition )
	if type( condition ) ~= 'boolean' then error( "An assertion should recive a bolean value and not a '" .. type(condition) .. "' type." ) end

	if not condition then tError( message, "The condition should be true, but it actually was false" ) end
end

function ASSERT_EQUALS( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )
 	if value ~= expected then
		tError( message, "got " .. tostring(value) .. " when expecting " .. expected )
	end
end

function ASSERT_VECTOR3( vector1, vector2 )
	ASSERT_EQUALS( vector1.x, vector2.x, "The value of coordinate X is " .. tostring(vector1.x) .. " when the expected is " .. tostring(vector2.x) )
	ASSERT_EQUALS( vector1.y, vector2.y, "The value of coordinate Y is " .. tostring(vector1.y) .. " when the expected is " .. tostring(vector2.y) )
	ASSERT_EQUALS( vector1.z, vector2.z, "The value of coordinate Z is " .. tostring(vector1.z) .. " when the expected is " .. tostring(vector2.z) )
end

function EXPECT_EXCEPTION( errorMessage, func, ...  )
	local ok, err = pcall( func, table.unpack({...}) )
	if ok then 
		tError( "Expected to raise an exception but it didn't." ) 
	else
		if not err:match( errorMessage ) then tError( "An exception was raised but the message \"" .. err .. "\" didn't match with the expected:\"" .. errorMessage .. "\"" ) end
	end
end
