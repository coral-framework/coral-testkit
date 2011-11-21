--------------------------------------------------------------------------------
--- TestKit Utility Functions
--------------------------------------------------------------------------------

local osClock = os.clock
local sformat = string.format

-- Returns the current time stamp
local function tick()
	return osClock()
end

-- Returns the elapsed time since a reference time stamp
local function elapsed( startTime )
	local dt = tick() - startTime
	return dt < 0.001 and 0 or dt
end

-- Format an elapsed time in seconds
local function formatTime( t )
	if t < 1 then
		return math.floor( t * 1000 ) .. " ms"
	end
	return t .. " sec"
end

-- Formats a number followed by a noun either in singular or plural
local function formatCount( count, singular, plural )
	return count .. " " .. ( count == 1 and singular or plural )
end

-- Formats an escaped string between quotes.
local function quoteString( str )
	if str:find( "\n", nil, true ) then
		return "[[" .. str:gsub( "\n", "\n    " ) .. "\n]]"
	else
		return '"' .. str .. '"'
	end
end

-- Extracts the source file from the 'source' field of a lua_Debug table
local function getSource( info )
	return info.source:sub( 2 )
end

-- Fisher-Yates shuffle
math.randomseed( os.time() )
local function shuffle( t )
	for n = #t, 1, -1 do
		local k = math.random( n )
		t[n], t[k] = t[k], t[n]
	end
end

return {
	tick = tick,
	elapsed = elapsed,
	formatTime = formatTime,
	formatCount = formatCount,
	quoteString = quoteString,
	getSource = getSource,
	shuffle = shuffle,
}
