#include <stdio.h>
#include <string>
#include <filesystem>

namespace fs = std::filesystem;

#include <lua/lua.hpp>

int luaGetCurrentDirectory(lua_State* L) {
    lua_pushstring(L , fs::current_path().string().c_str());
    return 1;
}

int luaGetDirectories(lua_State* L) {
    fs::path path(luaL_checkstring(L , 1));

    lua_newtable(L);

    for (const auto& entry : fs::directory_iterator(path)) {
        if (!entry.is_directory()) {
            continue;
        }

        lua_pushstring(L , entry.path().filename().string().c_str());
        lua_pushnumber(L , 0);
        lua_settable(L , -3);
    }

    return 1;
}

int luaGetFiles(lua_State* L) {
    fs::path path(luaL_checkstring(L , 1));

    lua_newtable(L);

    for (const auto& entry : fs::directory_iterator(path)) {
        if (!entry.is_regular_file()) {
            continue;
        }

        lua_pushstring(L , entry.path().filename().string().c_str());
        lua_pushnumber(L , 0);
        lua_settable(L , -3);
    }

    return 1;
}

int luaCreateDirectory(lua_State* L) {
    fs::path path(luaL_checkstring(L , 1));

    lua_pushboolean(L , fs::create_directory(path));
    return 1;
}

int luaExists(lua_State* L) {
    fs::path path(luaL_checkstring(L , 1));

    lua_pushboolean(L , fs::exists(path));
    return 1;
}

static const luaL_Reg luaFilesystemLib[] = {
    {"GetCurrentDirectory", luaGetCurrentDirectory},
    {"GetDirectories", luaGetDirectories},
    {"GetFiles", luaGetFiles},
    {"CreateDirectory", luaCreateDirectory},
    {"Exists", luaExists},
    {NULL, NULL}
};

extern "C" __declspec(dllexport) int luaopen_libfilesystem(lua_State * L) {
    lua_newtable(L);
    luaL_setfuncs(L , luaFilesystemLib , 0);
    return 1;
}
