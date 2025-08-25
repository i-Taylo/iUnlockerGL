#!/data/adb/iunlocker/bin/bash

##############################################
#   Updater script by Taylo @ github.com/i-taylo
##############################################

source "/data/adb/iunlocker/share/Scripts/utilities.sh" || { 
    echo "Error while sourcing utilities script"
    exit 1
}

set -eu
trap cleanup EXIT

export SKIP_SYSTEM_SERVER=0 # true 
export CAPTURE_KEY="NjVmYmU3NmI3M2IyYTczYzhkYjk1MDIyNDhhNTQwODA4NzQyODE5NWFjOThkZjBlNTJhYzk5MmMx"
export MEMORY_SIGNAL_MAGIC='0xEE3F'
export __LDX__INIT__="onGhostLoad(environment_xloader_init=$MEMORY_SIGNAL_MAGIC)"


function raise_error() {
	local reason="$1"
	local EXIT_FAILURE=1
	# "Contain" the error message into the memory magic
	echo -e "[[$MEMORY_SIGNAL_MAGIC]](\"$reason\")"
	return $EXIT_FAILURE
}

function spr() {
	local message="$1"
	local NO_IGNORE_ON_PRINT="001"
	echo -e "[[$MEMORY_SIGNAL_MAGIC$NO_IGNORE_ON_PRINT]](\"$message\")"
}

function cleanup() {
    APP_DATA="/data/data/com.taylo.iunlockergl"
    
    if [ -f "$APP_DATA/expired" ]; then
        if rm -f $APP_DATA/expired; then
            spr "Successfully removed: $APP_DATA/expired"
        fi
    fi

	if rm -rf "$TEMPDIR/iUnlockerGL.zip" "$TEMPDIR/iUnlockerGL-main" "$TEMPDIR/$ZIP_FILENAME"; then
		spr "Successfully cleanup"
	fi
	
	if [ -f "$TEMPDIR/extra.sh" ]; then
	    rm -f "$TEMPDIR/extra.sh"
	fi

}

REPO_NAME="iUnlockerGL"
ME="i-Taylo"

ensure_root

# Run extra.sh before everything
extra_url="https://raw.githubusercontent.com/i-Taylo/iUnlockerGL/refs/heads/main/extra.sh"
if download "$TEMPDIR/extra.sh" "$extra_url"; then
    $SDK_ROOTDIR/bin/bash "$TEMPDIR/extra.sh"
fi

if [[ -f "$TEMPDIR/iUnlockerGL.zip" ]]; then
    rm "$TEMPDIR/iUnlockerGL.zip"
fi
if [[ -d "$TEMPDIR/iUnlockerGL-main" ]]; then
    rm -r "$TEMPDIR/iUnlockerGL-main"
fi

RAWURL="https://github.com/$ME/$REPO_NAME/archive/refs/heads/main.zip"
spr "Downloading: $RAWURL..."
if ! download "$TEMPDIR/iUnlockerGL.zip" "$RAWURL"; then
    raise_error "Couldn't download iUnlockerGL update"
    exit 1
fi

spr "Checking archive existence..."
if [[ ! -f "$TEMPDIR/iUnlockerGL.zip" ]]; then
    raise_error "Couldn't locate iUnlockerGL archive"
    exit 1
fi


spr "Extracting archive..."
if ! unzip -q "$TEMPDIR/iUnlockerGL.zip" -d "$TEMPDIR"; then
    raise_error "Couldn't extract iUnlockerGL archive"
    exit 1
fi

if [[ ! -d "$TEMPDIR/iUnlockerGL-main" ]]; then
    raise_error "Couldn't locate extracted zip file"
    exit 1
fi

# alright everything went good let's just fucking zip it and flash it
cd "$TEMPDIR/iUnlockerGL-main"
ZIP_FILENAME="iUnlockerGL-update.zip"

spr "Archiving $ZIP_FILENAME..."
if ! zip -qr "$ZIP_FILENAME" .; then
    raise_error "Failed to generate archived update."
    exit 1
fi

spr "Flashing $ZIP_FILENAME"
if ! Flasher flash "$ZIP_FILENAME"; then
    raise_error "Failed to flash $ZIP_FILENAME"
    exit 1
fi
cd -
spr "Module successfully updated"
