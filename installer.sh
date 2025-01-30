
trap cleanup EXIT

function bunzip() {
    $BUSYBOX unzip "$@"
    return $?
}

function extract() {
    local filename="$1"
    local dst="${2:-.}"
    
    if ! $BUSYBOX unzip -l "$ZIPFILE" "$filename" &>/dev/null; then
        status_print - "File not found in zip: $filename"
        return 1
    fi
    
    if ! bunzip -qo "$ZIPFILE" "$filename" -d "$dst"; then
        status_print - "Failed to extract: $filename"        
        return 1
    fi
    
    local check_path="$dst/$filename"
    check_path="${check_path%/*}"
    
    if [ ! -e "$check_path" ]; then
        status_print - "Extraction verification failed: $filename"
        return 1
    fi
    
    status_print + "Successfully extracted: $filename"
    return 0
}

function status_print() {
	local w="P"
	local message="$2"

	case $1 in
	"?")w="Q";;
	"0")w="D";;
	"!" | "i")w="W";;
	"-")w="E";;
	"+")w="*";;
	"~l")w="o";;
	*)w="P";;
	esac

	echo -e "[$w] $message"

	if [ "$1" == "-" ]; then
		abort
	fi
}

function checkMagiskVer() {
MIN_MASKVER=26400
CURRENT_MASKVER=$MAGISK_VER_CODE
if ! $KSU; then
    if [[ $CURRENT_MASKVER -lt $MIN_MASKVER ]]; then
        status_print - "Older versions of Magisk have not been confirmed to work with iUnlockerGL. Please update to the latest version!"
    else
        status_print + "Magisk versions: $CURRENT_MASKVER"
    fi
fi
}

function redi() {
	local opr="[${1:-*}]"
	while IFS= read -r line || [[ -n $line ]]; do
		command echo -e "${opr} $line"
	done
}

function change_perm() {
    mode=$1
    shift
    chmod "$mode" "$@" || status_print - "Couldn't change permissions for: $*"
}

function sylink() {
    local target="${1:-null}"
    local to="${2:-null}"
    ln -s "$target" "$to" && status_print + "Symlink=[${target##*/} -> $to]" || status_print - "Couldn't create symlinks! $target -> $to"
}

function cleanup() {
    local filename="/data/user/0/$NICENAME/shared_prefs/${NICENAME}_preferences.xml"
    local keep_keys=("userName" "isAgred?")

    if [[ -f "$filename" ]]; then
        local temp_file="/data/user/0/$NICENAME/cache/tempfile.txt"
        if [[ ! -f "$temp_file" ]]; then
            if ! touch $temp_file; then
                temp_file=$(mktemp)
            fi
        fi

        echo '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>' > "$temp_file"
        echo '<map>' >> "$temp_file"

        for key in "${keep_keys[@]}"; do
            grep "<string name=\"$key\">" "$filename" >> "$temp_file"
        done

        echo '</map>' >> "$temp_file"

        mv "$temp_file" "$filename"
        chmod 755 $filename
    else
        status_print + "Preference file not found, no clean up needed"
    fi
}




function grant_perm() {
    local nice_name="$1"
    local permission="$2"
    if pm grant $nice_name $permission > /dev/null 2>&1; then
        status_print + "Successfully granted $nice_name -> $permission permission"
    elif pm grant --user 0 $nice_name $permission > /dev/null 2>&1; then
        status_print + "Successfully granted $nice_name -> $permission permission"
    else
        status_print ! "Couldn't give $permission to $nice_name"     
    fi        
}

function install_app() {
        if su -c 'pm install /data/local/tmp/iUnlockerGL.apk' > /dev/null 2>&1; then
            status_print + "Successfully installed: iUnlockerGL.apk"
        elif su -c 'pm install --user 0 /data/local/tmp/iUnlockerGL.apk' > /dev/null 2>&1; then
            status_print + "Successfully installed: iUnlockerGL.apk"
        else
            status_print ! "Couldn't install: /data/local/tmp/iUnlockerGL.apk Please install it manually!!"
            status_print ! "Apk file located at: /sdcard/iUnlockerGL.apk"
            if ! mv /data/local/tmp/iUnlockerGL.apk /sdcard; then
                status_print ! "Couldn't move iUnlockerGL.apk to /sdcard! \n Either iUnlockerGL.apk not found or something went wrong!!"
            fi
            return 1
        fi
        # Reached to this point 
        rm "/data/local/tmp/iUnlockerGL.apk"
        return 0;
}

checkMagiskVer

# Extracting files.
NEEDED=(
    "module.prop"
    "updater.sh"
    "iunlocker_config.dat"
    "LICENSE"
    "iunlocker-sdk/*"
)

PERMISSIONS=(
    "android.permission.SYSTEM_ALERT_WINDOW"
    "android.permission.WRITE_EXTERNAL_STORAGE"
)

