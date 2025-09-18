set(lwmem_core_SRCS
    ${CMAKE_CURRENT_LIST_DIR}/src/lwmem/lwmem.c
    ${CMAKE_CURRENT_LIST_DIR}/src/system/lwmem_sys_apple.c
)

add_library(lwmem)
target_sources(lwmem PRIVATE ${lwmem_core_SRCS})
target_include_directories(lwmem PUBLIC "${CMAKE_CURRENT_LIST_DIR}/src/include")
