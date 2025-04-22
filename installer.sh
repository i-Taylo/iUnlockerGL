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
	"?") w="QUESTION" ;;
	"0") w="DEBUG" ;;
	"!" | "i") w="WARNING" ;;
	"-") w="ERROR" ;;
	"+") w="INFO" ;;
	"c") w="CLEANUP" ;;
	"~l") w="o" ;;
	*) w="INFO" ;;
	esac

	echo -e "[$w] $message"

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
	local filename="/data/user/0/$NICENAME/shared_prefs/${NICENAME}_preferences.xml"
	local keep_keys=("gl_vk_warning_skipped" "userName" "isAgred?" "hintWarn" "isDark" "showDataCollection")

	if [[ -f "$filename" ]]; then
		local temp_file="/data/user/0/$NICENAME/cache/tempfile.txt"

		if [[ ! -f "$temp_file" ]]; then
			touch "$temp_file" || temp_file=$(mktemp) || {
				status_print - "Failed to create temp file"
				exit 1
			}
		fi

		echo '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>' >"$temp_file"
		echo '<map>' >>"$temp_file"

		match_found=false
		for key in "${keep_keys[@]}"; do
			if grep -q "<\(string\|boolean\) name=\"$key\"" "$filename"; then
				grep "<\(string\|boolean\) name=\"$key\"" "$filename" >>"$temp_file"
				match_found=true
			fi
		done

		echo '</map>' >>"$temp_file"

		if [[ "$match_found" == true ]]; then
			mv "$temp_file" "$filename"
			chmod 644 "$filename"
		else
			rm "$temp_file"
		fi
	else
		status_print + "Preference file not found, no cleanup needed"
	fi
    
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
	
	# 1. Module id changed in v1.1.4-r1
    # 2. Separate std&sapphire plugins deprecated in v1.1.4-r1
    depr="iUnlockerGL-iStdUnlocker-Plugin"
    
    OID="iUnlockerGL"
    ODI="/data/adb/modules/$OID"

    if [[ "$KSU" == "true" ]]; then
        EXC="ksud"
        if [[ -x "$DEFAULT_PATH/bin/$EXC" ]]; then
            getAllModules="$($DEFAULT_PATH/bin/$EXC module list)"
            for mod in $getAllModules; do
                [[ "$mod" == "$OID" ]] && $DEFAULT_PATH/bin/$EXC module uninstall "$OID"
                [[ "$mod" == "$depr" ]] && $DEFAULT_PATH/bin/$EXC module uninstall "$depr"
            done
        else
            status_print ! "Binary $EXC not found!"
        fi

    elif [[ "$AP" == "true" ]]; then
        EXC="apd"
        if [[ -x "$DEFAULT_PATH/bin/$EXC" ]]; then
            getAllModules="$($DEFAULT_PATH/bin/$EXC module list)"
            for mod in $getAllModules; do
                [[ "$mod" == "$OID" ]] && $DEFAULT_PATH/bin/$EXC module uninstall "$OID"
                [[ "$mod" == "$depr" ]] && $DEFAULT_PATH/bin/$EXC module uninstall "$depr"
            done
        else
            status_print ! "Binary $EXC not found!"
        fi
    
    else 
        if [[ -d "$ODI" ]]; then
            if ! touch "$ODI/remove"; then
                status_print - "Couldn't remove old iUnlocker version! please uninstall it manually!!"
            fi
        fi
        if [[ -d "/data/adb/modules/$depr" ]]; then
            if ! touch "/data/adb/modules/$depr/remove"; then
                status_print - "Couldn't remove old standard iUnlocker plugin! please uninstall it manually to avoid confliction!!"
            fi
        fi
    fi

    if [[ -f "$MODPATH/iUnlockerGL.apk" ]]; then
        if ! rm -rf "$MODPATH/iUnlockerGL.apk"; then
            status_print ! "Couldn't clean up $MODPATH/iUnlockerGL.apk"
        fi
    fi
    

}

function AppInstaller() {
    $SDK_ROOTDIR/bin/AppInstaller "$@"
    return $?
}

function ensure_no_oldGl() {
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
    local val="$(cat "$UPDATER_FILE")"
    local UPDATER_FILE="$SDK_ROOTDIR/updater_version"
    
    if [[ ! -f "$UPDATER_FILE" ]]; then
        echo -ne "$updater_version" > $UPDATER_FILE
    else
        if [[ ! $val -eq $updater_version ]]; then
            echo -ne "$updater_version" > $UPDATER_FILE
        fi
    fi
}

