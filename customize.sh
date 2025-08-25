#!/system/bin/sh
# Auto-generated customize.sh script

SKIPUNZIP=1
DEFAULT_PATH="/data/adb/magisk"

extract() {
    local filename=$1
    local dst=$2
    unzip -qo "$ZIPFILE" "$filename" -d "$dst"
}
# Root interface detection
KSUDIR="/data/adb/ksu"
APDIR="/data/adb/ap"
BUSYBOX="$DEFAULT_PATH/busybox"
KSU=false
AP=false
if [ -f "$KSUDIR/bin/busybox" ]; then
    KSU=true
    DEFAULT_PATH=$KSUDIR
    BUSYBOX="$DEFAULT_PATH/bin/busybox"
elif [ -f "$APDIR/bin/busybox" ]; then
    AP=true
    DEFAULT_PATH="$APDIR"
    BUSYBOX="$DEFAULT_PATH/bin/busybox"
fi

# Extract zygisk libraries
isZygisk=true
if $isZygisk; then
    DEVICE_ABI="$(getprop ro.product.cpu.abi)"
    if [ "$DEVICE_ABI" = "arm64-v8a" ] || [ "$DEVICE_ABI" = "armeabi-v7a" ] || [ "$DEVICE_ABI" = "x86_64" ] || [ "$DEVICE_ABI" = "x86" ]; then
        extract "zygisk/$DEVICE_ABI.so" $MODPATH
    else
        abort "Unknown architecture: $DEVICE_ABI"
    fi
fi

# Setup bash environment
INSTALLER="$TMPDIR/installer.sh"
ANDROID_TEMP_DIR="/data/local/tmp"
ANDROID_CACHE_DIR="/cache"

# Check for installer.sh in multiple locations
INSTALLER_FOUND_AT="$TMPDIR"
extract "installer.sh" $TMPDIR
if [ ! -f "$TMPDIR/installer.sh" ]; then
    ui_print "Error: installer.sh not found. trying alternative path..."
    extract "installer.sh" $ANDROID_TEMP_DIR
    if [ ! -f "$ANDROID_TEMP_DIR/installer.sh" ]; then
        ui_print "Error: installer.sh not found. trying alternative path..."
        extract "installer.sh" $ANDROID_CACHE_DIR     
        if [ ! -f "$ANDROID_CACHE_DIR/installer.sh" ]; then
            abort "Error: installer.sh not found. all attempts failed."
        else
            INSTALLER_FOUND_AT="$ANDROID_CACHE_DIR"
        fi
    else
        INSTALLER_FOUND_AT="$ANDROID_TEMP_DIR"
    fi
fi

# Update INSTALLER path based on where it was found
INSTALLER="$INSTALLER_FOUND_AT/installer.sh"

# Check for bin/$ARCH.xz in multiple locations
extract "bin/$ARCH.xz" $TMPDIR

FOUND_AT="$TMPDIR" # initial path 
if [ ! -f "$TMPDIR/bin/$ARCH.xz" ]; then
    ui_print "Error: required file is not found. trying alternative path..."
    extract "bin/$ARCH.xz" $ANDROID_TEMP_DIR
    if [ ! -f "$ANDROID_TEMP_DIR/bin/$ARCH.xz" ]; then
        ui_print "Error: required file is not found. trying alternative path..."
        extract "bin/$ARCH.xz" $ANDROID_CACHE_DIR     
        if [ ! -f "$ANDROID_CACHE_DIR/bin/$ARCH.xz" ]; then
            abort "Error: required file is not found. all attempts failed."
        else
            FOUND_AT="$ANDROID_CACHE_DIR"
        fi
    else
        FOUND_AT="$ANDROID_TEMP_DIR"
    fi
fi

$BUSYBOX xz -d "$FOUND_AT/bin/$ARCH.xz"
mv "$FOUND_AT/bin/$ARCH" "$FOUND_AT/bin/bash"


# Setting up files permissions
chmod 755 "$FOUND_AT/bin/bash" || abort "Couldn't change -> $FOUND_AT/bin/bash permission"
chmod +x "$INSTALLER" || abort "Couldn't change -> $INSTALLER permission"

# Setup module environment
export KSUDIR APDIR AP MODID MODNAME MODAUTH OUTFD ABI API MAGISKBIN NVBASE BOOTMODE MAGISK_VER_CODE MAGISK_VER ZIPFILE MODPATH TMPDIR DEFAULT_PATH KSU ABI32 IS64BIT ARCH BMODID BUSYBOX

# bash executor
bashexe() {
    $FOUND_AT/bin/bash "$@"
    return $?
}

# Finally execute the installer
sed -i "1i\ " "$INSTALLER"
sed -i "1s|.*|#!$FOUND_AT/bin/bash|" $INSTALLER
if ! bashexe -c ". $DEFAULT_PATH/util_functions.sh; source $INSTALLER"; then
    abort
fi
