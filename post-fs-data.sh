MODDIR=${0%/*}
ADDIR="/data/adb"
SDK_ROOTDIR="$ADDIR/iunlocker-sdk"
PROP_FILE="$MODDIR/system.prop"

log() {
    local TAG="POST_FS_DATA_SH"
    local logfile="$SDK_ROOTDIR/share/iUnlockerGL.log"
    echo -e "( $1 ) ) [ $TAG ] : $2" >> $logfile
}

remProps() {
    tmpfile="${PROP_FILE}.tmp"
    cp "$PROP_FILE" "$tmpfile"

    for key in "$@"; do
        cp "$tmpfile" "$tmpfile.tmp"
        grep -v -E "^$key=" "$tmpfile.tmp" > "$tmpfile"
        rm "$tmpfile.tmp"
    done

    mv "$tmpfile" "$PROP_FILE"
}



addProp() {
    key="$1"
    value="$2"
    if [ -z "$key" ] || [ -z "$value" ]; then return 1; fi
    remProp "$key"
    echo "$key=$value" >> "$PROP_FILE"
}


# Handling plugins / Sapphire
sapphire_install_file="$SDK_ROOTDIR/tmp/.sapphire_install"
sapphire_ver=""
opr="sapphire"
if [ -f "$sapphire_install_file" ]; then
    sapphire_ver="$(cat $sapphire_install_file)"
    log "$opr" "Found installation file"
    log "$opr" "Checking for system directory..."
    if [ -d "$SDK_ROOTDIR/tmp/Amethyst/system" ]; then
        log "$opr" "Found system directory, moving it to -> $MODDIR"
        if mv "$SDK_ROOTDIR/tmp/Amethyst/system" "$MODDIR"; then
            log "$opr" "Successfully moved system dir"
            addProp "gl.sapphire.version" "$sapphire_ver"
            addProp "gl.sapphire" "1"
            if rm "$sapphire_install_file"; then
                log "$opr" "Successfully removed $sapphire_install_file"
            fi
        else
            log "$opr" "Failed to move system dir to -> $MODDIR"
        fi
    fi
fi
# Handling plugins / Standard iUnlocker
stdI_install_file="$SDK_ROOTDIR/tmp/.std_iunlocker_install"
listprops=""
opr="stdiunlocker"
if [ -f "$stdI_install_file" ]; then
    listprops="$(cat $stdI_install_file)"
    log "$opr" "Found installation file"

    echo "$listprops" | while IFS='=' read key value; do
        log "$opr" "appending: $key=$value"
        addProp "$key" "$value"
    done
    rm $stdI_install_file
    log "$opr" "Installation completed"
fi

# Handling bootfuckingloop & Uninstallation
SAPU="/cache/sapphire_uninstall"
TEMPSAPU="$SDK_ROOTDIR/tmp/sapphire_uninstall"
if [ -f $SAPU ] || [ -f $TEMPSAPU ]; then
    if [ -d $MODDIR/system ]; then
        if rm -rf $MODDIR/system; then
            log "Sapphire" "Successfully removed sapphire"
            remProp "gl.sapphire.version"
            remProp "gl.sapphire"
            if [ -f $SAPU ]; then
                rm $SAPU
            else
                rm $TEMPSAPU
            fi
            # reboot
        fi
    fi
fi
# Main module
GLU="/cache/iunlocker_uninstall"
if [ -f $GLU ]; then
    if touch $MODDIR/remove; then
        rm $GLU
        reboot
    fi
fi

STDU="/cache/iunlocker_standard_uninstall"
TEMPSTDU="$SDK_ROOTDIR/tmp/iunlocker_standard_uninstall"
opr="iUnlockerUninstaller:std"
if [ -f "$STDU" ] || [ -f "$TEMPSTDU" ]; then
    log "$opr" "Found uninstallation file"
    log "$opr" "Uninstalling properties..."
    remProps \
        "ro.product.model" \
        "ro.product.system.model" \
        "ro.product.system_ext.model" \
        "ro.product.vendor.model" \
        "ro.product.odm.model" \
        "ro.product.manufacturer" \
        "ro.product.system.manufacturer" \
        "ro.product.system_ext.manufacturer" \
        "ro.product.vendor.manufacturer" \
        "ro.product.odm.manufacturer"
    log "$opr" "Successfully uninstalled properties"
    
    if [ -f "$STDU" ]; then
        rm "$STDU"
    elif [ -f $TEMPSTDU ]; then
        rm "$TEMPSTDU"
    fi
fi
