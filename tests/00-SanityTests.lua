-- Test the functions for testing testing functions
-- i.e. EXPECT_FATAL_FAILURE() and EXPECT_NONFATAL_FAILURE()

local function noFailure()
	EXPECT_TRUE( true )
	ASSERT_EQ( 2, 2 )
end

local function aNonFatalFailure()
	noFailure()
	EXPECT_TRUE( false )
	EXPECT_EQ( 1, 2 )
end

local function aFatalFailure()
	aNonFatalFailure()
	ASSERT_TRUE( false )
	ASSERT_EQ( 1, 2 )
end

local function anError()
	omgAnError()()
end

function noFailures()
	EXPECT_TRUE( true )
	ASSERT_EQ( 2, 2 )
end

function nonFatalFailures()
	EXPECT_NONFATAL_FAILURE( aNonFatalFailure )
	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Expected: 1(.+)Actual: 2", aNonFatalFailure )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: no message matched the pattern", function()
		EXPECT_NONFATAL_FAILURE( "nonmatching", aNonFatalFailure )
	end )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: got a fatal failure", function()
		EXPECT_NONFATAL_FAILURE( aFatalFailure )
	end )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: got an error", function()
		EXPECT_NONFATAL_FAILURE( anError )
	end )
end

function fatalFailures()
	EXPECT_FATAL_FAILURE( aFatalFailure )
	EXPECT_FATAL_FAILURE( "SanityTests%.lua(.+)Expected: 1(.+)Actual: 2", aFatalFailure )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: no message matched the pattern", function()
		EXPECT_FATAL_FAILURE( "nonmatching", aFatalFailure )
	end )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: got 2 non%-fatal failures", function()
		EXPECT_FATAL_FAILURE( aNonFatalFailure )
	end )

	EXPECT_NONFATAL_FAILURE( "SanityTests%.lua(.+)Actual: got an error", function()
		EXPECT_FATAL_FAILURE( anError )
	end )
end
