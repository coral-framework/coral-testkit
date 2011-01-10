require "testkit.FluentTests"

----------------------------------------------
-- Phrase implementations
----------------------------------------------
function aOpenedAndClearedCalculator()
	-- creates the scenario
	scenario.calculator = 0
end

function addingTo(a, b)
	scenario.calculator = a + b
	scenario.title = "the result is " .. scenario.calculator
end


function theCalculatorShouldDisplay( number )	
	return ( scenario.calculator == number )
end

function theCalculatorTitleShouldBe( title )	
	return ( scenario.title == title )
end

function advancedOptionsShouldBeEnabled()
	return true
end

----------------------------------------
-- Test definition
----------------------------------------

GIVEN "a opened and cleared calculator"
WHEN "adding 2 to 3"
THEN "the calculator should display 5"
AND "the calculator title should be 'the result is 5'"
AND "advanced options should be enabled"

ENDTEST()
