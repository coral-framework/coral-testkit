--------------------------------------------------------------------------------
--- Test Report Generator
--------------------------------------------------------------------------------

local path = require "path"
local lfs = require "lfs"

local file

---------------------------------------
-- Helper Functions
---------------------------------------

local function w( ... ) file:write( ... ) end

-- writes a line
local function wl( ... ) w( ... ); w( "\n" ) end  

-- writes a xml attribute
local function wa( n, v ) w( " ", n, "=" ); w( "\"", v, "\"" )  end

-- replaces double quotes by a single quote
local function escape( text ) return string.gsub( text, "\"", "'" ) end 

-- creates a folder if necessary, the outputfile and returns a file handle.
-- if an error occours returns nil and a error message
local function openReportFile( xmlReportFileName )
	if not xmlReportFileName then 
		return nil, "The output file name was not given." 
	end
	local xmlReportFileName = path.normalize( lfs.currentdir() .. "/" .. xmlReportFileName )

	local outputDir = xmlReportFileName:match("(.*)/[^/]*")
	if not path.exists( outputDir ) and outputDir ~= "" then
		print ( "Creating output folder: " .. outputDir )
		path.makePath( outputDir )
	end

	print( "Writing report to file: " .. xmlReportFileName )

	local file, err = io.open( xmlReportFileName, "w" )
	if err then return nil, ( "The file could not be opened. " .. err ) end

	return file
end

---------------------------------------
-- Report Methods
---------------------------------------

-- writes the test suits results to the the xml report in the JUnit format 
local M = {}
function M.writeToXml( total, suits, fileName )
	
	local f, err = openReportFile( fileName )
	if err then print( err ); return 1 end
	file = f

	wl( "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" )
	w( "<testsuites" )
 	wa( "name", "All Tests" )
	wa( "tests", total ) wl ">"

	for i,s in ipairs( suits ) do
		w "<testsuite" 
		wa( "name", s.readableName )
		wa( "tests", #s.testCases ) 
		wa( "errors", s.testErrors )
		wa( "failures", s.failures ) wl ">"

		for j,c in ipairs( s.testCases ) do
			status = "run"
			body = function() end
			if c.err or c.failure then 
				status = "error" 
				body = function() 
							w "\t\t<error" wa( "type", escape( c.errorMessage ) ) wl "/>"  
						end
			end

			w "\t<testcase" wa( "name", c.readableName ) wa( "status", status ) wl ">"
			body()
			wl "\t</testcase>"

		end
		wl "</testsuite>"
	end
	wl "</testsuites>\n" 

	f:close()
end

return M

