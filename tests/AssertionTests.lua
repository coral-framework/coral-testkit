function assertTrue()
	ASSERT_TRUE( 3.14 == 3.14 )
end

function assertEq()
	ASSERT_EQ( "str", "str" )
	--ASSERT_EQ( 3.1444445, 3.1444446 )
end

function assertDoubleEq()
	ASSERT_DOUBLE_EQ( 3.1444445, 3.1444446 )
end

-- make sure setup() and teardown() are being called

local state = "undefined"

function setup()
	state = "ok"
end

function teardown()
	state = "invalid"
end

function cleanEnvironmentOne()
	ASSERT_EQ( state, "ok" )
	state = "dirty"
end

function cleanEnvironmentTwo()
	ASSERT_EQ( state, "ok" )
	state = "dirty"
end
