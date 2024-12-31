// game_sequence.hpp taylo @ github <https://github.com/i-Taylo>
// Telegram @ <V9y_7V3>
#pragma once

#define GLOBAL_ACCESS_DBT_VERSION 3

#ifdef LINUX_IUNLOCKER_VM
    #define SEQ_PREBUILT_SERVICE     0x88
    #define GAME_FIRST_OPEN_TOKEN    "bcda760a9ff6e37717048edb3091642d"
    #define CLOSE_SERVICE(...) __QUIT_GAME_PROTECTOR__(CHEATING, process, _REASON_ ,SIGTERM)
    #define __CLX_TOKEN__ "f98922596a963794fc78014b1316e5a6" // unchanged 
    #define __XHU_CLAZZ__LOOP_VTYX_SRV_EXRF_TYPE   "Liunlocker/VM" // unchanged 
    #define ___VJSTRING___ "Ljava/lang/String"
#endif