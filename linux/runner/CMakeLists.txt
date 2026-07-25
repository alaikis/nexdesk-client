cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Add X11 and XTest libraries for screen capture and input injection
find_package(X11 REQUIRED)
if(X11_FOUND)
  target_include_directories(${BINARY_NAME} PRIVATE ${X11_INCLUDE_DIR})
  target_link_libraries(${BINARY_NAME} PRIVATE ${X11_LIBRARIES})
endif()
if(X11_Xext_FOUND)
  target_link_libraries(${BINARY_NAME} PRIVATE ${X11_Xext_LIB})
endif()
if(X11_Xtest_FOUND)
  target_link_libraries(${BINARY_NAME} PRIVATE ${X11_Xtest_LIB})
endif()

# Add libjpeg for JPEG encoding
find_package(JPEG REQUIRED)
if(JPEG_FOUND)
  target_include_directories(${BINARY_NAME} PRIVATE ${JPEG_INCLUDE_DIR})
  target_link_libraries(${BINARY_NAME} PRIVATE ${JPEG_LIBRARIES})
endif()

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
