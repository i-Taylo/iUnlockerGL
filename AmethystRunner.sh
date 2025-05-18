#!/data/adb/iunlocker-sdk/bin/bash

export MEMORY_SIGNAL_MAGIC='0x0AFE'
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

function invalid_characters() {
	if [[ "$1" =~ [[:punct:]] ]]; then
		raise_error "Error: String contains invalid characters!"
		return 1
	fi
	return 0
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

function zip() {
	$SDKDIR/bin/zip "$@"
	return $?
}

function unzip() {
	$SDKDIR/bin/unzip "$@"
	return $?
}

function sapphire_app() {
	$SDKDIR/bin/sapphire_app "$@"
	return $?
}

function Flasher() {
	local operation="$1"
	local zipfile="$2"
	local valid_operations=("install" "flash" "uninstall" "remove")
	local operation_valid=false
	local return_code=0

	for op in "${valid_operations[@]}"; do
		if [[ "$operation" == "$op" ]]; then
			operation_valid=true
			break
		fi
	done

	if [[ "$operation_valid" == "false" ]]; then
		raise_error "Invalid operation: $operation. Valid operations are: ${valid_operations[*]}"
		return 1
	fi

	if [[ ! -f "$zipfile" ]]; then
		raise_error "Module zip file not found: $zipfile"
		return 1
	fi

	local ksud="/data/adb/ksu/ksud"
	local apd="/data/adb/ap/apd"
	local magisk_exec=$(which magisk 2>/dev/null)

	local can_use_ksu=false
	local can_use_ap=false
	local can_use_magisk=false

	if [[ -f "$ksud" && -x "$ksud" ]]; then
		can_use_ksu=true
		spr "KernelSU detected"
	fi

	if [[ -f "$apd" && -x "$apd" ]]; then
		can_use_ap=true
		spr "APatch detected"
	fi

	if [[ -n "$magisk_exec" ]]; then
		can_use_magisk=true
		spr "Magisk detected"
	fi

	local su_count=0
	$can_use_ksu && ((su_count++))
	$can_use_ap && ((su_count++))
	$can_use_magisk && ((su_count++))

	if [[ $su_count -eq 0 ]]; then
		raise_error "No root solution detected. Please ensure Magisk, KernelSU, or APatch is installed."
		return 1
	elif [[ $su_count -gt 1 ]]; then
		spr "Warning: Multiple root solutions detected which may conflict with each other."
	fi

	case "$operation" in
	"install" | "flash")
		if [[ "$can_use_ksu" == "true" ]]; then
			spr "Using KernelSU to install module..."
			$ksud module install "$zipfile"
			return_code=$?
		elif [[ "$can_use_ap" == "true" ]]; then
			spr "Using APatch to install module..."
			$apd module install "$zipfile"
			return_code=$?
		elif [[ "$can_use_magisk" == "true" ]]; then
			spr "Using Magisk to install module..."
			$magisk_exec --install-module "$zipfile"
			return_code=$?
		fi
		;;

	"uninstall" | "remove")
		local module_id=$(basename "$zipfile" .zip)

		if [[ "$module_id" == "$zipfile" ]]; then
			if command -v unzip &>/dev/null; then
				module_id=$(unzip -p "$zipfile" module.prop 2>/dev/null | grep "^id=" | cut -d= -f2)
			fi
		fi

		if [[ -z "$module_id" ]]; then
			raise_error "Could not determine module ID for uninstallation"
			return 1
		fi

		if $can_use_ksu; then
			spr "Using KernelSU to uninstall module..."
			$ksud module uninstall "$module_id"
			return_code=$?
		elif $can_use_ap; then
			spr "Using APatch to uninstall module..."
			$apd modules remove "$module_id"
			return_code=$?
		elif $can_use_magisk; then
			spr "Using Magisk to uninstall module..."
			if ! rm -rf "/data/adb/modules/$module_id"; then
				return_code=1
			fi
		fi
		;;
	esac

	if [[ $return_code -ne 0 ]]; then
		raise_error "Operation failed with exit code $return_code"
		return $return_code
	else
		spr "Operation completed successfully"
		return 0
	fi
}

ADDIR="/data/adb"
SDKDIR="$ADDIR/iunlocker-sdk"
TEMPDIR="$SDKDIR/tmp"
TEMP_STRUCT="$TEMPDIR/Amethyst"

if [[ ! -d "$SDKDIR" ]]; then
	raise_error "SDK directory not found"
	exit 1
fi

if [[ ! -d "$TEMP_STRUCT" ]]; then
    if ! mkdir -p "$TEMP_STRUCT"; then
        raise_error "Couldn't generate $TEMP_STRUCT"
        exit 1
    fi
fi

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
SAPPHIRE_VERSION_STRING="v1.0-r1"
if ! sapphire_app --new_gl_model "$TARGET_GLMODEL" --no-confirm --no-warning; then
    raise_error "Something went wrong!"
    exit 1
else
    # notify post fs script
    echo "$SAPPHIRE_VERSION_STRING" > "$SDKDIR/tmp/.sapphire_install"
fi