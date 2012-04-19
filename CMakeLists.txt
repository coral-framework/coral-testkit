################################################################################
# Coral TestKit (Testing Framework)
################################################################################

cmake_minimum_required( VERSION 2.6 )

project( TESTKIT )

################################################################################
# Setup Coral
################################################################################

# Load Coral's CMake package
if( NOT CORAL_ROOT )
	file( TO_CMAKE_PATH "$ENV{CORAL_ROOT}" CORAL_ROOT )
endif()
set( CMAKE_MODULE_PATH "${CORAL_ROOT}/cmake" ${CMAKE_MODULE_PATH} )
find_package( Coral REQUIRED )

SET( CORAL_PATH
	"${CMAKE_SOURCE_DIR}/modules"
	${CORAL_PATH}
)

################################################################################
# Installation
################################################################################

# install module files
install( DIRECTORY "${CMAKE_SOURCE_DIR}/modules/" DESTINATION modules )

################################################################################
# Packaging
################################################################################

set( CPACK_PACKAGE_NAME					"coral-testkit" )
set( CPACK_PACKAGE_VERSION_MAJOR		"0" )
set( CPACK_PACKAGE_VERSION_MINOR		"5" )
set( CPACK_PACKAGE_VERSION_PATCH		"0" )
set( CPACK_PACKAGE_DESCRIPTION_SUMMARY	"Coral's Testing Framework" )

include( CPack )

################################################################################
# Subdirectories
################################################################################

enable_testing()
add_subdirectory( tests )
