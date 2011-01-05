--the current scenario
local scenario = {}

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


function parseAndRun(s)
	--concact with camel case, parses the parameters and runs the function	
	local functionName = ""
	local currentWord = ""
	local stringParam = ""
	local writingStringParam = false
	local params = {}
	-- added to evaluate the last word
	s = s .. " "
	for i = 1, #s do
	    local c = s:sub(i,i)
		
		if c == " " and not writingStringParam then 
			local number = tonumber( currentWord )
			if number then
				table.insert( params, number )
			else
				functionName = functionName .. currentWord
			end
			currentWord = ""
		elseif c == "," or c == "." then  -- TODO: Passar para gmatch
		elseif c == "'" then
			--clossing string
			if writingStringParam then
				table.insert( params, stringParam )
				stringParam = ""
			else
				writingStringParam = true
			end
		else
			-- writes the character on the right place
			if writingStringParam then stringParam = stringParam .. c
			else
				if #currentWord == 0 and #functionName ~= 0 then c = c:upper() end
				currentWord = currentWord .. c
			end
		end
	end

	if not _G[functionName] then 
		error( "function '".. functionName .. "' not found!\n" )
	end
	return _G[functionName]( table.unpack( params ) )
end

function GIVEN(s)
	scenario.expression = "\n\tgiven " .. s
	parseAndRun(s)
end

function WHEN(s)
	scenario.expression = scenario.expression .. "\n\twhen " .. s
	parseAndRun(s)
end

function THEN(s)
	local ok = parseAndRun( s ) 
	if not ok then 
		scenario.hasInvalidCondition = true 
		if not scenario.invalidCondition then 
			scenario.invalidCondition = s 
		else 
			scenario.invalidCondition  = scenario.invalidCondition .. ", " .. s 
		end
	end 
end

function AND(s)
	THEN(s)
end

function ENDTEST()
	if scenario.hasInvalidCondition then
		print( "The case:" .. scenario.expression .. "\n has faild on the conditions: \27[31;1m" .. scenario.invalidCondition .. "\27[0m" )
	else
		print ( "\27[32;1mAll tests passed!!!\27[0m" )
	end
end

GIVEN "a opened and cleared calculator"
WHEN "adding 2 to 3"
THEN "the calculator should display 5"
AND "the calculator title should be 'the result is 5'"
AND "advanced options should be enabled"

ENDTEST()


