--------------------------------------------------------------------------------
--- TestKit Report Writer
--------------------------------------------------------------------------------

local path = require "lua.path"
local printVar = require "lua.printVar"

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

	-- write
	local function w( ... ) file:write( ... ) end

	-- write a line
	local function wl( ... ) w( ... ) w( "\n" ) end

	-- write an XML attribute
	local function wa( n, v ) w( " ", n, "=" ) w( "\"", v, "\"" ) end

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
					w( "\t\t\t<failure" ) wa( "message", failure.message ) wa( "type", "" ) wl( "><![CDATA[" )
					local info = failure.info
					w( "\t\t\t\t", info.source, ":", info.currentline )
					if info.name then
						w( " in function ", info.name )
					end
					wl( "\n]]></failure>" )
				end

				if test.err then
					w( "\t\t\t<error" ) wa( "message", test.err.message ) wa( "type", "" ) w( "><![CDATA[" )
					w( test.err.traceback )
					wl( "]]></error>" )
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
