cmake_minimum_required(VERSION 3.28)
set (CMAKE_CXX_STANDARD 23)

set(LUA_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include/lua)
set(LUA_LIBRARY ${CMAKE_SOURCE_DIR}/include/lua/liblua.a)
find_package(Lua REQUIRED)

project(filesystem)

include_directories(${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/include)

file(GLOB SOURCES "src/*.c" "src/*.cpp")
file(GLOB HEADERS "src/*.h")

add_library(filesystem MODULE ${SOURCES} ${HEADERS})
target_include_directories(filesystem PRIVATE ${LUA_INCLUDE_DIR})
target_link_libraries(filesystem PRIVATE ${LUA_LIBRARIES})

add_definitions(-DLUA_BUILD_AS_DLL)
add_definitions(-DLUA_LIB)
