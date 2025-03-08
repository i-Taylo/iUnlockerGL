#!/data/adb/modules/iUnlockerGL/iunlocker-sdk/bin/bash

export MEMORY_SIGNAL_MAGIC='0xA0E4'

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

function stdUnlockerHandler() {
	$SDKDIR/bin/StdUnlockerHandler "$@"
	return $?
}

function modify_prop() {
	local prop_file="$1"
	local key="$2"
	local new_value="$3"

	if [[ ! -f "$prop_file" ]]; then
		raise_error "Error: File does not exist."
		return 1
	fi
	if grep -q "^$key=" "$prop_file"; then
		sed -i "s/^$key=.*/$key=$new_value/" "$prop_file"
	else
		echo "$key=$new_value" >>"$prop_file"
	fi

	spr "Successfully modified $key in $prop_file"
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
		if $can_use_ksu; then
			spr "Using KernelSU to install module..."
			$ksud module install "$zipfile"
			return_code=$?
		elif $can_use_ap; then
			spr "Using APatch to install module..."
			$apd module install "$zipfile"
			return_code=$?
		elif $can_use_magisk; then
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

MODDIR=${0%/*}
readonly MODID="iUnlockerGL"
SDKDIR="$MODDIR/iunlocker-sdk"
ZIPTMPDIR="$MODDIR/.tempdir"
PLUGINS=("stdunlocker")

if [[ "$(basename $MODDIR)" != "$MODID" ]]; then
	raise_error "Unknown module id"
	exit 1
fi

# if [[ ! -d "$ZIPTMPDIR" ]]; then
# if ! mkdir -p "$ZIPTMPDIR"; then
# ZIPTMPDIR="/data/local/tmp/.itempdir"
# if ! mkdir -p "$ZIPTMPDIR"; then
# raise_error "Couldn't create tmpdir"
# exit 1
# fi
# fi
# fi

TARGET_ZIPFILE="$1"
TARGET_MODEL="$2"
TARGET_MANUF="$3"

if [[ -z "$TARGET_MODEL" ]]; then
	raise_error "No model string provided"
	exit 1
fi
if [[ -z "$TARGET_MANUF" ]]; then
	raise_error "No manufacturer string provided"
	exit 1
fi

if [[ -z "$TARGET_ZIPFILE" ]]; then
	raise_error "No zipfile provided"
	exit 1
elif [[ ! -f "$TARGET_ZIPFILE" ]]; then
	raise_error "[ $TARGET_ZIPFILE ] doesn't exist!"
	exit 1
fi

# if ! invalid_characters "$TARGET_MODEL"; then
# exit 1
# fi

# if ! invalid_characters "$TARGET_MANUF"; then
# exit 1
# fi

isiUnlocker=false
for ((i = 0; i < ${#PLUGINS[@]}; i++)); do
	if [[ "${PLUGINS[i]}" == "stdunlocker" ]]; then
		isiUnlocker=true
	fi
done

if $isiUnlocker; then
	SYSTEM_PROPERTIES=(
		"ro.product.model"
		"ro.product.system.model"
		"ro.product.system_ext.model"
		"ro.product.vendor.model"
		"ro.product.odm.model"
		"ro.product.manufacturer"
		"ro.product.system.manufacturer"
		"ro.product.system_ext.manufacturer"
		"ro.product.vendor.manufacturer"
		"ro.product.odm.manufacturer")

	args=("$TARGET_ZIPFILE")
	for key in "${SYSTEM_PROPERTIES[@]}"; do
		if [[ "$key" == *"model" ]]; then
			args+=("--key" "$key" "--value" "$TARGET_MODEL")
		elif [[ "$key" == *"manufacturer" ]]; then
			args+=("--key" "$key" "--value" "$TARGET_MANUF")
		fi
	done

	if ! stdUnlockerHandler "${args[@]}"; then
		raise_error "Failed to update properties"
		exit 1
	else
		spr "Successfully updated all properties"
	fi

	# Commented sections remain unchanged
	# if ! zipexec -r "someplugin01.zip" .; then
	# raise_error "Couldn't compress plugins!"
	# fi

	if ! Flasher flash "$TARGET_ZIPFILE"; then
		raise_error "Couldn't flash $TARGET_ZIPFILE"
	fi
fi
