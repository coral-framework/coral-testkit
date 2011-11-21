-- make sure setup() and teardown() are called for every test case

local state = "undefined"

function setup()
	state = "ok"
end

function teardown()
	state = "invalid"
end

function testOne()
	ASSERT_EQ( state, "ok" )
	state = "dirtyOne"
end

function testTwo()
	ASSERT_EQ( state, "ok" )
	state = "dirtyTwo"
end
