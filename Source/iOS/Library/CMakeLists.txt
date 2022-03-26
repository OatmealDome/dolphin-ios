add_library(dolphin SHARED
  Dummy.cpp
)

set_target_properties(dolphin PROPERTIES
  LINK_FLAGS "-Wl,-all_load"
)

target_link_libraries(dolphin
PUBLIC
  common
  core
  uicommon
)
