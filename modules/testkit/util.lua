--------------------------------------------------------------------------------
--- TestKit Utility Functions
--------------------------------------------------------------------------------

local osClock = os.clock

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

-- Extracts the source file from the 'source' field of a lua_Debug table
local function getSource( info )
	return info.source:sub( 2 )
end

return {
	tick = tick,
	elapsed = elapsed,
	formatTime = formatTime,
	formatCount = formatCount,
	getSource = getSource
}
