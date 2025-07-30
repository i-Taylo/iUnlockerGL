#!/data/adb/iunlocker/bin/bash

SDK_ROOTDIR="/data/adb/iunlocker"
TEMPDIR="$SDK_ROOTDIR/tmp"
ADDIR="/data/adb"

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


function create_tmpdir() {
	if mkdir -p $1; then
		spr "Successfully created: ${1##*/}"
	else
		raise_error "Couldn't create tmpdir"
	fi
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
	local magisk_exec=magisk

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

function wget() {
    $SDK_ROOTDIR/bin/wget "$@"
    return $?
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
		if wget $opts "$output" "$url"; then
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

function invalid_characters() {
	if [[ "$1" =~ [[:punct:]] ]]; then
		raise_error "Error: String contains invalid characters!"
		return 1
	fi
	return 0
}

function zip() {
	$SDKDIR/bin/zip "$@"
	return $?
}

function unzip() {
	$SDKDIR/bin/unzip "$@"
	return $?
}

function jq() {
    $SDK_ROOTDIR/bin/jq "$@"
    return $?
}

function sapphire_app() {
	$SDK_ROOTDIR/bin/sapphire_app "$@"
	return $?
}

function bash() {
	$SDK_ROOTDIR/bin/bash "$@"
	return $?
}