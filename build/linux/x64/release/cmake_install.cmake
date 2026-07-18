# Install script for directory: /home/workspace/nex.elstella.com/flutter_app/linux

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app"
         RPATH "$ORIGIN/lib")
  endif()
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle" TYPE EXECUTABLE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/intermediates_do_not_run/flutter_app")
  if(EXISTS "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app"
         OLD_RPATH "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/bitsdojo_window_linux:/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_secure_storage_linux:/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_webrtc:/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/screen_retriever:/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/window_manager:/home/workspace/nex.elstella.com/flutter_app/linux/flutter/ephemeral:"
         NEW_RPATH "$ORIGIN/lib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/flutter_app")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/data/icudtl.dat")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/data" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/linux/flutter/ephemeral/icudtl.dat")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/linux/flutter/ephemeral/libflutter_linux_gtk.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libbitsdojo_window_linux_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/bitsdojo_window_linux/libbitsdojo_window_linux_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libflutter_secure_storage_linux_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_secure_storage_linux/libflutter_secure_storage_linux_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libflutter_webrtc_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_webrtc/libflutter_webrtc_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libwebrtc.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/linux/flutter/ephemeral/.plugin_symlinks/flutter_webrtc/linux/../third_party/libwebrtc/lib/linux-x64/libwebrtc.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libscreen_retriever_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/screen_retriever/libscreen_retriever_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libwindow_manager_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/window_manager/libwindow_manager_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libdartjni.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/jni/shared/libdartjni.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE DIRECTORY FILES "/home/workspace/nex.elstella.com/flutter_app/build/native_assets/linux/")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/data/flutter_assets")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/data/flutter_assets")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/data" TYPE DIRECTORY FILES "/home/workspace/nex.elstella.com/flutter_app/build//flutter_assets")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib/libapp.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/workspace/nex.elstella.com/flutter_app/build/lib/libapp.so")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/flutter/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/runner/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/bitsdojo_window_linux/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_secure_storage_linux/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/flutter_webrtc/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/screen_retriever/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/window_manager/cmake_install.cmake")
  include("/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/plugins/jni/cmake_install.cmake")

endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/home/workspace/nex.elstella.com/flutter_app/build/linux/x64/release/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