function install_iunlocker_app() {
    # Using AppInstaller api
    local keep_opt="--keep-apkinstaller-userfile"
    local use_wu=""
    if AppInstaller --get-running-user $keep_opt --nopr; then
        use_wu="--use-working-user"
    fi
    if AppInstaller --install "$MODPATH/iUnlockerGL.apk" $keep_opt $use_wu; then
    	for ((perm = 0; perm < ${#PERMISSIONS[@]}; perm++)); do
    		AppInstaller --grant-app-perm "$NICENAME" "${PERMISSIONS[perm]}" $keep_opt $use_wu
    	done
    fi
}

checkMagiskVer

# Extracting files.
NEEDED=(
	"module.prop"
	"system.prop"
	"iunlocker-sdk/*"
	"updater.sh"
	"uninstall.sh"
	"plugin_flasher.sh"
	"service.sh"
	"post-fs-data.sh"
	"properties.h"
	"iUnlockerGL.apk"
	"$MODID.dat"
	"LICENSE"
	"AmethystRunner.sh"
)

PERMISSIONS=(
	"android.permission.SYSTEM_ALERT_WINDOW"
	"android.permission.WRITE_EXTERNAL_STORAGE"
)

NICENAME="com.taylo.iunlockergl"
ADDIR="/data/adb"
SDK_ROOTDIR="$ADDIR/iunlocker-sdk"
ANDROID_TEMP_DIR="/data/local/tmp"
TOOLS="$SDK_ROOTDIR/tools"


for ((f = 0; f < ${#NEEDED[@]}; f++)); do
    NED="${NEEDED[f]}"
    if [[ "$NED" == "$MODID.dat" ]]; then
        extract "$NED" "$ADDIR"
    elif [[ "$NED" == "iunlocker-sdk/*" ]]; then
        extract "$NED" "$ADDIR"
    elif [[ "$NED" == "AmethystRunner.sh" ]]; then
        extract "$NED" "$SDK_ROOTDIR/share/Scripts"
    elif [[ "$NED" == "updater.sh" ]]; then
        extract "$NED" "$SDK_ROOTDIR/share/Scripts"
    elif [[ "$NED" == "plugin_flasher.sh" ]]; then
        extract "$NED" "$SDK_ROOTDIR/share/Scripts"
    elif [[ "$NED" == "properties.h" ]]; then
        extract "$NED" "$SDK_ROOTDIR/include"
    elif ! extract "$NED" "$MODPATH"; then
    	abort "Couldn't extract '$NED' ! it's required"
    fi
done

# Checking for SDK.
[ ! -d $SDK_ROOTDIR ] && {
	status_print - "SDK is not found ! it's required for :\n\t\t- Lifecycle Engine, Zygisk shared library."
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
	if chown root:root "$SDK_ROOTDIR/lib/libgl_loader.so"; then
		status_print + "Successfully changed owner."
	else
		status_print - "Couldn't change owner"
	fi
}

status_print + "Setting up Ghost Container"
# LILITH_TABLEFILE="$MODPATH/Lilith.rx" // replaced with ghost container

JsonWriter "$MODPATH/ghost.json" \
    "ghostJson" "/data/user/0/$NICENAME/files/ghost_container.json" \
    "ghostEt" "ERR_Connectivity|ERR_Tamper|ERR_nsfailed" \
    "environment_xloader_init" "null" \
    "isRandomTempfs" "true" \
    "restricted_dirs" "DYN${MODID}ENDDYN" \
    "onRun" 0x0 \
    "onStop" 0x1 \
    "onStart" 0x2 \
    "onMemoryAddressReceived" 0x3 \
    "destructionAfter" 500 #ms

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
	run_thro='GHOST_NAMESPACE_PRELOAD'
	sclass_handler="Ghost::API::GB_INSTANCE"
	sclass_uuid_magic_addr='0x8F2EA0'
	sclass_uuid_identifier="UUID_MAGIC" 
	sclass_receiver_expt_value="${run_thro}::OK_Connectivity"
	gfwriter -o "$MODPATH/prototype.dat" \
		-s "$sclass_handler" -k "$sclass_uuid_identifier" -v "$sclass_uuid_magic_addr:$sclass_receiver_expt_value" 2>&1 | redi
fi

ensure_no_oldGl
install_iunlocker_app
ensure_updater

# Important steps ] let's check if $MODID.dat and properties.h
if [ ! -f "$ADDIR/$MODID.dat" ]; then
	status_print - "Couldn't find $MODID.dat !!! without \`$MODID.dat\` file your system will not boot correctly or it will not boot at all"
fi

if [ ! -f "$SDK_ROOTDIR/include/properties.h" ]; then
	status_print - "Couldn't find properties.h !!! without \`$MODID.dat\` file your system will not boot correctly or it will not boot at all"
fi

# Reached to this point means everything went success
status_print + "Successfully installed" # :)
