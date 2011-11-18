################################################################################
# Coral TestKit (Testing Framework)
################################################################################

cmake_minimum_required( VERSION 2.6 )

project( TESTKIT )

################################################################################
# Setup Coral
################################################################################

# Resolve the CORAL_ROOT
file( TO_CMAKE_PATH "$ENV{CORAL_ROOT}" CORAL_ROOT )

# Add Coral's CMake dir to the CMAKE_MODULE_PATH
set( CMAKE_MODULE_PATH ${CORAL_ROOT}/cmake ${CMAKE_MODULE_PATH} )

# Load Coral's CMake package
find_package( Coral REQUIRED )

# Configure the coral path
set( CORAL_PATH "${CMAKE_SOURCE_DIR}/modules" )

################################################################################
# Installation
################################################################################

# enforce a safe default CMAKE_INSTALL_PREFIX
if( NOT CMAKE_INSTALL_PREFIX MATCHES "coral-testkit" )
	set( CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/coral-testkit" )
endif()

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
