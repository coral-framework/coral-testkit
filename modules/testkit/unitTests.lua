local function tError( m, default )
	error( { message = m or ( "assertion failed: " .. default ), testError = true } )
end

local function normalizeValue( value )
	if type( value ) == 'function' then return value() end
	if type( value ) == 'table' then error( "table values are not suported in comparisons." ) end
	return value
end

function assertTrue( condition, message )
	condition = normalizeValue( condition )
	if type( condition ) ~= 'boolean' then error( "An assertrion should recive a bolean value and not a '" .. type(condition) .. "' type." ) end

	if not condition then tError( message, "The condition should be true, but it actually was false" ) end
end

function assertEquals( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )
 	if value ~= expected then
		tError( message, "got " .. tostring(value) .. " when expecting " .. expected )
	end
end
