function isTrue()
	EXPECT_TRUE( 3.1444445 ~= 3.1444446 )
end

function isEqual()
	EXPECT_EQ( 3.144444, 3.144444 )
end

function isNotEqual()
	EXPECT_NE( 3.1444445, 3.1444446 )
end

function isLesserThan()
	EXPECT_LT( 3.1444445, 3.1444446 )
end

function assertDoubleEq()
	EXPECT_DOUBLE_EQ( 3.1444445, 3.1444446 )
end

function erroneous()
	EXPECT_ERROR( function() oopsAnError()() end )
end

local function raiseException()
	co.raise( "co.IllegalStateException", "omg an exception" )
end

function exceptional()
	EXPECT_EXCEPTION( "co.IllegalStateException", function() raiseException() end )
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
