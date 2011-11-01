################################################################################
# Build the Module
################################################################################

CORAL_GENERATE_MODULE( _MODULE_SOURCES testkit )

INCLUDE_DIRECTORIES( ${CMAKE_CURRENT_SOURCE_DIR} ${CORAL_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR}/generated )

FILE( GLOB _SOURCE_FILES *.cpp )
FILE( GLOB _HEADER_FILES *.hpp )

ADD_LIBRARY( testkit MODULE ${_HEADER_FILES} ${_SOURCE_FILES} ${_MODULE_SOURCES} )

IF( WIN32 )
	TARGET_LINK_LIBRARIES( testkit ${CORAL_LIBRARIES} psapi.lib )
ELSE( WIN32 )
	TARGET_LINK_LIBRARIES( testkit ${CORAL_LIBRARIES} )
ENDIF( WIN32 )
	
CORAL_TARGET( testkit )
CORAL_MODULE_TARGET( "testkit" testkit )

################################################################################
# Source Groups
################################################################################

SOURCE_GROUP( "@Generated" FILES ${_MODULE_SOURCES} )
