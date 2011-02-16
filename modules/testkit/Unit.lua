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

function ASSERT_EQ( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )
	
	if type(value) ~= type(expected) then error( "compared values are two different types." ) end
	
 	if value ~= expected then
		tError( message, "got " .. tostring(value) .. " when expecting " .. expected )
	end
end

function ASSERT_DOUBLE_EQ( value, expected, message )
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
	
 	if  delta > tolerance or ( expected * value ) < 0 then
		tError( message, "got " .. tostring(value) .. " when expecting " .. expected )
	end
end

function EXPECT_EXCEPTION( errorMessage, func, ...  )
	local ok, err = pcall( func, table.unpack({...}) )
	if ok then 
		tError( "Expected to raise an exception but it didn't." ) 
	else
		if not err:match( errorMessage ) then tError( "An exception was raised but the message \"" .. err .. "\" didn't match with the expected:\"" .. errorMessage .. "\"" ) end
	end
end

