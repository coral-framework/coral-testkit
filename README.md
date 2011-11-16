TestKit Module
==============

A module, in Lua, for running tests in a Coral application.

Currently its main goal is to run the already exsiting tests in the given
modules.

The testkit runs the TestRunner script. You may pass as many test folders to be
tested as you wish, and he will search for lua scripts ending with 'Tests.lua'
(e.g. GenericTests.lua), but remeber always that each of the module's being
tested must have their current modules folder previously defined at the coral
path, including the testkit's path.

If you wish to use any auxiliary files during the testing, such as resources,
they also must be previously defined at the coral path.

The testkit may contain as many different testing approaches as necessary. At
the moment, a simple UnitTest script is available and already being used in
other Coral modules.

Usage
=====

SYNOPSIS:

coral lua.Launcher testKit.TestRunner [ [TEST_FOLDER] ... ] -o [OUTPUT_FILE_PATH]

DESCRIPTION:

The coral launcher call's the lua.Launcher, who calls the testKit's TestRunner.
The output parameter is obligatory, it defines the name (and path optionally)
of the xml (junit format) file containing the test results. All paths, all
relative, and should be treated as such.

TEST CALL EXAMPLE:

	c:/libcoral/coral.exe lua.Launcher testkit.TestRunner testsPathA testPathB -o output/unitTests.xml

TEST SCRIPT EXAMPLE:

	--Filename: ExampleTests.lua

	require "testkit.Unit" -- testing tool

	-- module2BTested should be defined in the system's path CORAL_PATH
	local module2BTested = require "module2BTested"

	function genericTest()
		-- method "assertTrue" is a function of the "Unit" module
		assertTrue( module2BTested.performAction, "Action didn't perform as expected!" )
	end
