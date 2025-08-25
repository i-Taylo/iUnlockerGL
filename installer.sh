trap cleanup EXIT

LOGPRIORITY=3
PROTOTYPE_LOGALL=true

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
    local should_log=true

    case $1 in
        "?" ) w="QUESTION"; log_priority=2 ;;
        "0" ) w="DEBUG";    log_priority=1 ;;
        "!" | "i" ) w="WARNING"; log_priority=2 ;;
        "-" ) w="ERROR";    log_priority=3 ;;
        "+" ) w="INFO";     log_priority=2 ;;
        "c" ) w="CLEANUP"; log_priority=2 ;;
        "~l" ) w="o";       log_priority=2 ;;
        * ) w="INFO";       log_priority=2 ;;
    esac

    case $LOGPRIORITY in
        1) should_log=true ;;
        2) [ $log_priority -ge 2 ] && should_log=true || should_log=false ;;
        3) [ $log_priority -ge 3 ] && should_log=true || should_log=false ;;
        *) should_log=true ;;
    esac

    if $should_log; then
        echo -e "[$w] $message"
    fi

    if [ "$1" == "-" ]; then
        abort
    fi
}

JsonWriter() {
    local file="$1"
    shift

    echo "{" > "$file"
    local first=true

    while [[ $# -gt 0 ]]; do
        key="$1"
        value="$2"
        shift 2

        if [[ "$first" == false ]]; then
            echo "," >> "$file"
        else
            first=false
        fi

        if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" =~ ^true$|^false$ ]]; then
            echo -n "  \"$key\": $value" >> "$file"
        else
            echo -n "  \"$key\": \"$value\"" >> "$file"
        fi
    done

    echo -e "\n}" >> "$file"
}


function checkMagiskVer() {
	MIN_MASKVER=26400
	CURRENT_MASKVER=$MAGISK_VER_CODE
	if [[ "$KSU" != "true" ]] || [[ "$AP" != "true" ]]; then
		if [[ $CURRENT_MASKVER -lt $MIN_MASKVER ]]; then
			status_print ! "Older versions of Magisk have not been confirmed to work with iUnlockerGL. Please update to the latest version!"
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
    prototype_exec="$SDK_ROOTDIR/bin/prototype"
	if [[ -f "$prototype_exec" ]]; then
		if rm -f "$SDK_ROOTDIR/bin/prototype"; then
		    status_print c "Successfully cleaned: ${prototype_exec##*/}"
		else
		    status_print c "Couldn't clean: ${prototype_exec##*/}"
		fi
	fi
	
	junkTools="$SDK_ROOTDIR/tools"
	if [[ -d "$junkTools" ]]; then
		if rm -rf "$junkTools"; then
		    status_print c "Successfully cleaned: ${junkTools##*/}"
		else
		    status_print c "Couldn't clean: ${junkTools##*/}"
		fi	    
	fi
	
    if [[ -f "$MODPATH/iUnlockerGL.apk" ]]; then
        if ! rm -rf "$MODPATH/iUnlockerGL.apk"; then
            status_print ! "Couldn't clean up $MODPATH/iUnlockerGL.apk"
        fi
    fi
    
    # $MODID.dat moved to sdkdir in v1.1.5-r2 due to prototype containment failure in Android 15+, which caused connections between components to exit immediately.
    if [[ -f "/data/adb/$MODID.dat" ]]; then
        # clean MODID.dat && reset the app data as well
        rm -f "/data/adb/$MODID.dat"
        keep_opt="--keep-apkinstaller-userfile"
        wu=1
        if AppInstaller --get-running-user $keep_opt --nopr; then
            wu=0
        fi
        [ $wu -eq 0 ] && {
            working_user="$(cat $SDK_ROOTDIR/tmp/apkinstaller)"
            [ ! -z $working_user ] && {
                pm clear --user $working_user $NICENAME | redi "🧹"
            } || pm clear $NICENAME | redi "🧹"
        }
    fi
    
    NOT_NEEDED=(
        "$SDK_ROOTDIR/bin/upenv"
    )
    for ((f = 0; f < ${#NOT_NEEDED[@]}; f++)); do
        F2CLEAN="${NOT_NEEDED[f]}"
        if [[ -f "$F2CLEAN" ]] || [[ -d "$F2CLEAN" ]]; then
            rm -rf $F2CLEAN
        fi
    done
    

}

function AppInstaller() {
    $SDK_ROOTDIR/bin/AppInstaller "$@"
    return $?
}

function ensure_nold() {
    keep_opt="--keep-apkinstaller-userfile"
    
    local listOf="$(AppInstaller --list)"
    local old_nicename="com.TayloIUnlockerGL"
    local use_wu=""
    if AppInstaller --get-running-user $keep_opt --nopr; then
        use_wu="--use-working-user"
    fi
    
    for GL in ${listOf[@]}; do
        if [[ "$GL" == "$old_nicename" ]]; then
            AppInstaller --uninstall "$old_nicename" $keep_opt $use_wu
        fi
    done
}

function ensure_updater() {
    local updater_version=1000
    local UPDATER_FILE="$SDK_ROOTDIR/updater_version"
    local val="$(cat "$UPDATER_FILE")"
    
    if [[ ! -f "$UPDATER_FILE" ]]; then
        echo -ne "$updater_version" > $UPDATER_FILE
    else
        if [[ ! $val -eq $updater_version ]]; then
            echo -ne "$updater_version" > $UPDATER_FILE
        fi
    fi
}

function install_iunlocker_app() {
    local keep_opt="--keep-apkinstaller-userfile"
    local use_wu=""
    local apk_file=""

    # Determine if we should use working user
    if AppInstaller --get-running-user "$keep_opt" --nopr; then
        use_wu="--use-working-user"
    fi

    # Install iUnlockerGL.apk
    apk_file="$MODPATH/iUnlockerGL.apk"
    if [[ ! -f "$apk_file" ]]; then 
        status_print w "iUnlockerGL.apk not found in module directory"
    else
        if AppInstaller --install "$apk_file" "$keep_opt" "$use_wu"; then
            # Grant permissions only if installation succeeded
            for perm in "${PERMISSIONS[@]}"; do
                AppInstaller --grant-app-perm "$NICENAME" "$perm" "$keep_opt" "$use_wu"
            done
        fi
    fi

    # Install iUnlockerUpdater.apk  
    apk_file="$MODPATH/iUu.apk"
    if [[ ! -f "$apk_file" ]]; then
        status_print w "iUnlockerUpdater.apk not found in module directory"
    else
        AppInstaller --install "$apk_file" "$keep_opt" "$use_wu"
    fi
}

# checkMagiskVer

# Extracting files.
NEEDED=(
	"module.prop"
	"sepolicy.rule"
	"system.prop"
	"iunlocker/*"
	"updater.sh"
	"uninstall.sh"
	"plugin_flasher.sh"
	"post-fs-data.sh"
	"properties.h"
	"iUnlockerGL.apk"
	"iUu.apk"
	"$MODID.dat" # v1.1.5-r2 this config will be extracted only if it's not exists in Communication dir | --ovrw, ++upenv
	"LICENSE"
	"AmethystRunner.sh"
	"plupdate_checker.sh"
	"nsgen.sh"
	"service.sh"
	"utilities.sh"
)

PERMISSIONS=(
	"android.permission.SYSTEM_ALERT_WINDOW"
	"android.permission.WRITE_EXTERNAL_STORAGE"
)

NICENAME="com.taylo.iunlockergl"
ADDIR="/data/adb"
SDK_ROOTDIR="$ADDIR/iunlocker"
ANDROID_TEMP_DIR="/data/local/tmp"
TOOLS="$SDK_ROOTDIR/tools"
COMM_DIR="$SDK_ROOTDIR/share/Comm"

for ((f = 0; f < ${#NEEDED[@]}; f++)); do
    NED="${NEEDED[f]}"
    if [[ "$NED" == "iunlocker/*" ]]; then
        extract "$NED" "$ADDIR"
    elif [[ "$NED" == "$MODID.dat" ]]; then
        if [[ ! -f "$COMM_DIR/$MODID.dat" ]]; then
            extract "$NED" "$COMM_DIR"
        else
            $SDK_ROOTDIR/bin/upenv | redi "upenv"
        fi
    elif [[ "$NED" == *".sh" ]] && [[ "$NED" != "post-fs-data.sh" ]]; then
        extract "$NED" "$SDK_ROOTDIR/share/Scripts"
    elif [[ "$NED" == "properties.h" ]]; then
        extract "$NED" "$SDK_ROOTDIR/include"
    elif ! extract "$NED" "$MODPATH"; then
    	abort "Couldn't extract '$NED' ! it's required"
    fi
done

# Checking for SDK.
[ ! -d $SDK_ROOTDIR ] && {
	status_print - "SDK is not found ! it's required for :\n\t\t- Lifecycle Engine, Ghost containers, Zygisk shared library."
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
	cp -af "$TMPDIR/bin/bash" $SDK_ROOTDIR/bin/
}

# Required for Ghost::FORCE_LDPRELOADER tool...
{
	if chown root:root "$SDK_ROOTDIR/lib/libgl_loader.so" && chown -R root:root $COMM_DIR; then
		status_print + "Successfully changed owner."
	else
		status_print - "Couldn't change owner"
	fi
}

# Running prototype test unit...
function configen() {
	$SDK_ROOTDIR/bin/configen "$@"
	return $?
}
function prototype() {
    local args=()
    $PROTOTYPE_LOGALL && args+=("--logall")
    "$SDK_ROOTDIR/bin/prototype" "${args[@]}"
    return $?
}

if ! mv "$SDK_ROOTDIR/lib/libtest_lib.so" "$MODPATH"; then
    status_print - "Failed to move libtest_lib.so! it's needed by prototype"
fi

status_print + "Running prototype test unit..."
if ! prototype; then
	abort "Prototype indicate failure, means your device is not supported !"
else
	# It's Important to tell our service of the prototype success.
	run_thro='GHOST_NAMESPACE_PRELOAD'
	sclass_handler="Ghost::API::GB_INSTANCE"
	sclass_uuid_magic_addr='0x8F2EA0'
	sclass_uuid_identifier="UUID_MAGIC" 
	sclass_receiver_expt_value="${run_thro}::OK_Connectivity" # OK_Connectivity -> essential 
	configen -o "$COMM_DIR/prototype.dat" \
		-s "$sclass_handler" -k "$sclass_uuid_identifier" -v "$sclass_uuid_magic_addr:$sclass_receiver_expt_value" 2>&1 | redi
fi

ensure_nold
install_iunlocker_app
ensure_updater

# Important steps ] let's check if $MODID.dat and properties.h
if [ ! -f "$COMM_DIR/$MODID.dat" ]; then
	status_print - "Couldn't find $MODID.dat !!! without \`$MODID.dat\` file your system will not boot correctly or it will not boot at all"
fi

if [ ! -f "$SDK_ROOTDIR/include/properties.h" ]; then
	status_print - "Couldn't find properties.h !!! without \`properties.h\` file the module will not function properly"
fi

# Reached to this point means everything went success
status_print + "Successfully installed" # :)
