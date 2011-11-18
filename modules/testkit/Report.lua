--------------------------------------------------------------------------------
--- TestKit Report Writer
--------------------------------------------------------------------------------

local path = require "lua.path"
local sByte = string.byte
local sGSub = string.gsub
local sFormat = string.format

local xmlEscapes = {
	['<'] = "&lt;",
	['>'] = "&gt;",
	['&'] = "&amp;",
	['"'] = "&quot;",
}

local function xmlEscaper( c )
	local escape = xmlEscapes[c]
	if not escape then
		escape = sFormat( "&#x%.2X;", sByte( c ) )
	end
	return escape
end

local function xmlEscape( str )
	return sGSub( str, "[%c<>&\"]", xmlEscaper )
end

local file

-- write strings


-- writes a line


-- writes an XML attribute


-- replaces double quotes with single quotes
local function escape( text ) return string.gsub( text, "\"", "'" ) end

-- Writes test results to an XML file in the JUnit format
local function writeToXml( stats, suites, filename )
	local dirPath, baseName = path.split( filename )
	path.makePath( dirPath )

	local file = assert( io.open( filename, "w" ) )
	local function w( ... ) file:write( ... ) end

	-- write a line
	local function wl( ... ) w( ... ) w( "\n" ) end

	-- write an XML attribute
	local function wa( name, value )
		w( " ", name, "=" )
		if value == nil then
			w( '""' )
		else
			w( '"', xmlEscape( value ), '"' )
		end
	end

	-- write an error in a test case
	local function wError( kind, type, message, text )
		w( "\t\t\t<", kind ) wa( "type", type ) wa( "message", message )
		wl( "><![CDATA[", text, "]]></", kind, ">" )
	end

	wl( "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" )
	w( "<testsuites" )
 	wa( "name", "All TestKit Tests" )
	wa( "tests", stats.tests )
	wa( "errors", stats.errors )
	wa( "failures", stats.failures )
	wa( "time", stats.time )
	wa( "timestamp", os.date "%Y-%m-%d%Z%H:%M:%S" )
	wl( ">" )

	for _, suite in ipairs( suites ) do
		w( "\t<testsuite" )
		wa( "name", suite.name )
		wa( "tests", #suite.tests )
		wa( "errors", suite.errors )
		wa( "failures", suite.failures )
		wa( "time", suite.time )
		wl( ">" )

		for _, test in ipairs( suite.tests ) do
			local status = "run"
			if test.err then
				status = "error"
			elseif #test.failures > 0 then
				status = "failure"
			end

			w( "\t\t<testcase" ) wa( "name", test.name ) wa( "status", status ) wa( "time", test.time )

			if test.passed then
				wl( " />" )
			else
				wl( ">" )

				for k, failure in ipairs( test.failures ) do
					wError( "failure", "", failure.message, failure.text )
				end

				if test.err then
					wError( "error", test.err.type, test.err.message, test.err.traceback )
				end

				wl( "\t\t</testcase>" )
			end
		end
		wl( "\t</testsuite>" )
	end
	wl( "</testsuites>" )

	file:close()
end

return {
	writeToXml = writeToXml
}
