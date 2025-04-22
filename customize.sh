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

extract "installer.sh" $TMPDIR
extract "bin/$ARCH.xz" $TMPDIR

if [ ! -f "$TMPDIR/bin/$ARCH.xz" ]; then
    abort "Error: required files are not found."
else
    $BUSYBOX xz -d $TMPDIR/bin/$ARCH.xz
    mv "$TMPDIR/bin/$ARCH" "$TMPDIR/bin/bash"
fi

# Setting up files permissions
chmod 755 "$TMPDIR/bin/bash" || abort "Couldn't change -> $TMPDIR/bin/bash permission"
chmod +x "$INSTALLER" || abort "Couldn't change -> $INSTALLER permission"

# Setup module environment
export MODID MODNAME MODAUTH OUTFD ABI API MAGISKBIN NVBASE BOOTMODE MAGISK_VER_CODE MAGISK_VER ZIPFILE MODPATH TMPDIR DEFAULT_PATH KSU ABI32 IS64BIT ARCH BMODID BUSYBOX

# bash executor
bashexe() {
    $TMPDIR/bin/bash "$@"
    return $?
}

# Finally execute the installer
sed -i "1i\ " "$INSTALLER"
sed -i "1s|.*|#!$TMPDIR/bin/bash|" $INSTALLER
if ! bashexe -c ". $DEFAULT_PATH/util_functions.sh; source $INSTALLER"; then
    abort
fi
