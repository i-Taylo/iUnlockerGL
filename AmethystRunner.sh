#!/data/adb/iunlocker/bin/bash

source "/data/adb/iunlocker/share/Scripts/utilities.sh" || { 
    echo "Error while sourcing utilities script"
    exit 1
}

export MEMORY_SIGNAL_MAGIC='0x0AFE'
export SAPPHIRE_VERSION="v1.0-mainline"
# trap cleanup EXIT

function spr() {
	local message="$1"
	local NO_IGNORE_ON_PRINT="003"
	echo -e "[[$MEMORY_SIGNAL_MAGIC$NO_IGNORE_ON_PRINT]](\"$message\")"
}

function raise_error() {
	local reason="$1"
	local EXIT_FAILURE=1
	# "Contain" the error message into the memory magic
	echo -e "[[$MEMORY_SIGNAL_MAGIC]](\"$reason\")"
	return $EXIT_FAILURE
}

function cleanup() {
    if [[ -d "$TEMP_STRUCT" ]]; then
        if rm -rf "$TEMP_STRUCT"; then
            spr "Successfully cleaned up $TEMP_STRUCT"
        fi
    else
        spr "Nothing to clean up"
    fi
}

function check_for_update() {
    spr "Checking for updates..."
    # Test plupdate_checker.sh first
    if ! bash $SDK_ROOTDIR/share/Scripts/plupdate_checker.sh -plugin_name=iUnlockerSapphire -getVersion > /dev/null 2>&1; then
        raise_error "Failed to fetch sapphire version"
    else
        fetched_version="$(bash $SDK_ROOTDIR/share/Scripts/plupdate_checker.sh -plugin_name=iUnlockerSapphire -getVersion)"
        exec_url="$(bash $SDK_ROOTDIR/share/Scripts/plupdate_checker.sh -plugin_name=iUnlockerSapphire -getExecUrl)"
        exec_file="$SDK_ROOTDIR/bin/sapphire_app"
        exec_ver="$(sapphire_app -version)"
        formatted_url=$(echo $exec_url | sed "s/\$ARCH/$ARCH/g")
        
        spr "Fetched version: $fetched_version"
        spr "Local version: $SAPPHIRE_VERSION"
        spr "formatted url: $formatted_url"
        
        if [[ "$fetched_version" != "$exec_ver" ]]; then
            # will rename it instead of completely deleting it
            spr "New update available: $fetched_version"
            mv "$exec_file" "$SDK_ROOTDIR/bin/sapphire_app.bak"
            if ! download "$exec_file" "$formatted_url"; then
                raise_error "Failed to download sapphire_app plugin"
                # we don't need to exit here let the script uses the old version
                mv "$SDK_ROOTDIR/bin/sapphire_app.bak" "$exec_file"
            else
                chmod 755 $exec_file
                exec_ver="$(sapphire_app -version)"
                # let's test if the plugin works
                if ! sapphire_app -test > /dev/null 2>&1; then
                    raise_error "Sapphire test operation failed.\nexit code: $?"
                    exit 1
                fi
                if [[ "$exec_ver" == "$fetched_version" ]]; then
                    spr "New Sapphire version: $exec_ver"
                else
                    spr "Version doesn't match $fetched_version!"
                    # let the script continue
                fi
            fi
        fi
        
    fi
}

ADDIR="/data/adb"
SDK_ROOTDIR="$ADDIR/iunlocker"
TEMPDIR="$SDK_ROOTDIR/tmp"
TEMP_STRUCT="$TEMPDIR/Amethyst"

if [[ ! -d "$SDK_ROOTDIR" ]]; then
	raise_error "SDK directory not found"
	exit 1
fi

if [[ ! -d "$TEMP_STRUCT" ]]; then
    if ! mkdir -p "$TEMP_STRUCT"; then
        raise_error "Couldn't generate $TEMP_STRUCT"
        exit 1
    fi
fi

api_level_arch_detect
check_for_update

# Main process
spr "Generation of Sapphire module structure..."
cd "$TEMP_STRUCT"

spr "Setting up Sapphire PatcherTool..."

TARGET_GLMODEL="$1"
[ -z "$TARGET_GLMODEL" ] && {
    raise_error "No GPU Model & Vulkan model were provided"
    exit 1
}

# sapphire_app already has a length limiter so no need to check for length...
# so let's just fucking continue
# Ahh, shit, my sexy burger just dropped on my keyboard and made quite a mess.
# Awwright... lesh jush call the... saph-firrr_app...
SAPPHIRE_VERSION_STRING="$(sapphire_app -version)"
if ! sapphire_app --new_gl_model "$TARGET_GLMODEL" --no-confirm --no-warning; then
    raise_error "Something went wrong!"
    exit 1
else
    # notify post fs script
    echo "$SAPPHIRE_VERSION_STRING" > "$SDK_ROOTDIR/tmp/.sapphire_install"
fi