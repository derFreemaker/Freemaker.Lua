cmake_minimum_required(VERSION 3.28)

set(LUA_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include/lua)
set(LUA_LIBRARY ${CMAKE_SOURCE_DIR}/include/lua/liblua.a)
find_package(Lua REQUIRED)

project(filesystem)

include_directories(${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/include)

file(GLOB SOURCES "src/*.c" "src/*.cpp")
file(GLOB HEADERS "src/*.h")

add_library(filesystem SHARED ${SOURCES} ${HEADERS})

target_link_libraries(filesystem ${LUA_LIBRARIES})

# set to compile ro x64
add_compile_options(-m64)
add_compile_options(-mfpic)
