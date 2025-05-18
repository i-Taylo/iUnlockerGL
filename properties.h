#ifndef PROPERTIES_H
#define PROPERTIES_H

// ==================================================
// Module Configuration Header
// for the iUnlocker module and its components.
// ==================================================

// --- Module Info ---
#define MODULE_ID               "Mjg2MjU1ODg0Mwo"
#define BACKEND_VERSION_HSTR    "v1.1.4-r2"           // Backend version string
#define SIGNATURE               "fingerprinter:CF:CA:48:38:76:DD:80:F0:77:B9:F2:FC:D9:CA:5E:71:19:2C:FF:5C:BA:29:0A:A7:19:C8:F4:30:4B:E1:81:95"

// --- Feature Toggles ---
#define ENABLE_BACKGROUND_UPDATES   false            // Background update support (TODO: needs service integration)
#define USE_SMART_BUFFER_LIBRARY    true             // Enable SmartBuffer library
#define USE_SAPPHIRE_ELF_LIBRARY    true             // Enable Sapphire ELF handling library
#define USE_ZYGISK_LIBRARY          true             // Enable Zygisk integration (Magisk modules)

// --- Graphics ---
#ifndef GRAPHICS_API
    #define GRAPHICS_API "OpenGL"                    // Default graphics API
#endif

// --- Virtual Container Settings ---
#ifndef DYNAMIC_GHOST_LOADER
    #define DYNAMIC_GHOST_LOADER 0x2                 // Container type: 0x1 = LILITH, 0x2 = GHOST
#endif

#define USE_VM_FOR_GAMES         false               // Avoid VM for games to bypass anti-cheat detection
#define USE_VM_FOR_APPS          true                // Use VM for apps to isolate behavior
#define KEEP_CONTAINERS_ALIVE    true                // Do not destroy containers, destroy only on app termination

#define CONTAINER_MIME_TYPE      "json"              // MIME type used for container communication

// --- Shell Defaults ---
#define DEFAULT_SHELL            "bash"              // Shell used in runtime environment
#define DEFAULT_SHELL_RCFILE     "/data/local/tmp"   // Default shell profile script location

// --- UI & Theming ---
#define APPLICATION_UI           "iUnlockerUI"       // Application UI identifier
#define APP_THEME                "green"             // Default theme (green, dark, light, etc.)

// --- API Usage ---
#define ENABLE_CACHED_OPERATIONS true                // Use cached operations instead of spawning fresh tasks

// Used APIs
#define USED_APIS           "lilith,ghost"

// --- Methods ---
#define BACKEND_VERSION_FUNC     getBackendVersion
#define FRONTEND_VERSION_FUNC    getFrontendVersion

#endif // PROPERTIES_H
