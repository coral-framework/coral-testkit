TestKit Module
==============

A module for running tests in a Coral application.

Currently its main goal is to run the already exsiting tests in the given
modules. 

The testkit runs the ModuleLauncher script. You may pass as many 
modules to be tested as you wish, and he will search for lua scripts ending with
'Test.lua' (e.g. GenericTest.lua), but remeber always that each of the module's
paths must be previously defined at the coral path, including the testkit's path.

Usage
=====

SYNOPSIS:

coral lua.Launcher testKit.ModuleLauncher [ [MODULE_NAME] ... ] -o [OUTPUT_FILE_PATH]

DESCRIPTION:

The coral launcher call's the lua.Launcher, who calls the testKit ModuleLauncher.
The output paramenter is obligatory, it defines the name (and path optionally) 
of the xml (junit format) file containing the test results. All paths all 
relative, and should be treated as such.

