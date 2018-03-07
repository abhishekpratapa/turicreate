project(Turi)

if(${TC_BUILD_ANNOTATION_CLIENT})

  find_program(NPM npm)
  if(NOT NPM)
    message(FATAL_ERROR "npm not found. Node.js 6.x or later with npm is required to build Turi Create.")
  endif()

  if(APPLE)
    add_custom_target(annotation_client
      COMMAND xcodebuild -project "${CMAKE_CURRENT_SOURCE_DIR}/Turi Create Object Detection Annotation.xcodeproj/" -configuration ${CMAKE_BUILD_TYPE} SYMROOT=${CMAKE_CURRENT_BINARY_DIR}
      COMMENT "Building annotation client via xcodebuild"
    )
  else()
    make_empty_library(annotation_client)
  endif()
else()
  make_empty_library(annotation_client)
endif()
