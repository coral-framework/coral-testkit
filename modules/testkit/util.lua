--------------------------------------------------------------------------------
--- TestKit Utility Functions
--------------------------------------------------------------------------------

local osClock = os.clock

local function tick()
	return osClock()
end

local function elapsed( startTime )
	local dt = tick() - startTime
	return dt < 0.001 and 0 or dt
end

local function formatTime( t )
	if t < 1 then
		return math.floor( t * 1000 ) .. " ms"
	end
	return t .. " sec"
end

local function formatCount( count, singular, plural )
	return count .. " " .. ( count == 1 and singular or plural )
end

return {
	tick = tick,
	elapsed = elapsed,
	formatTime = formatTime,
	formatCount = formatCount,
}
