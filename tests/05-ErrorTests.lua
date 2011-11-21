local function raiseIllegalArgument()
	co.raise( "co.IllegalArgumentException", "illegal arg" )
end

local function raiseMissingInput()
	co.raise( "co.MissingInputException", "missing input" )
end

local function raiseError()
	omgAnError()()
end

local function noError() return true end

function exceptions()
	EXPECT_EXCEPTION( "co.IllegalArgumentException", raiseIllegalArgument )
	EXPECT_EXCEPTION( "co.IllegalArgumentException", "illegal arg", raiseIllegalArgument )
	ASSERT_EXCEPTION( "co.MissingInputException", raiseMissingInput )
	ASSERT_EXCEPTION( "co.MissingInputException", "missing input", raiseMissingInput )
	EXPECT_FATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: got an exception of type co%.MissingInputException', function()
		ASSERT_EXCEPTION( "co.IllegalArgumentException", raiseMissingInput )
	end )
	EXPECT_FATAL_FAILURE( "ErrorTests%.lua(.+)Actual: the error does not match the pattern", function()
		ASSERT_EXCEPTION( "co.MissingInputException", "wrong message", raiseMissingInput )
	end )
	EXPECT_NONFATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: got an error', function()
		EXPECT_EXCEPTION( "co.MissingInputException", raiseError )
	end )
	EXPECT_NONFATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: the function ran smoothly', function()
		EXPECT_EXCEPTION( "co.MissingInputException", noError )
	end )
end

function errors()
	EXPECT_ERROR( raiseIllegalArgument )
	EXPECT_ERROR( "illegal arg", raiseIllegalArgument )
	ASSERT_ERROR( raiseError )
	ASSERT_ERROR( "attempt to call global 'omgAnError' %(a nil value%)", raiseError )
	EXPECT_FATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: the error does not match the pattern', function()
		ASSERT_ERROR( "wrong message", raiseMissingInput )
	end )
	EXPECT_NONFATAL_FAILURE( "ErrorTests%.lua(.+)Actual: the function ran smoothly", function()
		EXPECT_ERROR( noError )
	end )
end

function noErrors()
	EXPECT_NO_ERROR( noError )
	ASSERT_NO_ERROR( noError )
	EXPECT_FATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: got an error', function()
		ASSERT_NO_ERROR( raiseError )
	end )
	EXPECT_NONFATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: got an error', function()
		EXPECT_NO_ERROR( raiseError )
	end )
	EXPECT_NONFATAL_FAILURE( 'ErrorTests%.lua(.+)Actual: got an exception of type co%.MissingInputException', function()
		EXPECT_NO_ERROR( raiseMissingInput )
	end )
end
