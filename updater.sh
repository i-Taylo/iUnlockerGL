#!/data/adb/modules/iUnlockerGL/iunlocker-sdk/bin/bash

##############################################
#   Updater script by Taylo @ github.com/i-taylo
##############################################

set -eu

export SKIP_SYSTEM_SERVER=0
export MEMORY_SIGNAL_MAGIC='0xEE3F'
export __LDX__INIT__="onLilithLoad(global($MEMORY_SIGNAL_MAGIC).set(0)):close(global(S).set(0)):load(global(T).set(0)).commit();"

trap cleanup EXIT

function raise_error() {
	local reason="$1"
	local EXIT_FAILURE=1
	# "Contain" the error message into the memory magic
	echo -e "[[$MEMORY_SIGNAL_MAGIC]](\"$reason\")"
	return $EXIT_FAILURE
}

function grep_prop() { # from util_functions.sh | magisk
	local REGEX="s/^$1=//p"
	shift
	local FILES=$@
	[ -z "$FILES" ] && FILES='/system/build.prop'
	cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

function grep_get_prop() { # from util_functions.sh | magisk
	local result=$(grep_prop $@)
	if [ -z "$result" ]; then
		# Fallback to getprop
		getprop "$1"
	else
		echo $result
	fi
}

function api_level_arch_detect() { # from util_functions.sh | magisk
	API=$(grep_get_prop ro.build.version.sdk)
	ABI=$(grep_get_prop ro.product.cpu.abi)
	if [ "$ABI" = "x86" ]; then
		ARCH=x86
		ABI32=x86
		IS64BIT=false
	elif [ "$ABI" = "arm64-v8a" ]; then
		ARCH=arm64
		ABI32=armeabi-v7a
		IS64BIT=true
	elif [ "$ABI" = "x86_64" ]; then
		ARCH=x64
		ABI32=x86
		IS64BIT=true
	else
		ARCH=arm
		ABI=armeabi-v7a
		ABI32=armeabi-v7a
		IS64BIT=false
	fi
}

function ensure_root() {
	if [ $(id -u) != 0 ]; then
		raise_error "device not rooted or root permissions were denied"
	fi
}

function check_arch() { # Not needed anymore
	arch="$(uname -m)"
	if [ "$arch" != "aarch64" ]; then
		raise_error "Unsupported architecture: $arch"
	fi
}

function spr() {
	local message="$1"
	local NO_IGNORE_ON_PRINT="001"
	echo -e "[[$MEMORY_SIGNAL_MAGIC$NO_IGNORE_ON_PRINT]](\"$message\")"
}

function create_tmpdir() {
	if mkdir -p $1; then
		spr "Successfully created: ${1##*/}"
	else
		raise_error "Couldn't create tmpdir"
	fi
}

function cleanup() {
	if rm -rf "$MODULETMPDIR" "$MODULETMPDIR/MODULES"; then
		spr "Successfully cleanup"
	fi
}

function download() {
	local url output opts MAX_ATTEMPTS ATTEMPT
	url="$2"
	output="$1"
	opts='--no-check-certificate -e robots=off -q -O'
	mkdir -p "$(dirname "$output")"

	MAX_ATTEMPTS=5
	ATTEMPT=1
	while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
		if /data/adb/modules/iUnlockerGL/iunlocker-sdk/bin/wget $opts "$output" "$url"; then
			spr "Successfully downloaded: $output"
			return 0
		else
			spr "Couldn't download $output from: $url, retrying..."
		fi
		ATTEMPT=$((ATTEMPT + 1))
		if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
			spr "Reached maximum retries."
			return 1 # will be handled later
		fi
	done
}

function cpy() {
	local target=$1
	local dest=$2
	if cp -af "$target" "$dest"; then
		spr "Successfully copied ${target##*/} -> $dest"
	else
		raise_error "Couldn't copy important file"
	fi
}

ebusybox() {
	$BUSYBOX "$@"
	return $?
}

BASE="/data/adb/modules/iUnlockerGL"
SDKDIR="$BASE/iunlocker-sdk"
ZYGISK_LIBRARY="$BASE/zygisk"
REPO_NAME="iUnlockerGL"
ME="i-Taylo"
URL="https://raw.githubusercontent.com/$ME/$REPO_NAME/refs/heads/main"
FILES_ARRAY_URL="https://raw.githubusercontent.com/$ME/$REPO_NAME/refs/heads/main/MODULES"
MODULETMPDIR="$BASE/moduletmp"
DEFAULT_PATH="/data/adb/magisk"
KSUDIR="/data/adb/ksu"
BUSYBOX="$DEFAULT_PATH/busybox"
KSU=false

api_level_arch_detect
ensure_root

if [ -d $KSUDIR ]; then
	KSU=true
	DEFAULT_PATH=$KSUDIR
	BUSYBOX="$DEFAULT_PATH/bin/busybox"
fi

if [ ! -d "$BASE" ]; then
	raise_error "MODULE DIRECTORY NOT EXISTS"
fi # End of check->$BASE

if [ ! -d "$SDKDIR" ]; then
	raise_error "iUnlocker SDK DIRECTORY NOT EXISTS"
fi # End of check->$SDKDIR

create_tmpdir "$MODULETMPDIR"
cd "$MODULETMPDIR" # enter tmpdir

# Let's delete "${FILES_ARRAY_URL##*/}" before downloading fresh file
if [ -f "${FILES_ARRAY_URL##*/}" ]; then
	if rm "${FILES_ARRAY_URL##*/}"; then
		spr "Deleted: "${FILES_ARRAY_URL##*/}""
	fi
fi # end of deletion
# Now let's download fresh one.
if ! download "${FILES_ARRAY_URL##*/}" "$FILES_ARRAY_URL"; then
	raise_error "error downloading important file"
fi # end of downloading

#
dos2unix "${FILES_ARRAY_URL##*/}"
MODULES_FILE="$(cat ${FILES_ARRAY_URL##*/})"
for file in ${MODULES_FILE[@]}; do
	if ! download "./$file" "$URL/$file"; then
		raise_error "error downloading important file"
	fi
done

# Reached to this point now let's move everything to maindir
mode=755
cd $BASE # go back

if cp -af "$MODULETMPDIR/"* "$BASE"; then
	if cp -af "$SDKDIR/tools/lib/$ARCH/"* "$SDKDIR/lib"; then
		spr "Successfully copied: $SDKDIR/tools/lib/$ARCH -> $SDKDIR/lib"
	else
		raise_error "Couldn't copy important libraries"
	fi
	if cp -af "$SDKDIR/tools/$ARCH/"* "$SDKDIR/bin"; then
		spr "Successfully copied: $SDKDIR/tools/$ARCH -> $SDKDIR/bin"
	else
		raise_error "Couldn't copy important binaries!!!"
	fi

	if rm -rf $SDKDIR/tools; then
		spr "Removed: $SDKDIR/tools"
	fi

	cd $BASE/bin # enter bin
	if ebusybox xz -d $ARCH.xz; then
		spr "Successfully extracted: $ARCH.xz"
	else
		raise_error "Couldn't extract important binary!!!"
	fi

	if mv $ARCH bash; then
		spr "Successfully renamed $ARCH -> bash"
	else
		raise_error "Couldn't rename $ARCH->bash !!! operation required"
	fi

	if mv bash $BASE/iunlocker-sdk/bin; then
		spr "Successfully moved bash -> $BASE/iunlocker-sdk/bin"
	else
		raise_error "Couldn't move bash to iunlocker sdk!!! it's required"
	fi

	cd .. # getting back

	if rm -rf $BASE/bin; then
		spr "Removed $BASE/bin"
	fi

	# Reached to this point
	spr "Successfully moved all files"
	if chmod -R $mode $BASE; then
		spr "Successfully changed permissions"
	else
		raise_error "Couldn't change permission!! libraries & binaries cannot run without proper permissions!!!"
	fi
else
	raise_error "Couldn't move important files"
fi

# Last step
APP_DATA="/data/data/com.TayloIUnlockerGL"
if [ -f "$APP_DATA/expired" ]; then
    if rm $APP_DATA/expired; then
        spr "Successfully removed: $APP_DATA/expired"
    fi
fi
