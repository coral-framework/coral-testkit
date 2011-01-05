local function tError( m )
	error( { message = m, testError = true } )
end

local function normalizeValue( value )
	if type( value ) == 'function' then return value() end
	if type( value ) == 'table' then error( "table values are not suported in comparisons." ) end
	return value
end

function assertEquals( value, expected, message )
	value = normalizeValue( value )
	expected = normalizeValue( expected )
 	if value ~= expected then
		if message then
			tError( message )
		else 
			tError( "assertion failed: got " .. tostring(value) .. " when expecting " .. expected )
		end
	end
end
