MODDIR=${0%/*}
ADDIR="/data/adb"
SDK_ROOTDIR="$ADDIR/iunlocker-sdk"
PROP_FILE="$MODDIR/system.prop"

log() {
    local TAG="SERVICE_SH"
    local logfile="$SDK_ROOTDIR/share/iUnlockerGL.log"
    echo -e "( $1 ) ) [ $TAG ] : $2" >> $logfile
}


# updater_pkg="$SDK_ROOTDIR/share/Updater/iUnlocker-updater.apk"

# test_and_install() {
    # local apkfile="$1"
    # local keep_opt="--keep-apkinstaller-userfile"
    # local use_wu=""
    # if "$SDK_ROOTDIR/bin/AppInstaller" --get-running-user $keep_opt; then
        # use_wu="--use-working-user"
    # fi
    # if "$SDK_ROOTDIR/bin/AppInstaller" --install "$apkfile $use_wu"; then
        # echo "install success" >> "$MODDIR/service.log"
    # else
        # echo "install failure" >> "$MODDIR/service.log"
    # fi
# }

# updater_version=1000
# UPDATER_FILE="$SDK_ROOTDIR/updater_version"
# val=""
# if [ -f "$UPDATER_FILE" ]; then
    # val="$(cat "$UPDATER_FILE")"
# fi

# updater_nicename="com.taylo.iunlockergl.updater"
# listOf="$("$SDK_ROOTDIR/bin/AppInstaller" --list)"
# BOOT_COMPLETED="$(getprop sys.boot_completed)"


# suc=1
# while [ "$(getprop sys.boot_completed)" != "1" ]; do
    # suc=0
# done

# if [ $suc -eq 0 ]; then
# sleep 20
# echo "$listOf" | while read UpdaterApp; do
    # if [ "$UpdaterApp" = "$updater_nicename" ]; then
        # echo "Already installed attaching version" >> "$MODDIR/service.log"
        # if [ ! -f "$UPDATER_FILE" ]; then
            # echo -n "$updater_version" > "$UPDATER_FILE"
        # else
            # echo "File not found attaching only version" >> "$MODDIR/service.log"
            # if [ "$val" -gt "$updater_version" ]; then
                # echo -n "$updater_version" > "$UPDATER_FILE"
            # fi
        # fi
        # break
    # else
        # echo "Not installed, installing" >> "$MODDIR/service.log"
        # test_and_install "$updater_pkg"
        # echo -n "$updater_version" > "$UPDATER_FILE"
        # break
    # fi
# done
# fi
# Safely remove old config

__CONFIG_OLD_DIR__="/data/adb/modules/iUnlockerGL"
__CONFIG_PROTOTYPE__="$MODDIR/prototype.dat"

if [ ! -d "$__CONFIG_OLD_DIR__" ]; then
    exit 0
fi

gfwriter() {
    "$SDK_ROOTDIR/bin/taylox_gfwriter" "$@"
    return $?
}

RUN_THRO='GHOST_NAMESPACE_PRELOAD'
SCLASS_RECEIVER_EXPT_VALUE="${RUN_THRO}::OK_Connectivity"
SCLASS_HANDLER="Ghost::API::GB_INSTANCE"
SCLASS_UUID_IDENTIFIER="UUID_MAGIC"
NEW_SCLASS_UUID_MAGIC_ADDR="0x730EA0"

if gfwriter -o "$__CONFIG_PROTOTYPE__" -s "$SCLASS_HANDLER" -k "$SCLASS_UUID_IDENTIFIER" -v "$NEW_SCLASS_UUID_MAGIC_ADDR:$SCLASS_RECEIVER_EXPT_VALUE"; then
    if rm -rf "$__CONFIG_OLD_DIR__"; then
        exit 0
    fi
fi
