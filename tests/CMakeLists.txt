################################################################################
# Run the test scripts with CTest
################################################################################

CORAL_ADD_TEST( tests testkit.Run ${CMAKE_CURRENT_SOURCE_DIR} -o "output/TestResults$<CONFIGURATION>.xml" )
