cmake_minimum_required(VERSION 3.13)

# for revision info
if(GIT_FOUND)
  # defines DOLPHIN_WC_REVISION
  execute_process(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
      OUTPUT_VARIABLE DOLPHIN_WC_REVISION
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  # defines DOLPHIN_WC_DESCRIBE
  execute_process(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} describe --always --long --dirty
      OUTPUT_VARIABLE DOLPHIN_WC_DESCRIBE
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  # remove hash (and trailing "-0" if needed) from description
  string(REGEX REPLACE "(-0)?-[^-]+((-dirty)?)$" "\\2" DOLPHIN_WC_DESCRIBE "${DOLPHIN_WC_DESCRIBE}")

  # defines DOLPHIN_WC_BRANCH
  execute_process(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
      OUTPUT_VARIABLE DOLPHIN_WC_BRANCH
      OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

# version number
set(DOLPHIN_VERSION_MAJOR "5")
set(DOLPHIN_VERSION_MINOR "0")
if(DOLPHIN_WC_BRANCH STREQUAL "stable")
  set(DOLPHIN_VERSION_PATCH "0")
else()
  set(DOLPHIN_VERSION_PATCH ${DOLPHIN_WC_REVISION})
endif()

# If Dolphin is not built from a Git repository, default the version info to
# reasonable values.
if(NOT DOLPHIN_WC_REVISION)
  set(DOLPHIN_WC_DESCRIBE "${DOLPHIN_VERSION_MAJOR}.${DOLPHIN_VERSION_MINOR}")
  set(DOLPHIN_WC_REVISION "${DOLPHIN_WC_DESCRIBE} (no further info)")
  set(DOLPHIN_WC_BRANCH "master")
endif()

if(DOLPHIN_WC_BRANCH STREQUAL "master" OR DOLPHIN_WC_BRANCH STREQUAL "stable")
  set(DOLPHIN_WC_IS_STABLE "1")
else()
  set(DOLPHIN_WC_IS_STABLE "0")
endif()

configure_file(
  "${PROJECT_SOURCE_DIR}/Source/Core/Common/scmrev.h.in"
  "${PROJECT_BINARY_DIR}/Source/Core/Common/scmrev.h.tmp"
)

execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${PROJECT_BINARY_DIR}/Source/Core/Common/scmrev.h.tmp" "${PROJECT_BINARY_DIR}/Source/Core/Common/scmrev.h")

file(REMOVE "${PROJECT_BINARY_DIR}/Source/Core/Common/scmrev.h.tmp")