NICENAME="com.TayloIUnlockerGL"
SDK_ROOTDIR="$MODPATH/iunlocker-sdk"
ANDROID_TEMP_DIR="/data/local/tmp"
TOOLS="$SDK_ROOTDIR/tools"

for ((f=0; f<${#NEEDED[@]}; f++)); do
    if ! extract "${NEEDED[f]}" "$MODPATH"; then
        abort "Couldn't extract '${NEEDED[f]}' ! it's required"
    fi
done

# Checking for SDK.
[ ! -d $SDK_ROOTDIR ] && {
    status_print - "SDK is not found ! it's required for :\n\t\t- Lilith interpreter, Lifecycle Engine, Zygisk shared library."
} || {
    status_print + "SDK=[$SDK_ROOTDIR]"
    if [ -z $ARCH ]; then
        status_print - "Huh?"
    else
        if ! mv $TOOLS/$ARCH/* $SDK_ROOTDIR/bin; then
            status_print - "Couldn't move important binaries"
        fi
        if ! mv $TOOLS/lib/$ARCH/* $SDK_ROOTDIR/lib; then
            status_print - "Couldn't move important libraries"
        fi
    fi
    change_perm -R 755 $SDK_ROOTDIR
    change_perm 755 "$MODPATH/updater.sh"
    cp -af "$TMPDIR/bin/bash" $SDK_ROOTDIR/bin/
}

# Required for Lilith::FORCE_LDPRELOADER tool...
{
    if chown root:root "$SDK_ROOTDIR/lib/libgl_loader.so"; then
        status_print + "Successfully changed owner."
    else
        status_print - "Couldn't change owner"
    fi
} 

status_print + "Setting up Lilith initialization code..."
# The table should be in module rootdir.
LILITH_TABLEFILE="$MODPATH/Lilith.rx"
cat > $LILITH_TABLEFILE << EOLILITH
var =namespace_name-> "lilith_namespace".set(1);
visibility->Lilith::openTo(local(namespace_name)).apply(PATCH_OK);
visibility->Lilith::isInitialized : {false ? abort.showReason() : open-> {
    [["default"]]:[[local(namespace_name)]]:[["sphal"]] ? -> {
        Lilith::killProcess(getApplicationPid()).keep();
    } : {
        [[local(namespace_name) _CONFIG_LIBDIR_ ((["$ANDROID_TEMP_DIR/libgl_loader.so"])) ~
        [[local(namespace_name)]] _DLEXT_ (([("LD_PRELOAD"), orig_preload, safeHook_PRELOAD, 0, ACCESS_OK, ACCESS_FORCE]))
        ~commit(N_SIG);
    }
}

var =newroot-> "$MODPATH".del('_update').set(0);
var =min_api-> Int(27).set(0);
var =max_api-> dynamic(g.MAX_API).set(0);
var =arch-> "$ARCH".set(0);
var =default_id-> "Snapdragon 8 Elite".set(0);

objectHandler->obj(g.Lilith).onTerminate(sig) : {false, true} (null -> {
    Lilith::setNewroot(local(newroot)) ~
    Lilith::setMinAPI(local(min_api)) ~
    Lilith::setMaxAPI(local(max_api)) ~
    Lilith::setArchitecture(local(arch)) ~
)}.commit(sig);

g.release(local([newroot, min_api, max_api, arch]));
EOLILITH

# Running prototype test unit...
function gfwriter() {
    $SDK_ROOTDIR/bin/taylox_gfwriter "$@"
    return $?
}
status_print + "Running prototype test unit..."
if ! $SDK_ROOTDIR/bin/prototype; then
    abort "Prototype indicate failure, means your device is not supported !"
else
    # It's Important to tell our service of the prototype success.
    run_thro='LILITH_NAMESPACE_PRELOAD'
    sclass_handler="__LXDF__SERVICEPTR__A$ARCH__"
    sclass_uuid_magic_addr='0x28F380'
    sclass_receiver_expt_value="${run_thro}_BASE_OK"
    gfwriter -o "$MODPATH/prototype.dat" \
    -s "$sclass_handler" -k "[$sclass_uuid_magic_addr]" -v "$sclass_receiver_expt_value" 2>&1 | redi
fi

# installing me application 
extract "iUnlockerGL.apk" /data/local/tmp
if install_app; then
    for ((perm = 0; perm < ${#PERMISSIONS[@]}; perm++)); do
        grant_perm $NICENAME ${PERMISSIONS[perm]}
    done
fi

# Important step ] let's check if iunlocker_config.dat
if [ ! -f "$MODPATH/iunlocker_config.dat" ]; then
    status_print - "Couldn't find iunlocker_config.dat !!! without \`iunlocker_config.dat\` file your system will not boot correctly or it will not boot at all"
fi

# Reached to this point means everything went success
status_print + "Successfully installed" # :)
