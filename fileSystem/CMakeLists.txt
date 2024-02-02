cmake_minimum_required(VERSION 3.20)

set(LUA_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/../include/lua)
set(LUA_LIBRARY ${CMAKE_SOURCE_DIR}/../include/lua/liblua.a)
find_package(Lua REQUIRED)

set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR})

project(filesystem)
set(EXECUTABLE_NAME freemaker_filesystem)

include_directories(${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/../include)

file(GLOB SOURCES "src/*.c" "src/*.cpp")
file(GLOB HEADERS "src/*.h")

add_library(${EXECUTABLE_NAME} SHARED ${SOURCES} ${HEADERS})

set_target_properties(${EXECUTABLE_NAME} PROPERTIES PREFIX "")

target_link_libraries(${EXECUTABLE_NAME} ${LUA_LIBRARIES})